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
        
       // print("going from level \(prior) to \(level) in \(shrinkTime)")
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
        
        if hitsRemain == 0 {
            guard   let towerTile  = scene.tileOf(node: self) else   { return }
            
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
                if let t = scene.tower(at:tile) {
                    t.die(scene: scene, isKill: true)
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
            //self.run(SKAction.scale(by: 0.9, duration: 0.3))
            let ratio = CGFloat(hitsRemain)/CGFloat(maxHealth)
            #if os(OSX)
                self.fillColor = NSColor.white.blended(withFraction: ratio, of: .red) ?? .purple
            #else
                self.fillColor = UIColor.purple
            #endif
            
        }
        
    }
    
    func fire(at:MapPoint,scene:GameScene){
        guard gun.clock.needsUpdate() else { return }
        
        if  let dest =  scene.mapTiles.convert(mappoint: at){
       
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

    
    func allowedTiles() -> Set<Landscape> {
        return routeSet
    }
    
    static func outsidePath()->CGPath{
        let bezier2Path = CGMutablePath()
        
        let trans = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 55)
       
        func pathPoint(x:CGFloat,y:CGFloat)->CGPoint{
            return CGPoint(x:x,y:y).applying(trans)
        }
        bezier2Path.move(to: pathPoint(x: 14, y: 0))
        bezier2Path.addCurve(to: pathPoint(x: 15.8, y: 1), control1: pathPoint(x: 14, y: -0), control2: pathPoint(x: 15.58, y: 0.96))
        bezier2Path.addCurve(to: pathPoint(x: 17.46, y: 2.22), control1: pathPoint(x: 15.8, y: 1), control2: pathPoint(x: 17.31, y: 2))
        bezier2Path.addCurve(to: pathPoint(x: 25.69, y: 19.58), control1: pathPoint(x: 22.04, y: 7), control2: pathPoint(x: 24.79, y: 12.78))
        bezier2Path.addCurve(to: pathPoint(x: 25.87, y: 21.24), control1: pathPoint(x: 25.76, y: 20.12), control2: pathPoint(x: 25.82, y: 20.68))
        bezier2Path.addCurve(to: pathPoint(x: 26, y: 23.3), control1: pathPoint(x: 25.94, y: 21.9), control2: pathPoint(x: 25.98, y: 22.57))
        bezier2Path.addLine(to: pathPoint(x: 26, y: 44.06))
        bezier2Path.addCurve(to: pathPoint(x: 25.97, y: 44.67), control1: pathPoint(x: 26, y: 44.26), control2: pathPoint(x: 25.99, y: 44.46))
        bezier2Path.addCurve(to: pathPoint(x: 23.06, y: 52.38), control1: pathPoint(x: 25.87, y: 47.67), control2: pathPoint(x: 24.9, y: 50.24))
        bezier2Path.addCurve(to: pathPoint(x: 20.87, y: 54.38), control1: pathPoint(x: 22.38, y: 53.18), control2: pathPoint(x: 21.64, y: 53.85))
        bezier2Path.addLine(to: pathPoint(x: 20.68, y: 54.51))
        bezier2Path.addCurve(to: pathPoint(x: 17, y: 56), control1: pathPoint(x: 19.55, y: 55.24), control2: pathPoint(x: 18.32, y: 55.71))
        bezier2Path.addCurve(to: pathPoint(x: 14.02, y: 55.99), control1: pathPoint(x: 16.96, y: 56), control2: pathPoint(x: 14.02, y: 55.99))
        bezier2Path.addCurve(to: pathPoint(x: 13.5, y: 55.99), control1: pathPoint(x: 14, y: 55.99), control2: pathPoint(x: 13.8, y: 55.99))
        bezier2Path.addCurve(to: pathPoint(x: 13, y: 55.99), control1: pathPoint(x: 13.2, y: 55.99), control2: pathPoint(x: 13, y: 55.99))
        bezier2Path.addCurve(to: pathPoint(x: 10.04, y: 56), control1: pathPoint(x: 12.98, y: 55.99), control2: pathPoint(x: 10.04, y: 56))
        bezier2Path.addCurve(to: pathPoint(x: 6.32, y: 54.51), control1: pathPoint(x: 8.68, y: 55.71), control2: pathPoint(x: 7.45, y: 55.24))
        bezier2Path.addLine(to: pathPoint(x: 6.13, y: 54.38))
        bezier2Path.addCurve(to: pathPoint(x: 3.94, y: 52.38), control1: pathPoint(x: 5.36, y: 53.85), control2: pathPoint(x: 4.62, y: 53.18))
        bezier2Path.addCurve(to: pathPoint(x: 1.03, y: 44.67), control1: pathPoint(x: 2.1, y: 50.24), control2: pathPoint(x: 1.13, y: 47.67))
        bezier2Path.addCurve(to: pathPoint(x: 1, y: 44.06), control1: pathPoint(x: 1.01, y: 44.46), control2: pathPoint(x: 1, y: 44.26))
        bezier2Path.addLine(to: pathPoint(x: 1, y: 23.3))
        bezier2Path.addCurve(to: pathPoint(x: 1.13, y: 21.24), control1: pathPoint(x: 1.02, y: 22.57), control2: pathPoint(x: 1.06, y: 21.9))
        bezier2Path.addCurve(to: pathPoint(x: 1.31, y: 19.58), control1: pathPoint(x: 1.18, y: 20.68), control2: pathPoint(x: 1.24, y: 20.12))
        bezier2Path.addCurve(to: pathPoint(x: 9.54, y: 2.22), control1: pathPoint(x: 2.21, y: 12.78), control2: pathPoint(x: 4.96, y: 7))
        bezier2Path.addCurve(to: pathPoint(x: 11.2, y: 1), control1: pathPoint(x: 9.69, y: 2), control2: pathPoint(x: 11.2, y: 1))
        bezier2Path.addCurve(to: pathPoint(x: 13, y: 0), control1: pathPoint(x: 11.42, y: 0.96), control2: pathPoint(x: 13, y: 0))
        bezier2Path.addLine(to: pathPoint(x: 14, y: 0))
        bezier2Path.addLine(to: pathPoint(x: 14, y: 0))
        
        return bezier2Path
        
        
    }
    
    convenience init(timeOverTile:Double, route nextR:Voyage) {
        
       
        
        self.init(ellipseOf: CGSize(width: 25, height: 58))
        //self.init(path: DefenderTower.outsidePath())
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
            scene.gameState = .win
            return false
        }
        
        return true
    }
    


    
    
}

