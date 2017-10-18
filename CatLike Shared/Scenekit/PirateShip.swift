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
    
    static func makeShip(kind aKind:ShipKind, modfier:Double, route r:Voyage)->PirateNode {
        
        let body:SKPhysicsBody
        
       
        let ship:PirateNode
       
        let soundName:String?
        
         
        switch aKind {
        case .galley:
            ship = PirateNode(imageNamed: "Galley" )
            ship.wakeColor = .brown
            body = SKPhysicsBody(circleOfRadius: 20)
            body.restitution = 0.5
            ship.waterSpeed = modfier
            soundName = "Galley.piano.caf"
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
        case .crusier:
            
            ship = CruiserNode(imageNamed: "Crusier" )
            ship.wakeColor = .white
            body = SKPhysicsBody(circleOfRadius: 20)
            body.restitution = 0.5
            ship.waterSpeed = modfier * 1.5
            ship.hitsRemain = 1
            
            ship.gun.clock.adjust(interval: 70)
            soundName =  "cruiser.flute.caf"
        case .destroyer:
            
            ship = PirateNode(imageNamed: "Destroyer" )
            ship.wakeColor = .red
            body = SKPhysicsBody(circleOfRadius: 20)
            body.restitution = 0.5
            ship.waterSpeed = modfier * 3
            ship.hitsRemain = 4
            ship.gun.radius = 5
            ship.gun.clock.adjust(interval: 0.7)
            
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
            soundName = "motorboat.violns.caf"
        case .battle:
            ship = PirateNode(imageNamed: "Battleship" )
            ship.wakeColor = .black
            body = SKPhysicsBody(circleOfRadius: 35)
            body.restitution = 0.9
            ship.waterSpeed = modfier * 8
            ship.hitsRemain = 6
            ship.gun.clock.adjust(interval: 0.5)
            soundName = "battleship.Basses.caf"
        }

        if let s = soundName{
            let me = SKAudioNode(fileNamed:s)
            me.name = "seasound"
            me.autoplayLooped = true
            me.isPositional = true
            ship.addChild(me)
           
        }
        
       ship.route = r
       
        ship.kind = aKind
        ship.zPosition = 3
        
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
        /*
        let wake = addTrail(name: "SmokeTrail")
        run(SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.run() {
                self.removeTrail(trail:wake)
            }
            ]))
    
        
 
        
        board.addChild(wake)
        */
    
       
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
        
        wake.run(SKAction.sequence([SKAction.fadeOut(withDuration: 7),
                                    SKAction.removeFromParent()]))
        
         wake.zPosition = 2
        
        board.insertChild(wake, at: board.children.count - 1)

        
    }
    
    
    
    func die(scene:GameScene, isKill:Bool){
        
        guard  let shipTile = scene.tileOf(node: self) else { return }
        
        removeAllActions()
        physicsBody = nil
    
        scene.removeFrom(shipTile: shipTile)
        
        if scene.possibleToSand(at:shipTile){
            scene.redirectAllShips()
        }
        
        if isKill {
            scene.run(PirateNode.sinkSound)
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
        
        
        if self.hitsRemain == 0 {
            scene.mapTiles.changeTile(at: shipTile, to: .path)
 
            self.die(scene:scene, isKill:true)

        }
    }
    
    func fire(at:MapPoint,scene:GameScene){
        guard self.gun.clock.needsUpdate() else { return }
        if  let dest =  scene.mapTiles.convert(mappoint: at){
            let _ = CannonBall(tower: self, dest: dest, speed: self.gun.flightDuration)
            self.gun.clock.update()
            return
        }
    }
    
    
    
}

class CruiserNode : PirateNode{
    var raftLeft = 0
    
  
    override  func die(scene:GameScene, isKill:Bool){

        if isKill, let shipTile = scene.tileOf(node: self) {
            
            let lifeBoatTiles = scene.availableWater(around:shipTile)
            for tile in lifeBoatTiles {
                
                if   let shipPosition = scene.mapTiles.convert(mappoint:tile) {
                    
                    let ship:PirateNode
                    // print("we have \(raftLeft) rafts")
                    
                    if  raftLeft > 0,
                        let c = PirateNode.makeShip(kind: .crusier, modfier: 2, route: self.route) as? CruiserNode{
                        
                        c.raftLeft = raftLeft - 1

                        ship = c
                        
                    } else {
                        ship = PirateNode.makeShip(kind: .row, modfier: 1, route: self.route)
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

func randomShipKind()->ShipKind{
    
    
    let x = GKRandomSource.sharedRandom().nextUniform()
    if x < 0.6{
        return .galley
    }
    if x < 0.7 {
        return .crusier
    }
    
    if x < 0.85 {
        return .motor
    }
    if x < 0.95 {
        return .destroyer
    }
    
    return .battle
    
    // return .destroyer
    
}
func randomShip( modfier:Double, route:Voyage) -> PirateNode{
    
    let kind = randomShipKind()

    return PirateNode.makeShip(kind:kind, modfier:modfier, route: route)
    
}



