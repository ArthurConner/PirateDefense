//
//  TowerNode.swift
//  CatLike
//
//  Created by Arthur  on 9/25/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import Foundation
import GameKit


class TowerMissle:SKShapeNode {
    
    convenience init(tower:TowerNode,dest:CGPoint,flightDuration:Double) {
        
        self.init(circleOfRadius:8)
        self.fillColor = .red
        self.position = tower.position
        
        self.zPosition = 3
        guard let p = tower.parent else {return}
        p.addChild(self)
        let body = SKPhysicsBody(circleOfRadius: 4)
        
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.Missle
        body.restitution = 0.5
        self.physicsBody = body
        
        let act = SKAction.move(to: dest, duration: flightDuration)
        self.run(SKAction.sequence([act,
                                    SKAction.removeFromParent()]))
        
    }
    
}

struct TowerProxy: Codable {
    let postition:CGPoint
    let level:Int
    let towerID:String
}

class TowerNode: SKShapeNode , Fireable {
    
    var gun = PirateGun(interval:1, flightDuration:0.2, radius:3)
    var levelTimer = PirateClock(6)
 
     let towerID = "\(Date.timeIntervalSinceReferenceDate)_\(GKRandomSource.sharedRandom().nextUniform())"
    
    var level = 0
    let maxHealth = 6
    var hitsRemain = 6

    convenience init(range:CGFloat) {
        
        self.init(circleOfRadius:18)
        self.fillColor = .red
        self.strokeColor = .black
        self.lineWidth = 3
        self.gun.landscapes = [.water,.path]
        
        let body = SKPhysicsBody(circleOfRadius: 18)
        
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.Tower
        body.isDynamic = false
        
        body.restitution = 0.5

        self.physicsBody = body
        
    }
    
    func proxy()->TowerProxy {
        return TowerProxy(postition: self.position, level: self.level, towerID: self.towerID)
    }
    
    func checkAge(scene:GameScene)->Bool{
        if levelTimer.needsUpdate(){
            
            if level == 3 {
                if  let towerTile = scene.tileOf(node: self) {
                    scene.mapTiles.changeTile(at: towerTile, to: .inland)
                }
                self.die(scene: scene, isKill: false)
                return false
            } else {
                adjust(level: level)
                
            }
        }
        return true
    }
    
    func adjust(level nextL:Int){
        
        let prior = level
    
        switch nextL {
        case 0:
            gun.clock.adjust(interval: 1)
            level = 1
        case 1:
   
             gun.clock.adjust(interval: 1.5)
            level = 2
            
        case 2:
            gun.clock.adjust(interval: 2)
            level = 3
        default:
            level = 0
            gun.clock.adjust(interval: 1)
        }
        
        var shrinkTime = levelTimer.length()

        if prior < 0 {
            let interval = min(0.2,shrinkTime)
            shrinkTime = shrinkTime - interval
            
            self.run(SKAction.sequence([SKAction.scaleX(to: 1, y: 1, duration: interval),SKAction.scale(by: 0.8, duration: shrinkTime)]))
            
        } else {
            let shrink = SKAction.scale(by: 0.8, duration: shrinkTime)
            self.run(shrink)
        }
        
        levelTimer.update()
        self.gun.clock.tickNext()
    }
    

    
    func die(scene:GameScene, isKill:Bool){
        removeAllActions()
        physicsBody = nil
        self.gun.clock.enabled = false
        self.levelTimer.enabled = false
        self.strokeColor = .clear

        if isKill {
            
            let boom = SKShapeNode.init(circleOfRadius: 20)
            
            boom.path = self.path
            boom.position = self.position
            boom.fillColor = self.fillColor
            boom.strokeColor = .clear
            scene.addChild(boom)
            
            boom.run(SKAction.scale(by: CGFloat(self.gun.radius) - 0.5, duration: 2))
            boom.run(SKAction.sequence([SKAction.fadeOut(withDuration: 4),
                                   SKAction.removeFromParent()]))
            
            scene.remove(tower: self)
        } else {
            scene.remove(tower: self)
            
        }
        
    }
    
