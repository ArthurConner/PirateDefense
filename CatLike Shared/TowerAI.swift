//
//  TowerAI.swift
//  CatLike iOS
//
//  Created by Arthur  on 9/27/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import Foundation


class TowerAI {
    
    let clock = PirateClock(0.5)
    let towerAdd = PirateClock(3)
    
    
    
    func update(scene:GameScene){
        
        
        guard clock.needsUpdate() && towerAdd.needsUpdate() else { return }
        
        defer {
            clock.update()
        }
       
        
        guard scene.towerLocations.count < scene.maxTowers ,
            let source =  scene.mapTiles.startIsle?.harbor  else { return }
        
        let route = scene.mapTiles.mainRoute()
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
        
        for (loc, tower) in scene.towerLocations{
            
            possibleAddSpot.remove(loc)
            
            
            for x in scene.mapTiles.tiles(near: loc, radius: 4 - tower.level, kinds: sands){
                possibleAddSpot.remove(x)
            }
            
            
        }
        
        guard var bestTile = possibleAddSpot.first else { return }
        
        var bestVal = bestTile.distance(manhattan: source)
        
        for x in possibleAddSpot {
            let c = x.distance(manhattan: source)
            if c > bestVal {
               bestTile = x
                bestVal = c
            }
        }
        
        
        if let p = scene.convert(mappoint: bestTile) {
            scene.manageTower(point: p)
        }
        
        towerAdd.update()
        
        
      
        
    }
    
    
}
