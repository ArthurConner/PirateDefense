//
//  PirateShip.swift
//  CatLike
//
//  Created by Arthur  on 9/25/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import Foundation
import GameKit


enum ShipKind: Int, Codable {
    case galley
    case row
    case motor
    case battle
    case destroyer
    case crusier
    case bomber
}

struct ShipProxy : Codable{
    
    let kind:ShipKind
    let shipID:String
    let position:CGPoint
    let angle:CGFloat
}


class PirateNode: SKSpriteNode,  Fireable, Navigatable {
    
    var gun = PirateGun(interval:4, flightDuration:0.8, radius:3)
    
    var hitsRemain = 3
    var kind:ShipKind = .galley
    
    var waterSpeed:Double = 3
    var route = Voyage.offGrid()
    var isDying = false
    
    var startModfier:Double = 0
    var startLevel:Int = 0
    
    func allowedTiles() -> Set<Landscape> {
        return routeSet
    }
    
    
    static let sinkSound = SKAction.playSoundFileNamed("Sink.caf",waitForCompletion: false)
    
    static let battleShipSound = SKAction.playSoundFileNamed("battleship.Basses.caf",waitForCompletion: true)
    static let cruiserSound = SKAction.playSoundFileNamed("cruiser.flute.caf",waitForCompletion: true)
    static let destroyerSound = SKAction.playSoundFileNamed("destroyer.Violas.caf",waitForCompletion: true)
    static let galleySound = SKAction.playSoundFileNamed("Galley.piano.caf",waitForCompletion: true)
    static let motorSound = SKAction.playSoundFileNamed("motorboat.violns.caf",waitForCompletion: true)
    
    let shipID = "\(Date.timeIntervalSinceReferenceDate)_\(GKRandomSource.sharedRandom().nextUniform())"
    
    #if os(OSX)
    var wakeColor = NSColor.white
    #else
    var wakeColor = UIColor.white
    #endif
    
