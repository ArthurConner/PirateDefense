//
//  Navigatable.swift
//  CatLike iOS
//
//  Created by Arthur  on 10/18/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import Foundation
import SpriteKit



protocol Navigatable {
    
    var waterSpeed:Double{get set}
    var route:Voyage {get set}
    func allowedTiles()->Set<Landscape>
    func spawnWake()
    
    
    
}


class ShipPath: SKShapeNode {
    
}
extension Navigatable {
    
    func wakeAction()->SKAction {
        let wake = self.spawnWake
        return  SKAction.repeatForever(SKAction.sequence([SKAction.run(wake),SKAction.wait(forDuration: self.waterSpeed/3)]))
    }
    
    func sailAction(usingTiles tiles:MapHandler, orient:Bool=true, existing:Set<MapPoint>)->SKAction? {
        
        let dest = self.route.finish
        
        guard let ship = self as? SKNode else {return nil}
        guard
            let source =  tiles.map(coordinate: ship.position) else { return nil}
        
        
        let route = source.minpath(to: dest, map: tiles, using: self.allowedTiles(), existing: existing)
        
        var lastPoint:MapPoint? = nil
        for x in route.reversed(){
            
            if let l = lastPoint {
                
                let neighbors = x.adj(max: tiles.mapAdj).filter({$0 == l})
                if neighbors.isEmpty {
                    print("we have a route that does not work forward \(x) \(l)")
                }
                
                let neigh = l.adj(max: tiles.mapAdj).filter({$0 == x})
                if neigh.isEmpty {
                    let list =  l.adj(max: tiles.mapAdj)
                    print("we have a route that does not work reverse \(x) \(l) \(list) ")
                }
            }
            
            lastPoint = x
        }
        
        if let path = tiles.pathOf(mappoints:route, startOveride:ship.position) {
            let time =  self.waterSpeed * Double(route.count)
            if let p = ship.parent {
                let line = ShipPath(path: path)
                line.lineWidth = 3
                line.strokeColor = NSColor(calibratedRed: 1, green: 0, blue: 0, alpha: 0.2)
                
                if let _ = self as? TowerNode {
                    line.strokeColor =  NSColor(calibratedRed: 0, green: 1, blue: 0, alpha: 0.5)
                }
                
                p.addChild(line)
            }
            return SKAction.follow( path, asOffset: false, orientToPath: orient, duration: time)
            
        }
        
        return nil
    }
}
