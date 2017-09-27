//
//  PirateShip.swift
//  CatLike
//
//  Created by Arthur  on 9/25/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import Foundation
import GameKit


enum ShipKind {
    case galley
    case row
    case motor
    case battle
    case destroyer
    case crusier
}








class PirateNode: SKShapeNode,  Fireable {
    
    var animations: [SKAction] = []
    
    var gun = PirateGun(interval:4, flightDuration:0.8, radius:3)
    var waterSpeed:Double = 3
    var hitsRemain = 3
   
    
    var kind:ShipKind = .galley
    
    convenience init(kind aKind:ShipKind, modfier:Double) {
        
        let body:SKPhysicsBody
        
        switch aKind {
        case .galley:
            self.init(ellipseOf:CGSize(width: 20, height: 45))
            self.fillColor = .brown
            body = SKPhysicsBody(circleOfRadius: 20)
            body.restitution = 0.5
            self.waterSpeed = modfier
        case .row:
            self.init(ellipseOf:CGSize(width: 10, height: 22))
            self.fillColor = .white
            body = SKPhysicsBody(circleOfRadius: 10)
            self.waterSpeed = modfier * 3
            body.restitution = 0.1
            
            self.hitsRemain = 1
            self.gun.clock.adjust(interval: 3)
            self.gun.radius = 1
           
        case .crusier:
            
            self.init(ellipseOf:CGSize(width: 24, height: 48))
            self.fillColor = .white
            body = SKPhysicsBody(circleOfRadius: 20)
            body.restitution = 0.5
            self.waterSpeed = modfier * 1.5
            self.hitsRemain = 1
            
            self.gun.clock.adjust(interval: 70)
            
        case .destroyer:
            
            self.init(ellipseOf:CGSize(width: 20, height: 47))
            self.fillColor = .red
            body = SKPhysicsBody(circleOfRadius: 20)
            body.restitution = 0.5
            self.waterSpeed = modfier * 3
            self.hitsRemain = 4
            self.gun.radius = 5
            self.gun.clock.adjust(interval: 1.5)
            
            
        case .motor:
            self.init(ellipseOf:CGSize(width: 15, height: 30))
            self.fillColor = .purple
            body = SKPhysicsBody(circleOfRadius: 15)
            body.restitution = 0.1
            self.waterSpeed = modfier / 1.4
            self.hitsRemain = 1
            self.gun.clock.adjust(interval: 8)
            print("motor is now \(modfier / 2)")
        case .battle:
            self.init(ellipseOf:CGSize(width: 25, height: 50))
            self.fillColor = .black
            body = SKPhysicsBody(circleOfRadius: 35)
            body.restitution = 0.9
            self.waterSpeed = modfier * 8
            self.hitsRemain = 8
            self.gun.clock.adjust(interval: 0.5)
        }
        
        self.kind = aKind
        self.strokeColor = .black
        self.gun.landscapes =   [.sand]
        
        body.allowsRotation = false
        
        body.categoryBitMask = PhysicsCategory.Ship
        body.contactTestBitMask = PhysicsCategory.Missle
        
        self.physicsBody = body
        
    }
    
    
    
    
    
