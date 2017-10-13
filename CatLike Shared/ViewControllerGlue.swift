//
//  ViewControllerGlue.swift
//  CatLike
//
//  Created by Arthur  on 10/13/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import Foundation


enum GameTypeModes {
    case unknown
    case tower
    case ship
}

protocol GameTypeModeDelegate {
    func didSet(game:GameTypeModes)
}


enum TowerPlayerActions:String {
    case launchPaver = "Launch SandShip"
    case KillAllTowers = "Kill All Towers"
    
}


protocol TowerPlayerActionDelegate {
    func didTower(action:TowerPlayerActions)
}

