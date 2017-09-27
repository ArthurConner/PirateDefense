//
//  Types.swift
//  CatLike
//
//  Created by Arthur  on 9/25/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import Foundation

struct PhysicsCategory {
    static let None:      UInt32 = 0
    static let All:       UInt32 = 0xFFFFFFFF
    static let EndPoint:      UInt32 = 0b1
    static let Tower:    UInt32 = 0b10
    static let Ship:       UInt32 = 0b100
    static let Missle:   UInt32 = 0b1000
    static let CannonBall: UInt32 = 0b10000
}

enum GameState: Int {
    case initial=0, start, play, win, lose, reload, pause
}

protocol Fireable {
    
    func die(scene:GameScene, isKill:Bool)
    func targetTiles(scene:GameScene)->Set<MapPoint>
    func hit(scene:GameScene)
    func fire(at:MapPoint,scene:GameScene)
  
}
