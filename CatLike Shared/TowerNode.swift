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
class TowerNode: SKShapeNode {
    

    var gun = PirateGun(interval:1, flightDuration:0.2, radius:3)
    var levelTimer = PirateClock(6)
 
    var level = 0
    let maxHealth = 6
    var hitsRemain = 6

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
            
            self.run(SKAction.sequence([SKAction.scaleX(to: 1, y: 1, duration: interval),SKAction.scale(by: 0.6, duration: shrinkTime)]))
            
        } else {
            let shrink = SKAction.scale(by: 0.6, duration: shrinkTime)
            self.run(shrink)
        }
        
        levelTimer.update()
        self.gun.clock.tickNext()
    }
    
    
    
}


extension TowerNode : Fireable {
    
    func die(scene:GameScene, isKill:Bool){
        removeAllActions()
        physicsBody = nil
        self.gun.clock.enabled = false
        self.levelTimer.enabled = false
        self.strokeColor = .clear
       
        //print("tower died")
        if isKill {
            run(SKAction.scale(by: CGFloat(self.gun.radius) - 0.5, duration: 2))
            run(SKAction.sequence([SKAction.fadeOut(withDuration: 4),
                                   SKAction.run {
                                    scene.remove(tower: self)
                }]))
        } else {
            run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.1),
                                   SKAction.run {
                                    scene.remove(tower: self)
                }]))
            
            
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
            
            let checkset = scene.mapTiles.tiles(near:towerTile,radius:self.gun.radius + 1,kinds:towerScapes)
            
            var killSet:Set<MapPoint> = [towerTile]
            
            
            for checkTile in checkset {
                if checkTile != source,
                    checkTile != dest {
                    
                    killSet.insert(checkTile)
                    
                }
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
                scene.mapTiles.changeTile(at: x, to: .sand)
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
        
        if  let dest =  scene.convert(mappoint: at){
       
            let _ = TowerMissle(tower: self, dest: dest, flightDuration: gun.flightDuration)
            gun.clock.update()
            
            return
        }
    }
    
    
    
}

