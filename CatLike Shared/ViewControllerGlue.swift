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
    case editor
    case ship
}

protocol GameTypeModeDelegate {
    func didSet(game:GameTypeModes)
}


enum TowerPlayerActions:String {
    case launchPaver = "Launch SandShip"
    case launchTerra = "Launch Terra"
    case KillAllTowers = "Kill All Towers"
    case fasterBoats = "Faster Boats"
    case strongerBoats = "Stronger Boats"
    case showNextShip = "Show Next Ship"
    case sound = "Toggle Sound"
    case path = "Toggle Path"
    case save = "Save"
    case exit = "Exit"
    
}


protocol TowerPlayerActionDelegate {
    func didTower(action:TowerPlayerActions)
}