    func targetTiles(scene:GameScene)->Set<MapPoint>{
        guard gun.clock.needsUpdate() else { return []}
        
        guard  let towerTile = scene.tileOf(node: self) else {
            return []
        }
        
      
        return scene.mapTiles.tiles(near:towerTile,radius:self.gun.radius,kinds:self.gun.landscapes)
        
    }
    
    func hit(scene:GameScene){
        
        hitsRemain -= 1
        
        var otherTowers:[TowerNode] = []
        
        defer {
            
            for tower in otherTowers {
                if tower.hitsRemain > 0 {
                    tower.hitsRemain = 1
                    tower.hit(scene: scene)
                }
            }
        }
        
        if hitsRemain < 1 {
            guard let towerTile  = scene.tileOf(node: self) else   { return }
            
            let towerScapes:Set<Landscape> = [.sand,.water,.path]
            
            let checkset = scene.mapTiles.tiles(near:towerTile,radius:self.gun.radius,kinds:towerScapes)
            
            var killSet:Set<MapPoint> = [towerTile]
            
            for checkTile in checkset {
                killSet.insert(checkTile)
            }
            
            for trip in scene.mapTiles.voyages{
                killSet.remove(trip.start)
                killSet.remove(trip.finish)
            }
            
            for tile in killSet {
                if let t = scene.tower(at:tile){
                   if t == self {
                        t.die(scene: scene, isKill: true)
                   } else {
                        otherTowers.append(t)
                    }
                }
                scene.mapTiles.changeTile(at: tile, to: .water)
            }
            
            let landscapeToDrop:Set<Landscape> = [.inland]
            
            let il = scene.mapTiles.tiles(near:towerTile,radius:self.gun.radius,kinds:landscapeToDrop)
            for x in il {
              let _ =  scene.possibleToSand(at: x)
            }
            
            scene.redirectAllShips()
            
        } else {
            
            let ratio = CGFloat(hitsRemain)/CGFloat(maxHealth)
            self.fillColor = ColorUtils.shared.blend(.white,.red,ratio:ratio)
        
        }
        
    }
    
    func fire(at:MapPoint,scene:GameScene){
        guard gun.clock.needsUpdate() else { return }
        
        if let dest =  scene.mapTiles.convert(mappoint: at){
            let _ = TowerMissle(tower: self, dest: dest, flightDuration: gun.flightDuration)
            gun.clock.update()
            
            return
        }
    }
    
    
}

class SandTower: TowerNode, Navigatable {
    
    var waterSpeed: Double = 1
    
    var route = Voyage.offGrid()
    var prior:MapPoint?
    
    func allowedTiles() -> Set<Landscape> {
        return routeSet
    }
    
    convenience init(timeOverTile:Double, route nextR:Voyage) {
        
        self.init(ellipseOf: CGSize(width: 30, height: 60))
        self.fillColor = .purple
        self.strokeColor = .clear
        self.lineWidth = 3
     
        self.waterSpeed = timeOverTile 
        self.route = nextR
        self.hitsRemain = 1
        self.zPosition = 3
        self.gun.clock.adjust(interval: timeOverTile)
    
        let body = SKPhysicsBody(circleOfRadius: 30)
        
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.Tower
        body.isDynamic = false
        body.contactTestBitMask = PhysicsCategory.Ship
        body.restitution = 0.5
        
        self.physicsBody = body
    }
    
    func spawnWake() {

    }
    
    override func checkAge(scene:GameScene)->Bool{

        guard let pos = scene.tileOf(node: self) else { return true}
        
        if pos == route.finish {
            scene.remove(tower: self)
            return false
        }
        
        guard gun.clock.needsUpdate() else {
            
            if prior == nil {
                self.prior = pos
            }
            return true
            
        }
        
        guard let p = self.prior,
            p != pos
            else { return true}
        
        let oldpath = pos.path(to: p, map: scene.mapTiles, using: allowedTiles())
        
        guard oldpath.count > 1 else { return true}
        
        let nextTile = oldpath[1]
        
        guard scene.navigatableBoats(at: nextTile).isEmpty else { return true}
        
        guard waterSet.contains(scene.mapTiles.kind(point: nextTile)) else {
            gun.clock.update()
            return true
        }
        
        if (scene.possibleToSand(at:nextTile)){
            gun.clock.update()
            self.prior = nil
            scene.redirectAllShips()
            return true

        }
        
       return false
    }
    