    static func makeShip(kind aKind:ShipKind, modfier:Double, route r:Voyage, level shipLevel:Int)->PirateNode {
        
        let body:SKPhysicsBody
        let ship:PirateNode
        let soundName:String?
        let soundLevel:Float?
        
        switch aKind {
        case .galley:
            ship = PirateNode(imageNamed: "Galley" )
            ship.wakeColor = .brown
            body = SKPhysicsBody(circleOfRadius: 20)
            body.restitution = 0.5
            ship.waterSpeed = modfier
            soundName = "Galley.piano.caf"
            soundLevel = 0.4
            
        case .row:
            ship = PirateNode(imageNamed: "Row" )
            ship.wakeColor = .white
            body = SKPhysicsBody(circleOfRadius: 10)
            ship.waterSpeed = modfier * 3
            body.restitution = 0.1
            
            ship.hitsRemain = 1
            ship.gun.clock.adjust(interval: 3)
            ship.gun.radius = 1
            
            soundName = nil
            soundLevel = nil
            
        case .crusier:
            
            ship = CruiserNode(imageNamed: "Crusier" )
            ship.wakeColor = .white
            body = SKPhysicsBody(circleOfRadius: 20)
            body.restitution = 0.5
            ship.waterSpeed = modfier * 1.5
            ship.hitsRemain = 1
            
            ship.gun.clock.adjust(interval: 70)
            soundName =  "cruiser.flute.caf"
            soundLevel = 0.9
            
        case .bomber:
            
            let b = BomberNode(imageNamed: "Bomber" )
            ship = b
            ship.wakeColor = .red
            body = SKPhysicsBody(circleOfRadius: 20)
            body.restitution = 0.5
            ship.waterSpeed = modfier * max(1, Double(shipLevel))
            ship.hitsRemain = 1
            b.blastRadius += shipLevel
            
            ship.gun.clock.adjust(interval: 70)
            soundName =  "cruiser.flute.caf"
            soundLevel = 0.9
            
        case .destroyer:
            
            ship = PirateNode(imageNamed: "Destroyer" )
            ship.wakeColor = .red
            body = SKPhysicsBody(circleOfRadius: 20)
            body.restitution = 0.5
            ship.waterSpeed = modfier * 3
            ship.hitsRemain = 4 + shipLevel
            ship.gun.radius = 5
            ship.gun.clock.adjust(interval: 0.7)
            soundLevel = 0.5
            soundName = "destroyer.Violas.caf"
            
        case .motor:
            ship = PirateNode(imageNamed: "Motor" )
            ship.wakeColor = .green
            body = SKPhysicsBody(circleOfRadius: 15)
            body.restitution = 0.1
            ship.waterSpeed = modfier / 1.4
            ship.hitsRemain = 1
            ship.gun.clock.adjust(interval: 8)
            print("motor is now \(modfier / 2)")
            soundLevel = 0.5
            soundName = "motorboat.violns.caf"
            
        case .battle:
            ship = PirateNode(imageNamed: "Battleship" )
            ship.wakeColor = .black
            body = SKPhysicsBody(circleOfRadius: 35)
            body.restitution = 0.9
            ship.waterSpeed = modfier * 8
            ship.hitsRemain = 6 + shipLevel
            ship.gun.clock.adjust(interval: 0.5)
            soundLevel = 1
            soundName = "battleship.Basses.caf"
        }
        
        if let s = soundName{
            let me = SKAudioNode(fileNamed:s)
            me.name = "seasound"
            me.autoplayLooped = true
            me.isPositional = true
            ship.addChild(me)
            
            if let l = soundLevel {
                me.run(SKAction.changeVolume(to: l, duration: 3))
            }
            
        }
        
        ship.route = r
        ship.kind = aKind
        ship.zPosition = 3
        ship.startLevel = shipLevel
        ship.startModfier = modfier
        
        ship.gun.landscapes =   [.sand,.water,.path]
        ship.gun.clock.tickNext()
        body.allowsRotation = false
        
        body.categoryBitMask = PhysicsCategory.Ship
        body.contactTestBitMask = PhysicsCategory.Missle
        
        ship.physicsBody = body
        ship.setScale(0.3)
        ship.run(SKAction.scale(to: 0.75, duration: 6))
        
        return ship
    }
    
    func proxy()->ShipProxy {
        return ShipProxy(kind:self.kind , shipID: self.shipID, position: self.position, angle:self.zRotation)
    }
    
    func didFinish(map handler:MapHandler)->Bool{
        guard let me = handler.map(coordinate: self.position) else { return true}
        return me == route.finish
    }
    
    func spawnWake() {
        
        guard let board = self.parent else {return}
        
        let wake = SKShapeNode.init(circleOfRadius: 2)
        #if os(OSX)
            wake.fillColor = (self.wakeColor.blended(withFraction: 0.6, of: .white)?.blended(withFraction: 0.4, of: .clear)) ?? .white
        #else
            var h:CGFloat = 0
            var s:CGFloat = 0
            var b:CGFloat = 0
            var a:CGFloat = 0
            
            self.wakeColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            wake.fillColor = UIColor(hue: h, saturation: s/2, brightness: b * 2, alpha: 0.5)
        #endif
        wake.strokeColor = .clear
        wake.position = self.position
        
        wake.run(SKAction.sequence([
            SKAction.scale(to: 10, duration: 4)]))
        
        wake.run(SKAction.sequence([SKAction.fadeOut(withDuration: 4),
                                    SKAction.removeFromParent()]))
        wake.zPosition = 2
        board.insertChild(wake, at: board.children.count - 1)
        
        
    }
    
    
    
