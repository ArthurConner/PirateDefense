//
//  GameLevel.swift
//  CatLike iOS
//
//  Created by Arthur  on 11/14/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import Foundation


fileprivate struct ShipLaunch : Codable {
    let interval:TimeInterval
    let kind:ShipKind
    let modfier:Double
    let route:Voyage
    let level:Int

    let radius:Int?
    
    init( ship:PirateNode,time:TimeInterval){
        interval = time
       
        kind = ship.kind
        level = ship.startLevel
        modfier = ship.startModfier
        route = ship.route
     
        if let n = ship as? BomberNode {
            radius = n.blastRadius
        } else {
            radius = nil
        }

    }
    
    func ship()->PirateNode{
        let x = PirateNode.makeShip(kind: kind, modfier: modfier, route: route, level: level)
        if let n = x as? BomberNode, let r = radius {
            n.blastRadius = r
        }
        return x
    }
    
    
    
}

class GameLevel : Codable {
    
    let defaultFloor = 0.7
    let maxTowers = 9
    let playSound = true
    
    fileprivate var launches:[ShipLaunch] = []

    var points:Int = 0
    var victorySpeed:Double = 1
    var boatLevel = 0
    var victoryShipLevel = 3
    var isRecording = true
    var info = GameInfo()
    var startTime = Date()
    
    
    func clear(){
        points = 0
        victoryShipLevel = 3
        victorySpeed  = 1
        boatLevel = 0
        victoryShipLevel = 3
        startTime = Date()
    }
    
    func add(ship:PirateNode, at:TimeInterval){
        guard  isRecording else { return }
        launches.append(ShipLaunch(ship: ship, time: at))
    }
    
    func clearShips(){
        launches.removeAll()
    }
    
    func victoryShipStartingLevel()->Int{
        return victoryShipLevel + points/10
    }
    
    func towerStartingLevel()->Int{
        return 4 + points/10
    }
    
    func write(name:String){
        let path = "/Users/arthurc/code/catsaves/\(name)"
          do {
            let coder = JSONEncoder()
            coder.outputFormatting = .prettyPrinted
            
            let data = try coder.encode(self)
            
            try data.write(to: URL(fileURLWithPath: path))
         
            
        } catch let error {
            ErrorHandler.handle(.networkIssue, "Unable to send message \(error)")
        }
    }
    
    func read(){
        
        //"/Users/arthurc/code/catsaves/game_Nov14,2017at3_16_01PM.txt"

    }
    
    func adjustPoints(kind:ShipKind){
        switch kind {
        case .battle:
            points += 6
        case .crusier:
            points += 1
        case .destroyer:
            points += 5
        case .galley:
            points += 2
        case .motor:
            points += 3
        case .row:
            points += 0
        case .bomber:
            points += 5
            
            
        }
    }
    
    
}