    override func fire(at:MapPoint,scene:GameScene){
        return
    }
 
    
}


class DefenderTower: TowerNode, Navigatable {
    var waterSpeed: Double = 1
    var route = Voyage.offGrid()
    
    var sandShipsRemaining = 5
    var allowsWin = true

    func allowedTiles() -> Set<Landscape> {
        return routeSet
    }
   
   
    var baseColor = OurColor.purple

    
    convenience init(timeOverTile:Double, route nextR:Voyage) {
  
        self.init(ellipseOf: CGSize(width: 25, height: 58))
        self.fillColor = .black
        self.strokeColor = .clear
        self.lineWidth = 3
        
        self.waterSpeed = timeOverTile * 2
        self.route = nextR
        self.hitsRemain = 3
        self.gun.landscapes = [.water,.path]

        let body = SKPhysicsBody(circleOfRadius: 10)
        
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.Tower
        body.contactTestBitMask = PhysicsCategory.Ship
        body.isDynamic = false
        
        body.restitution = 0.5
        self.zPosition = 3
        self.physicsBody = body
        
    }
    
    func spawnWake() {
       
         guard let board = self.parent else {return}
         
         let wake = SKShapeNode.init(circleOfRadius: 2)
         wake.fillColor = .white
         wake.strokeColor = .clear
         wake.position = self.position
         
         wake.run(SKAction.sequence([
         SKAction.scale(to: 8, duration: 5)]))
         
         wake.run(SKAction.sequence([SKAction.fadeOut(withDuration: 7),
         SKAction.removeFromParent()]))
         
         wake.zPosition = 2
         
         board.insertChild(wake, at: board.children.count - 1)
 
    }
    
    override func checkAge(scene:GameScene)->Bool{

        guard let pos = scene.tileOf(node: self) else { return true}
        
        if pos == route.finish {
            scene.remove(tower: self)
            if allowsWin {
                scene.gameState = .win
            }
            return false
        }
        
        return true
    }
    
    override func hit(scene: GameScene) {
        super.hit(scene: scene)
        
        let ratio = CGFloat(hitsRemain)/CGFloat(maxHealth)
        self.fillColor = ColorUtils.shared.blend(.white, self.baseColor, ratio: ratio)

    }
    
    
    func sandToHome(scene:GameScene)->SandTower?{
        
        if let trip = scene.mapTiles.randomRoute(),
            scene.towersRemaining() > 0,
        let start = scene.tileOf(node: self),
            sandShipsRemaining > 0 {
            
            let route = Voyage(start: start, finish: trip.finish)
            let start:CGPoint
            
            let m = route.shortestRoute(map: scene.mapTiles, using: waterSet)
            
            if m.count > 1 {
                start = scene.mapTiles.convert(mappoint: m[1]) ?? self.position
            } else {
                start = self.position
            }
            
            let sandShip = SandTower(timeOverTile: 0.25, route: route)
            sandShip.position = start
            sandShip.fillColor = .yellow

            sandShip.run(sandShip.wakeAction(), withKey:"wake")
            sandShip.setScale(0.3)
            sandShip.run(SKAction.scale(to: 1, duration: 6))
            sandShipsRemaining -= 1
            return sandShip
        }
       
        return nil
    }
    
    func splitShip(scene:GameScene)->DefenderTower?{
        
        if  scene.towersRemaining() > 0,
            sandShipsRemaining > 0, self.hitsRemain > 3 ,  let startTile = scene.tileOf(node: self){
            
           
            
            
            let rou = Voyage(start: startTile, finish: self.route.finish)
            let m = rou.shortestRoute(map: scene.mapTiles, using: waterSet)
            
            let ret = DefenderTower(timeOverTile: self.waterSpeed / 10, route: rou)
            ret.hitsRemain = self.hitsRemain * 2/3
            ret.gun.clock.adjust(interval: self.gun.clock.length() * 2)
            ret.fillColor = .green
            ret.baseColor = ret.fillColor
            
            let start:CGPoint
            
            if m.count > 1 {
                start = scene.mapTiles.convert(mappoint: m[1]) ?? self.position
            } else {
                start = self.position
            }
            
            ret.position = start
            
            self.hitsRemain -= ret.hitsRemain
            self.gun.clock.reduce(factor: 0.7)
            self.run(SKAction.scale(by: 0.7, duration: 0.5))
            ret.run(SKAction.scale(by: 1.2, duration: 0.5))
            ret.allowsWin = false
            sandShipsRemaining -= 1
            return ret
        }
        
        return nil
    }
    
}



