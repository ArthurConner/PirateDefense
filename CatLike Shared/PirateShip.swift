//
//  PirateShip.swift
//  CatLike
//
//  Created by Arthur  on 9/25/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import Foundation
import GameKit


class CannonBall:SKShapeNode {
    
    
    
    convenience init(tower:PirateNode,dest:CGPoint,speed:Double) {
        
        self.init(circleOfRadius:8)
        self.fillColor = .black
        
        self.position = tower.position
        
        
        guard let p = tower.parent else {return}
        p.addChild(self)
        
        
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
    
    convenience init(named:String) {
        
        self.init(ellipseOf:CGSize(width: 20, height: 45))
        self.fillColor = .brown
        
        
        let body = SKPhysicsBody(circleOfRadius: 20)
        
        body.allowsRotation = false
        
        body.categoryBitMask = PhysicsCategory.Ship
        
        
        //  body.collisionBitMask = PhysicsCategory.All
        body.contactTestBitMask = PhysicsCategory.Missle
        
        body.restitution = 0.5
        self.physicsBody = body
        
    }
    
    func die() {
        // 1
        removeAllActions()
        
        yScale = -1
        // 2
        physicsBody = nil
        // 3
        run(SKAction.sequence([SKAction.fadeOut(withDuration: 3),
                               SKAction.removeFromParent()]))
    }
    
    
    
    func spawnWake() {
        
        guard let p = self.parent else {return}
        
        let sand = SKSpriteNode(imageNamed: "Path")
        
        sand.position = self.position
        
        sand.size = CGSize(width: 5, height: 5)
        let angle = CGFloat.pi * CGFloat(GKRandomSource.sharedRandom().nextUniform() - 0.5)
        sand.run(SKAction.sequence([SKAction.rotate(byAngle: angle, duration: 0.2),
                                    SKAction.scale(to: 10, duration: 4)]))
        
        sand.run(SKAction.sequence([SKAction.fadeOut(withDuration: 7),
                                    SKAction.removeFromParent()]))
        
        // self.addChild(sand)
        /*
         for (i, x) in p.children.enumerated(){
         
         if x == self {
         p.insertChild(sand, at: 0)
         return
         }
         
         }
         */
        p.insertChild(sand, at: p.children.count - 1)
        //p.addChild(sand)
        
    }
    
    func fire(target:MapPoint,converter:(_ mappoint:MapPoint)->CGPoint?){
        
        guard nextLaunch < Date(timeIntervalSinceNow: 0) else { return }
        
        
        if  let dest = converter(target){
            let _ = CannonBall(tower: self, dest: dest, speed: missleSpeed)
            nextLaunch = Date(timeIntervalSinceNow: intervalTime)
            return
        }
    }
}