    func die(scene:GameScene, isKill:Bool){
        
        guard !isDying else { return }
        isDying = true
        
        guard  let shipTile = scene.tileOf(node: self) else { return }
        removeAllActions()
        physicsBody = nil
        
        scene.removeFrom(shipTile: shipTile)
        
        if scene.possibleToSand(at:shipTile){
            scene.redirectAllShips()
        }
        
        if isKill {
            if scene.shouldPlaySound(){
                scene.run(PirateNode.sinkSound)
            }
        }
        
    }
    
    
    func targetTiles(scene:GameScene)->Set<MapPoint>{
        
        guard gun.clock.needsUpdate() else { return  [] }
        
        guard  let shipTile = scene.tileOf(node: self) else {
            return []
        }
        
        return scene.mapTiles.tiles(near:shipTile,radius:self.gun.radius,kinds:self.gun.landscapes)
        
    }
    
    func hit(scene:GameScene){
        self.hitsRemain -= 1
        guard  let shipTile = scene.tileOf(node: self) else { return }
        
        if self.hitsRemain < 1 {
            scene.mapTiles.changeTile(at: shipTile, to: .path)
            self.die(scene:scene, isKill:true)
        }
    }
    
    
    func fire(at:MapPoint,scene:GameScene){
        guard self.gun.clock.needsUpdate() else { return }
        if  let dest =  scene.mapTiles.convert(mappoint: at){
            let ball = CannonBall(tower: self, dest: dest, speed: self.gun.flightDuration)
            self.gun.clock.update()
            if scene.shouldPlaySound()  {
                
                
                let me = SKAudioNode(fileNamed:"Gun Cannon.caf")
                me.name = "seasound"
                me.isPositional = true
                
                ball.addChild(me)
                me.run(SKAction.changeVolume(to: 0.3, duration: 0.01))
            }
            return
        }
    }
    
    
    
}

class BomberNode : PirateNode {
    
     var blastRadius = GKRandomSource.sharedRandom().nextInt(upperBound: 4)+1
    
    
    override func die(scene:GameScene, isKill:Bool){
        
        var towersDestroyed:[Fireable] = []
        
        guard !self.isDying else { return }
       
        
        defer {
            for x in towersDestroyed {
                if let tow = x as? TowerNode {
                    tow.die(scene: scene, isKill: true)
                } else if let s = x as? PirateNode {
                    s.die(scene: scene, isKill: true)
                }
            }
        }
        
        if isKill, let shipTile = scene.tileOf(node: self) {
            
            var list = shipTile.adj(max: scene.mapTiles.mapAdj)
            
            var tilesboom:Set<MapPoint> = []
            
            for _ in 0..<blastRadius {
                var nextL:[MapPoint] = []
                for x in list {
                    if !tilesboom.contains(x){
                        tilesboom.insert(x)
                        let adj = x.adj(max: scene.mapTiles.mapAdj)
                        for y in adj {
                           // tilesboom.insert(y)
                            nextL.append(y)
                        }
                        
                    }
                }
                list = nextL
                
            }
            
            func remove(texture:Landscape,toNext:Landscape) {
                
                let sandPoints = tilesboom.filter({ scene.mapTiles.kind(point: $0) == texture})
                
                for x in sandPoints {
                    
                    func isGood(node:SKNode)->Bool{
                        if let _ = node as? Fireable,
                            let pos = scene.tileOf(node: node),
                            x == pos {
                            return true
                        }
                        
                        return false
                        
                    }
                    let killMe = scene.children.filter(isGood) as! [Fireable]
                    var shouldChange = true
                    for x in killMe {
                        
                        let p = scene.tileOf(node: x as! SKNode)!
                        
                        let damage = max(self.blastRadius - p.distance(manhattan: scene.tileOf(node: self)!),1) * 5
                        
                        
                        
                        if x.hitsRemain < damage {
                            towersDestroyed.append(x)
                        } else {
                            let stop = x.hitsRemain - damage
                            print("damaged \(x.hitsRemain) by \(damage)")
                            while x.hitsRemain > stop {
                                x.hit(scene: scene)
                            }
                            shouldChange = false
                        }
                    }
                    
                    //towersDestroyed.append(contentsOf: killMe )
                    
                    if shouldChange {
                      
                        scene.mapTiles.changeTile(at: x, to: toNext)
                        
                    }
                }
                
            }
            
            print("basting radius \(blastRadius) with tiles \(tilesboom.count)")
            
            remove(texture: .water, toNext: .water)
            remove(texture: .sand, toNext: .water)
            remove(texture: .inland, toNext: .sand)
            
        }
        
        super.die(scene: scene, isKill: isKill)
    }
}

