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
class TowerNode: SKShapeNode {
    

    var gun = PirateGun(interval:1, flightDuration:0.2, radius:3)
    var levelTimer = PirateClock(10)
 
    var level = 0
    var hitsRemain = 10

    convenience init(range:CGFloat) {
        
        self.init(circleOfRadius:20)
        self.fillColor = .red
        self.strokeColor = .black
        self.lineWidth = 3
        self.gun.landscapes = [.water,.path]
        
        let body = SKPhysicsBody(circleOfRadius: 20)
        
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.Tower
        body.isDynamic = false
        
        body.restitution = 0.5

        self.physicsBody = body
        
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
            #if os(OSX)
                self.fillColor = NSColor.red.blended(withFraction: 0.25, of: .white) ?? .purple
            #else
                self.fillColor = UIColor.purple
            #endif
            gun.clock.adjust(interval: 1.5)
            level = 1
        case 1:
            #if os(OSX)
                self.fillColor = NSColor.red.blended(withFraction: 0.75, of: .white) ?? .orange
            #else
                self.fillColor = UIColor.blue
            #endif
            
          
             gun.clock.adjust(interval: 2)
            level = 2
            
        case 2:
            self.fillColor = .white
 
            gun.clock.adjust(interval: 2.25)
            level = 3
        default:
            level = 0
            self.fillColor = .red
            gun.clock.adjust(interval: 1)
        }
        
        
        
        var shrinkTime = levelTimer.length()
        
        print("going from level \(prior) to \(level) in \(shrinkTime)")
        if prior < 0 {
            let interval = min(0.2,shrinkTime)
            shrinkTime = shrinkTime - interval
   
            self.run(SKAction.sequence([SKAction.scale(to: 1.5, duration: interval),SKAction.scale(to: 0.8, duration: shrinkTime)]))
            
        } else {
            let shrink = SKAction.scale(to: 0.8, duration: shrinkTime)
            self.run(shrink)
        }
        
        levelTimer.update()
    }
    
    
    
}


extension TowerNode : Fireable {
    
    func die(scene:GameScene, isKill:Bool){
        removeAllActions()
        physicsBody = nil
        if  let towerTile = scene.tileOf(node: self) {
            scene.towerLocations[towerTile] = nil
            
        }
        print("tower died")
        if isKill {
            run(SKAction.scale(by: CGFloat(self.gun.radius) - 0.5, duration: 2))
            run(SKAction.sequence([SKAction.fadeOut(withDuration: 3),
                                   SKAction.removeFromParent()]))
        } else {
            run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.2),
                                   SKAction.removeFromParent()]))
            
            
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
            guard   let towerTile  = scene.tileOf(node: self),
                let dest = scene.mapTiles.endIsle?.harbor,
                let source =  scene.mapTiles.startIsle?.harbor  else
            { return }
            
            let towerScapes:Set<Landscape> = [.sand]
            
            let checkset = scene.mapTiles.tiles(near:towerTile,radius:self.gun.radius,kinds:towerScapes)
            
            var killSet:Set<MapPoint> = [towerTile]
            
            let landscapeToKeep:Set<Landscape> = [.top,.inland]
            
            for checkTile in checkset {
                if checkTile != source,
                    checkTile != dest {
                    let f = checkTile.adj(max: scene.mapTiles.mapAdj).filter{ landscapeToKeep.contains(scene.mapTiles.kind(point: $0))}
                    if f.isEmpty{
                        killSet.insert(checkTile)
                    }
                }
            }
            for tile in killSet {
                if let t = scene.towerLocations[tile] {
                    t.die(scene: scene, isKill: true)
                    scene.towerLocations[tile] = nil
                }
                scene.mapTiles.changeTile(at: tile, to: .water)
            }
            
            for (_ , boat) in scene.ships.enumerated() {
                scene.adjust(ship: boat)
            }
            
        } else {
            self.run(SKAction.scale(by: 0.9, duration: 0.3))
        }
        
    }
    
    func fire(at:MapPoint,scene:GameScene){
        guard gun.clock.needsUpdate() else { return }
        
        if  let dest =  scene.convert(mappoint: at){
            if let place = scene.tileOf(node: self) {
                print("firing from \(place) to \(at) which is \(dest)")
            }
            let _ = TowerMissle(tower: self, dest: dest, flightDuration: gun.flightDuration)
            gun.clock.update()
            
            return
        }
    }
    
    
    
}

