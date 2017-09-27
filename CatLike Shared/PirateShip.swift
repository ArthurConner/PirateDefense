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
}

func randomShipKind()->ShipKind{
    let x = GKRandomSource.sharedRandom().nextUniform()
    if x < 0.6{
        return .galley
    }
    if x < 0.8 {
        return .row
    }
    
    if x < 0.9 {
        return .motor
    }
    
    return .battle
    
}

class CannonBall:SKShapeNode {
    

    convenience init(tower:PirateNode,dest:CGPoint,speed:Double) {
        
        self.init(circleOfRadius:8)
        self.fillColor = .black
        self.position = tower.position

        guard let board = tower.parent else {return}
        board.addChild(self)

        let body = SKPhysicsBody(circleOfRadius: 4)
        
        body.allowsRotation = false
        
        body.categoryBitMask = PhysicsCategory.CannonBall
        body.contactTestBitMask = PhysicsCategory.Tower
        
        body.restitution = 0.5
        self.physicsBody = body
        
        let act = SKAction.move(to: dest, duration: speed)
        self.run(SKAction.sequence([act,
                                    SKAction.removeFromParent()]))

        
    }
    
}



class PirateNode: SKShapeNode {
    
    var animations: [SKAction] = []
    
    var intervalTime:TimeInterval = 4
    var nextLaunch:Date = Date.distantPast
    var missleSpeed:Double = 0.8
    var waterSpeed:Double = 3
    var hitsRemain = 3
    var fireRadius = 2
    
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
            self.waterSpeed = modfier * 2
            body.restitution = 0.1
            self.hitsRemain = 1
            self.intervalTime = 3
            self.fireRadius = 3
        case .motor:
            self.init(ellipseOf:CGSize(width: 15, height: 30))
            self.fillColor = .purple
            body = SKPhysicsBody(circleOfRadius: 15)
            body.restitution = 0.1
            self.waterSpeed = modfier / 2
            self.hitsRemain = 1
            self.intervalTime = 8
            print("motor is now \(modfier / 2)")
        case .battle:
            self.init(ellipseOf:CGSize(width: 25, height: 50))
            self.fillColor = .black
            body = SKPhysicsBody(circleOfRadius: 35)
            body.restitution = 0.9
            self.waterSpeed = modfier * 8
            self.hitsRemain = 8
            self.intervalTime = 0.5
        }
        
        self.kind = aKind
        self.strokeColor = .black
        
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
    
   
}

extension PirateNode : Fireable {
    
    func die(scene:GameScene, isKill:Bool){
        removeAllActions()
        yScale = -1
        physicsBody = nil
        run(SKAction.sequence([
                               SKAction.removeFromParent()]))
    }
  
    func targetTiles(scene:GameScene)->Set<MapPoint>{
        
        guard nextLaunch < Date(timeIntervalSinceNow: 0) else { return  [] }
        
        guard  let shipTile = scene.tileOf(node: self) else {
            return []
        }
        
        let towerScapes:Set<Landscape> = [.sand]
        return scene.mapTiles.tiles(near:shipTile,radius:fireRadius,kinds:towerScapes)
        
    }
    
    func hit(scene:GameScene){
        self.hitsRemain -= 1
        
        guard  let shipTile = scene.tileOf(node: self),
            let dest = scene.mapTiles.endIsle?.harbor,
            let source =  scene.mapTiles.startIsle?.harbor else { return }
        
        if self.hitsRemain == 0 {
            
            
            self.die(scene:scene, isKill:true)
            for (i , boat) in scene.ships.enumerated() {
                if boat == self {
                    scene.ships.remove(at: i)
                    scene.hud.kills += 1
                    if scene.mapTiles.kind(point: shipTile) == .water {
                        scene.mapTiles.changeTile(at: shipTile, to: .sand)
                    } else {
                        scene.mapTiles.changeTile(at: shipTile, to: .sand)
                    }
                    let wSet:Set<Landscape> = [.water,.path]
                    let route = source.path(to: dest, map: scene.mapTiles, using: wSet)
                    if route.count < 2 {
                        scene.mapTiles.changeTile(at: shipTile, to: .path)
                    }
                    
                }
            }
            
            for (_ , boat) in scene.ships.enumerated() {
                scene.adjust(ship: boat)
            }
            
        }
    }
    
    func fire(at:MapPoint,scene:GameScene){
        guard nextLaunch < Date(timeIntervalSinceNow: 0) else { return }
        if  let dest =  scene.convert(mappoint: at){
            let _ = CannonBall(tower: self, dest: dest, speed: missleSpeed)
            nextLaunch = Date(timeIntervalSinceNow: intervalTime)
            return
        }
    }
    
 
   
}



