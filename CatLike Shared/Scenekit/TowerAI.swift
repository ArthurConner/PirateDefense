//
//  TowerAI.swift
//  CatLike iOS
//
//  Created by Arthur  on 9/27/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import Foundation
import GameKit

class TowerAI {
    
    let clock = PirateClock(0.5)
    let towerAdd = PirateClock(3)
    
    var radius:Int? = nil
    
    func update(scene:GameScene){
        
        
        guard clock.needsUpdate() && towerAdd.needsUpdate() else { return }
        
        defer {
            clock.update()
        }
        
        
        guard scene.towersRemaining() > 0 , let trip =  scene.mapTiles.randomRoute()  else { return }

        let route = trip.shortestRoute(map:scene.mapTiles, using:waterSet)
        guard route.count > 4 else { return }
        
        var possibleAddSpot:Set<MapPoint> = []
        
        for watertile in route {
            
            for x in watertile.adj(max: scene.mapTiles.mapAdj) {
                if scene.mapTiles.kind(point: x) == .sand {
                    possibleAddSpot.insert(x)
                }
            }
            
        }
        
        let sands:Set<Landscape> = [.sand]
        
        for loc in possibleAddSpot{
            
            
            if let tower = scene.tower(at: loc){
                possibleAddSpot.remove(loc)
                
                if tower.hitsRemain > 4, tower.level > 2 {
                    tower.adjust(level: -1)
                }
                let r = radius ?? 4 - tower.level
                for x in scene.mapTiles.tiles(near: loc, radius: r, kinds: sands){
                    possibleAddSpot.remove(x)
                }
                
            }
            
        }
        
        guard var bestTile = possibleAddSpot.first else { return }
        
        var bestVal = bestTile.distance(manhattan: trip.start)
        
        for x in possibleAddSpot {
            let c = x.distance(manhattan: trip.start)
            if c > bestVal {
                bestTile = x
                bestVal = c
            }
        }
        
        
        if let p = scene.mapTiles.convert(mappoint: bestTile) {
            scene.manageTapWhilePlaying(point: p)
        }
        
        towerAdd.update()
        
        
        
        
    }
    
    
}