class CruiserNode : PirateNode{
    var raftLeft = 0
    
    
    override func die(scene:GameScene, isKill:Bool){
        
        if isKill, let shipTile = scene.tileOf(node: self) {
            
            let lifeBoatTiles = scene.availableWater(around:shipTile)
            for tile in lifeBoatTiles {
                
                if let shipPosition = scene.mapTiles.convert(mappoint:tile) {
                    
                    let ship:PirateNode
                    if  raftLeft > 0,
                        let c = PirateNode.makeShip(kind: .crusier, modfier: 2, route: self.route,level: 0) as? CruiserNode{
                        
                        c.raftLeft = raftLeft - 1
                        
                        ship = c
                        
                    } else {
                        ship = PirateNode.makeShip(kind: .row, modfier: 1, route: self.route,level: 0)
                    }
                    
                    
                    ship.position = shipPosition
                    scene.add(ship:ship)
                    ship.gun.clock.update()
                    
                }
                
            }
            
            
        }
        
        super.die(scene: scene, isKill: isKill)
    }
    
    
}


/// Generates a random ship with a probabilty
///
/// - Returns: A specfic ship kind


func percentage(of:ShipKind, at:TimeInterval)->Double{
    
    let base:Double
    let slope:Double
    
    let final:Double
    
    switch of {
    case .battle:
        base = -300
        slope = 1.5
        final = 80
    case .galley:
        base = 1
        slope = 2
        final = 500
    case .row:
        base = -10
        slope = 0
        final = -10
    case .motor:
        base = 10
        slope = 0.75
        final = 20
    case .destroyer:
        base = -220
        slope = 1.2
        final = 150
    case .crusier:
        base = 0
        slope = 0.8
        final = 20
    case .bomber:
        base = -70
        slope = 0.8
        final = 60
    }
    
    return  min(max((base + slope * at)/5 , 0 ),final)
}

var shipBaseCounter = 0

func randomShipKind( at:TimeInterval)->ShipKind{
    
    if (at < 1) {
        shipBaseCounter = 0
    } else
    {
        shipBaseCounter += 1
        
    }
    
    let kinds:[ShipKind] = [.battle,.galley,.motor, .destroyer,.crusier, .bomber].filter({percentage(of:$0, at:at) > 0 })
    let ranks:[Double] = kinds.map({percentage(of:$0, at:at)})
    let total = ranks.reduce(0, +)
    
    let xp = Double(GKRandomSource.sharedRandom().nextUniform())
    
    let x = xp * total
    
    var sum:Double = 0
    
    //  print("number \(x) to \(xp)")
    /*
     if shipBaseCounter > 5 {
     var sum2:Int = 0
     print("\n checking \(x) which is \(x / total) at \(at)")
     for (i, r) in ranks.enumerated() {
     
     
     let k = kinds[i]
     
     let inter = Int( r / total * 100.0)
     print(" \(k)  \(sum2) - \(sum2 + inter)")
     sum2 += inter
     
     }
     shipBaseCounter = 0
     }
     */
    
    for (i, r) in ranks.enumerated() {
        
        sum += r
        if x < sum {
            //  print(kinds[i])
            return kinds[i]
        }
    }
    
    
    return .galley
    
    
}

func randomShip( modfier:Double, route:Voyage, at:TimeInterval,level:Int) -> PirateNode{
    
    let kind = randomShipKind(at:at)
    return PirateNode.makeShip(kind:kind, modfier:modfier, route: route, level:level)
    
}



