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
    
    convenience init(tower:TowerNode,dest:CGPoint,speed:Double) {
        
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
        
        let act = SKAction.move(to: dest, duration: speed)
        self.run(SKAction.sequence([act,
                                    SKAction.removeFromParent()]))
        
    }
    
}
class TowerNode: SKShapeNode {
    
    // var watchTiles:Set<MapPoint> = []
    var intervalTime:TimeInterval = 1
    var nextLaunch:Date = Date.distantPast
    
    var expireTime:Date = Date(timeIntervalSinceNow: 15)
    var expireInterval:TimeInterval = 5
    
    var missleSpeed:Double = 0.2
    var level = 0
    var hitsRemain = 10
    
    var fireRadius = 3
    
    
    convenience init(range:CGFloat) {
        
        self.init(circleOfRadius:20)
        self.fillColor = .red
        self.strokeColor = .black
        self.lineWidth = 3
        
        let body = SKPhysicsBody(circleOfRadius: 20)
        
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.Tower
        body.isDynamic = false
        
        body.restitution = 0.5
        self.physicsBody = body
        
    }
    
    func checkAge(scene:GameScene)->Bool{
        if self.expireTime < Date(timeIntervalSinceNow: 0){
            
            if level == 3 {
                if  let towerTile = scene.tileOf(node: self) {
                    scene.mapTiles.changeTile(at: towerTile, to: .inland)
                }
                self.die(scene: scene, isKill: false)
                return false
            } else {
                upgrade()
                self.expireTime = Date(timeIntervalSinceNow: expireInterval)
            }
        }
        return true
    }
    
    func upgrade(){
        
        switch level {
        case 0:
            #if os(OSX)
                self.fillColor = NSColor.red.blended(withFraction: 0.25, of: .white) ?? .purple
            #else
                self.fillColor = UIColor.purple
            #endif
            intervalTime = 1.5
            level = 1
        case 1:
            #if os(OSX)
                self.fillColor = NSColor.red.blended(withFraction: 0.75, of: .white) ?? .orange
            #else
                self.fillColor = UIColor.blue
            #endif
            
            intervalTime = 2
            level = 2
            
        case 2:
            self.fillColor = .white
            intervalTime = 2.25
            level = 3
        default:
            level = 0
            self.fillColor = .red
            intervalTime = 1
        }
        let grow = SKAction.scale(to: 1.1, duration: 0.2)
        self.run(SKAction.sequence([grow,SKAction.scale(to: 1/1.1, duration: 0.2)]))
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
            run(SKAction.scale(by: CGFloat(self.fireRadius) - 0.5, duration: 2))
            run(SKAction.sequence([SKAction.fadeOut(withDuration: 3),
                                   SKAction.removeFromParent()]))
        } else {
            run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.2),
                                   SKAction.removeFromParent()]))
            
            
        }
        
    }
    
    func targetTiles(scene:GameScene)->Set<MapPoint>{
        guard nextLaunch < Date(timeIntervalSinceNow: 0) else { return []}
        
        guard  let towerTile = scene.tileOf(node: self) else {
            return []
        }
        
        let boatScapes:Set<Landscape> = [.water,.path]
        return scene.mapTiles.tiles(near:towerTile,radius:fireRadius,kinds:boatScapes)
        
    }
    
    func hit(scene:GameScene){
        
        hitsRemain -= 1
        
        if hitsRemain == 0 {
            guard   let towerTile  = scene.tileOf(node: self),
                let dest = scene.mapTiles.endIsle?.harbor,
                let source =  scene.mapTiles.startIsle?.harbor  else
            { return }
            
            let towerScapes:Set<Landscape> = [.sand]
            
            let checkset = scene.mapTiles.tiles(near:towerTile,radius:fireRadius,kinds:towerScapes)
            
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
        guard nextLaunch < Date(timeIntervalSinceNow: 0) else { return }
        
        if  let dest =  scene.convert(mappoint: at){
            if let place = scene.tileOf(node: self) {
                print("firing from \(place) to \(at) which is \(dest)")
            }
            let _ = TowerMissle(tower: self, dest: dest, speed: missleSpeed)
            nextLaunch = Date(timeIntervalSinceNow: intervalTime)
            return
        }
    }
    
    
    
}

