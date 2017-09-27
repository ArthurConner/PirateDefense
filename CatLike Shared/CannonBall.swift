//
//  CannonBall.swift
//  CatLike iOS
//
//  Created by Arthur  on 9/27/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import Foundation
import GameKit

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
