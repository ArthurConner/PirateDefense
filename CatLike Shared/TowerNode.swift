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
    
    var watchTiles:Set<MapPoint> = []
    var intervalTime:TimeInterval = 1
    var nextLaunch:Date = Date.distantPast
    
    var expireTime:Date = Date(timeIntervalSinceNow: 15)
    var expireInterval:TimeInterval = 5
    
    var missleSpeed:Double = 0.2
    var level = 0
    var hitsRemain = 10
    
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
    
    func checkFire(targets:Set<MapPoint>,converter:(_ mappoint:MapPoint)->CGPoint?) -> MapPoint?{
        for target in targets {
            if self.watchTiles.contains(target) , let dest = converter(target){
                guard nextLaunch < Date(timeIntervalSinceNow: 0) else { return target }
                let _ = TowerMissle(tower: self, dest: dest, speed: missleSpeed)
                nextLaunch = Date(timeIntervalSinceNow: intervalTime)
                return target
            }
        }
        
        return nil
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
    
    func die() {
        // 1
        removeAllActions()
        
       
        // 2
        physicsBody = nil
        // 3
        run(SKAction.sequence([SKAction.fadeOut(withDuration: 3),
                               SKAction.removeFromParent()]))
    }
    
}

