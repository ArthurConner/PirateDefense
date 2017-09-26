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
        
        self.init(circleOfRadius:4)
        self.fillColor = .red
        
        self.position = tower.position
        
        
        guard let p = tower.parent else {return}
        p.addChild(self)
        
        
        let body = SKPhysicsBody(circleOfRadius: 20)
        
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
    var intervalTime:TimeInterval = 4
    var nextLaunch:Date = Date.distantPast
    var missleSpeed:Double = 0.2
    var level = 0
    
    convenience init(range:CGFloat) {
        
        self.init(circleOfRadius:20)
        self.fillColor = .purple
        
  
    }
    
    func checkFire(targets:Set<MapPoint>,converter:(_ mappoint:MapPoint)->CGPoint?){
        
        guard nextLaunch < Date(timeIntervalSinceNow: 0) else { return }
        
        for target in targets {
            if self.watchTiles.contains(target) , let dest = converter(target){
                let _ = TowerMissle(tower: self, dest: dest, speed: missleSpeed)
                nextLaunch = Date(timeIntervalSinceNow: intervalTime)
                return
            }
        }
    }
    
    func upgrade(){
        switch level {
        case 0:
            self.fillColor = .red
            intervalTime = 3
            level = 1
        case 1:
            self.fillColor = .orange
            intervalTime = 2
            level = 2
        case 2:
            self.fillColor = .white
            intervalTime = 1
        default:
            level = 2
        }
    }
    
    
    
}