class TeraTower: TowerNode, Navigatable {
    
    var waterSpeed: Double = 1
    
    var route = Voyage.offGrid()
    var prior:MapPoint?
    var tilesRemaining = 10
    
    func allowedTiles() -> Set<Landscape> {
        return [.sand,.inland]
    }
    
    convenience init(timeOverTile:Double, route nextR:Voyage) {
        
        self.init(rectOf: CGSize(width:20,height:20), cornerRadius:4)
        self.fillColor = .green
        self.strokeColor = .black
        self.lineWidth = 2
        
        self.waterSpeed = timeOverTile
        self.route = nextR
        self.hitsRemain = 3
        self.zPosition = 3
        self.gun.clock.adjust(interval: timeOverTile)
        
        let body = SKPhysicsBody(circleOfRadius: 30)
        
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.Tower
        body.isDynamic = false
        body.contactTestBitMask = PhysicsCategory.Ship
        body.restitution = 0.5
        
        self.physicsBody = body
    }
    
    func spawnWake() {
        
    }
    
    
    
    func getDestPoint(scene:GameScene)->MapPoint?{
        guard let pos = scene.tileOf(node: self) else { return nil}
 
            var reachable:Set<MapPoint> = [pos]
            var already:Set<MapPoint> = []
            
            let allow = self.allowedTiles()
            
            while !reachable.isEmpty {
                 var nextSet:Set<MapPoint> = []
                for r in reachable {
                    
                    for x in r.adj(max: scene.mapTiles.mapAdj){
                        if !already.contains(x),
                            allow.contains(scene.mapTiles.kind(point: x)){
                            already.insert(x)
                            nextSet.insert(x)
                        }
                    }
 
                }
                
                reachable = nextSet
                
            }
        
        let beach = Array(already.filter({scene.mapTiles.kind(point: $0) == .sand }))
        
        guard !beach.isEmpty else { return nil}
        
        var bestIndex = 0
        var furthest = 0
        
        for (i,v ) in beach.enumerated(){
            if v.distance(manhattan: pos) > furthest{
                furthest = v.distance(manhattan: pos)
                bestIndex = i
            }
        }
        
        return beach[bestIndex]
        
        
    }
    
    override func checkAge(scene:GameScene)->Bool{
        
        guard let pos = scene.tileOf(node: self) else { return true}
        
        
        
        
        

        
        if gun.clock.needsUpdate() {
            
            if pos == route.finish {
                if let m = getDestPoint(scene:scene),
                    pos != m {
                    self.route = Voyage(start: pos, finish: m)
                    scene.adjust(traveler: self,existing: scene.towerTiles())
                }
                
                
            }
            
            
            
            if pos.path(to: self.route.finish, map: scene.mapTiles, using: self.allowedTiles()).count < 2 {
                if let m = getDestPoint(scene:scene) {
                    self.route = Voyage(start: pos, finish: m)
                } else {
                    self.route = Voyage(start: pos, finish: pos)
                }
            }
            
            if prior == nil, scene.mapTiles.kind(point: pos) == .sand{
                self.prior = pos
            }
           
            
        
        
        guard let p = self.prior,
            p != pos
            else { return true}
        
        if scene.mapTiles.kind(point: p) == .sand {
            scene.mapTiles.changeTile(at: p, to: .inland)
            tilesRemaining -= 1
            
            if tilesRemaining < 1 {
                self.die(scene: scene, isKill: true)
            }
        }
        
        
        self.prior = nil
            gun.clock.update()
            
        }
        
        return true
    }
    
    override func fire(at:MapPoint,scene:GameScene){
        return
    }
    
    
}

