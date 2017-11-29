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
    var route:[MapPoint] = []
}
extension Navigatable {
    
    func wakeAction()->SKAction {
        let wake = self.spawnWake
        return  SKAction.repeatForever(SKAction.sequence([SKAction.run(wake),SKAction.wait(forDuration: self.waterSpeed/3)]))
    }
    
    func sailAction(usingTiles tiles:MapHandler, orient:Bool=true, existing:[Set<MapPoint>])->(SKAction?,ShipPath?) {
        
        let dest = self.route.finish
        
        var retPath:ShipPath? = nil
        
        guard let ship = self as? SKNode else {return (nil,retPath)}
        guard
            let source =  tiles.map(coordinate: ship.position) else { return (nil,retPath)}
        
        
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
            
                let line = ShipPath(path: path)
                line.route = route
                
                if let s = self as? PirateNode {
                    
                    line.strokeColor = ColorUtils.shared.alpha(s.wakeColor,  rate: 0.2)
                    line.lineWidth = CGFloat(s.hitsRemain)/4
                }
            
                if let f = self as? TowerNode {
                    
                    line.strokeColor = ColorUtils.shared.alpha(.purple,  rate: 0.2)
                    line.lineWidth = log2(CGFloat(f.hitsRemain)) + 1
                }
            
                line.lineWidth = ceil(max(min(line.lineWidth,2),9))
            
                retPath = line
            
            return (SKAction.follow( path, asOffset: false, orientToPath: orient, duration: time),line)
            
        }
        
        return (nil,retPath)
    }
}
