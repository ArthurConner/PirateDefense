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



class PirateNode: SKSpriteNode,  Fireable {
    

   
    
    var gun = PirateGun(interval:4, flightDuration:0.8, radius:3)
    var waterSpeed:Double = 3
    var hitsRemain = 3
    var kind:ShipKind = .galley
    
    let shipID = "\(Date.timeIntervalSinceReferenceDate)_\(GKRandomSource.sharedRandom().nextUniform())"
    
     #if os(OSX)
    var wakeColor = NSColor.white
    #else
    var wakeColor = UIColor.white
    #endif
    
    static func makeShip(kind aKind:ShipKind, modfier:Double)->PirateNode {
        
        let body:SKPhysicsBody
        
       
        let ship:PirateNode
       
         
         
        switch aKind {
        case .galley:
            ship = PirateNode(imageNamed: "Galley" )
            ship.wakeColor = .brown
            body = SKPhysicsBody(circleOfRadius: 20)
            body.restitution = 0.5
            ship.waterSpeed = modfier
        case .row:
            ship = PirateNode(imageNamed: "Row" )
            ship.wakeColor = .white
            body = SKPhysicsBody(circleOfRadius: 10)
            ship.waterSpeed = modfier * 3
            body.restitution = 0.1
            
            ship.hitsRemain = 1
            ship.gun.clock.adjust(interval: 3)
            ship.gun.radius = 1
            
            
        case .crusier:
            
            ship = CruiserNode(imageNamed: "Crusier" )
            ship.wakeColor = .white
            body = SKPhysicsBody(circleOfRadius: 20)
            body.restitution = 0.5
            ship.waterSpeed = modfier * 1.5
            ship.hitsRemain = 1
            
            ship.gun.clock.adjust(interval: 70)
            
        case .destroyer:
            
            ship = PirateNode(imageNamed: "Destroyer" )
            ship.wakeColor = .red
            body = SKPhysicsBody(circleOfRadius: 20)
            body.restitution = 0.5
            ship.waterSpeed = modfier * 3
            ship.hitsRemain = 4
            ship.gun.radius = 5
            ship.gun.clock.adjust(interval: 0.7)
            
            
        case .motor:
            ship = PirateNode(imageNamed: "Motor" )
            ship.wakeColor = .purple
            body = SKPhysicsBody(circleOfRadius: 15)
            body.restitution = 0.1
            ship.waterSpeed = modfier / 1.4
            ship.hitsRemain = 1
            ship.gun.clock.adjust(interval: 8)
            print("motor is now \(modfier / 2)")
        case .battle:
            ship = PirateNode(imageNamed: "Battleship" )
            ship.wakeColor = .black
            body = SKPhysicsBody(circleOfRadius: 35)
            body.restitution = 0.9
            ship.waterSpeed = modfier * 8
            ship.hitsRemain = 6
            ship.gun.clock.adjust(interval: 0.5)
        }

        
    
       
       
       
        ship.kind = aKind
        ship.zPosition = 3
        
        ship.gun.landscapes =   [.sand]
        ship.gun.clock.tickNext()
        body.allowsRotation = false
        
        body.categoryBitMask = PhysicsCategory.Ship
        body.contactTestBitMask = PhysicsCategory.Missle
        
        ship.physicsBody = body
        ship.run(SKAction.scale(by: 0.5, duration: 0.1))
        
        return ship
    }
    
    func proxy()->ShipProxy {
        return ShipProxy(kind:self.kind , shipID: self.shipID, position: self.position, angle:self.zRotation)
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
        removeAllActions()
        physicsBody = nil
        
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
            scene.removeFrom(shipTile: shipTile)
            
            if scene.mapTiles.mainRoute().count < 2 {
                scene.mapTiles.changeTile(at: shipTile, to: .path)
            }
            
            scene.redirectAllShips()

        }
    }
    
    func fire(at:MapPoint,scene:GameScene){
        guard self.gun.clock.needsUpdate() else { return }
        if  let dest =  scene.convert(mappoint: at){
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
                
                if   let shipPosition = scene.convert(mappoint:tile) {
                    
                    let ship:PirateNode
                    // print("we have \(raftLeft) rafts")
                    
                    if  raftLeft > 0,
                        let c = PirateNode.makeShip(kind: .crusier, modfier: 2) as? CruiserNode{
                        
                        c.raftLeft = raftLeft - 1

                        ship = c
                        
                    } else {
                        ship = PirateNode.makeShip(kind: .row, modfier: 1)
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
func randomShip( modfier:Double) -> PirateNode{
    
    let kind = randomShipKind()
    /*
    guard kind != .crusier else {
      
        return CruiserNode(kind: kind, modfier: modfier)
 
    }
    */
    return PirateNode.makeShip(kind:kind, modfier:modfier)
    
}