    func spawnWake() {
        
        guard let board = self.parent else {return}

        let wake = SKShapeNode.init(circleOfRadius: 2)
         #if os(OSX)
        wake.fillColor = (self.fillColor.blended(withFraction: 0.6, of: .white)?.blended(withFraction: 0.4, of: .clear)) ?? .white
        #else
            var h:CGFloat = 0
            var s:CGFloat = 0
            var b:CGFloat = 0
            var a:CGFloat = 0
            
            self.fillColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            sand.fillColor = UIColor(hue: h, saturation: s/2, brightness: b * 2, alpha: 0.5)
            #endif
        wake.strokeColor = .clear
        wake.position = self.position
        
        wake.run(SKAction.sequence([
            SKAction.scale(to: 10, duration: 4)]))
        
        wake.run(SKAction.sequence([SKAction.fadeOut(withDuration: 7),
                                    SKAction.removeFromParent()]))
        
        
        board.insertChild(wake, at: board.children.count - 1)
 
    }
    

    
    func die(scene:GameScene, isKill:Bool){
        removeAllActions()
        yScale = -1
        physicsBody = nil
        run(SKAction.sequence([
                               SKAction.removeFromParent()]))
        
        
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
        
        guard  let shipTile = scene.tileOf(node: self),
            let dest = scene.mapTiles.endIsle?.harbor,
            let source =  scene.mapTiles.startIsle?.harbor else { return }
        
    
        if self.hitsRemain == 0 {
            
            
            var killShips:[PirateNode] = []
            defer{
                for x in killShips {
                    x.die(scene: scene, isKill: false)
                }
            }
            self.die(scene:scene, isKill:true)
            var keepShip:[PirateNode] = []
            for (_ , boat) in scene.ships.enumerated() {
                if let boatTile = scene.tileOf(node: boat), boatTile == shipTile {
                   
                    scene.hud.kills += 1
                    if scene.mapTiles.kind(point: shipTile) == .water {
                        scene.mapTiles.changeTile(at: shipTile, to: .sand)
                    } else {
                        scene.mapTiles.changeTile(at: shipTile, to: .sand)
                    }
                    
                    if boat != self {
                        killShips.append(boat)
                    }
                    
                    

                    
                } else {
                    keepShip.append(boat)
                }
            }
            
            scene.ships = keepShip
            
            let wSet:Set<Landscape> = [.water,.path]
            let route = source.path(to: dest, map: scene.mapTiles, using: wSet)
            if route.count < 2 {
                scene.mapTiles.changeTile(at: shipTile, to: .path)
                killShips.removeAll()
            }
            
            for (_ , boat) in scene.ships.enumerated() {
                scene.adjust(ship: boat)
            }
            
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
    var raftLeft = 1
    
    override   func die(scene:GameScene, isKill:Bool){
    
        
        if isKill, let shipTile = scene.tileOf(node: self) {
            
            let water:Set<Landscape> = [.water,.path]
            var lifeBoatTiles = scene.mapTiles.tiles(near:shipTile,radius:2,kinds:water)
            lifeBoatTiles.remove(shipTile)
            
            for x in scene.ships {
                
                if let otherTile = scene.tileOf(node: x){
                    lifeBoatTiles.remove(otherTile)
                }
           
            }
            
            for tile in lifeBoatTiles {
                
                
              if   let shipPosition = scene.convert(mappoint:tile) {
                
                let ship:PirateNode
                print("we have \(raftLeft) rafts")
                
                if  raftLeft > 0 {
                    let c = CruiserNode(kind: .crusier, modfier: 1)
                    c.raftLeft = raftLeft - 1
                    
                    let w:CGFloat = 9 // max(CGFloat(c.raftLeft) * 5,14)
                    let h = w * 2
                    
                    c.path = CGPath.init(ellipseIn: CGRect(x:-w,y:-h, width:w * 2, height:h * 2), transform: nil)
                        
                        //self.init(ellipseOf:CGSize(width: 24, height: 48))
                    ship = c
                } else {
                    ship = PirateNode(kind: .row, modfier: 1)
                }
                    
                
                    ship.position = shipPosition
                
                    scene.addChild(ship)
                    scene.ships.append(ship)
                    scene.adjust(ship: ship)
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
        return .destroyer
    }
    
    if x < 0.8 {
        return .motor
    }
    if x < 0.9 {
        return .crusier
    }
    
    return .battle
 
   // return .destroyer
    
}
func randomShip( modfier:Double) -> PirateNode{
    
    let kind = randomShipKind()
    
    guard kind != .crusier else {
        return CruiserNode(kind: kind, modfier: modfier)
    }
    
    return PirateNode(kind:kind, modfier:modfier)
    
}



