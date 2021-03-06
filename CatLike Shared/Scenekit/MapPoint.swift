//
//  MapPoint.swift
//  CatLike iOS
//
//  Created by Arthur  on 10/4/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import Foundation


struct MapPoint:Codable{
    let row: Int
    let col: Int
    
    static let offGrid = MapPoint(row: -2, col: -2)
    
    init(row:Int,col:Int) {
        self.row = row
        self.col = col
    }
    
    func adj(max:Int)->[MapPoint]{
        var ret:[MapPoint] = []
        let vals:[(Int,Int)]
        
        if  self.row % 2 == 1 {
            vals  = [(0,-1),(1,0),(1,1),(0,1),(-1,1),(-1,0)]
            
        } else {
            vals  = [(0,-1),(1,-1),(1,0),(0,1),(-1,0),(-1,-1)]
        }
        for c in vals {
            let arow = row + c.0
            let acol = col + c.1
            
            if (arow >= 0) && (arow < max) && (acol >= 0) && (acol < max) {
                ret.append(MapPoint(row: arow, col: acol))
            }
        }
        
        return ret
    }
    
    func distance(manhattan:MapPoint)->Int{
        return abs(self.row - manhattan.row) + abs(self.col - manhattan.col)
    }
    
    func path(to dest:MapPoint,map:MapHandler, using:Set<Landscape>)->[MapPoint]{
        
        var visited:[MapPoint:MapPoint] = [self:self]
        var nextLevel = [self]
        
        while !nextLevel.isEmpty{
            var addMe:Set<MapPoint> = []
            for x in nextLevel {
                for ad in x.adj(max: map.mapAdj){
                    if visited[ad] == nil {
                        visited[ad] = x
                        if ad == dest {
                            var ret = [dest]
                            var current = x
                            while current != self {
                                ret.append(current)
                                current = visited[current] ?? x
                            }
                            ret.append(self)
                            return ret.reversed()
                        }
                        // if
                        if using.contains(map.kind(point: ad)){
                            addMe.insert(ad)
                        }
                        
                    } else {
                        // print("No")
                    }
                }
            }
            
            nextLevel = Array(addMe)
        }
        return []
        
    }
    
    
    fileprivate func _minpath(to dest:MapPoint,map:MapHandler, using:Set<Landscape>, existing eAtLevel:[Set<MapPoint>], count:Int)->[MapPoint]{
        
        var visited:[MapPoint:MapPoint] = [self:self]
        var nextLevel = [self]
        var counter = 0
        
        var pathNo = 0
        while !nextLevel.isEmpty{
            let existing:Set<MapPoint>
            if pathNo < eAtLevel.count {
                existing =  eAtLevel[pathNo]
            pathNo += 1
            } else {
                existing = []
            }
            
            var addMe:Set<MapPoint> = []
            for x in nextLevel {
                for ad in x.adj(max: map.mapAdj){
                    if visited[ad] == nil {
                        visited[ad] = x
                        if ad == dest {
                            var ret = [dest]
                            var current = x
                            while current != self {
                                ret.append(current)
                                current = visited[current] ?? x
                            }
                            ret.append(self)
                            return ret.reversed()
                        }
                        // if
                        if using.contains(map.kind(point: ad)){
                            
                            if existing.contains(ad) {
                                counter += 1
                                if counter < count {
                                    addMe.insert(ad)
                                }
                            } else {
                                addMe.insert(ad)
                            }
                        }
                        
                    } else {
                        // print("No")
                    }
                }
            }
            
            nextLevel = Array(addMe)
        }
        return []
        
    }
    
    /*
 if using.contains(map.kind(point: ad)){
 if existing.contains(ad) {
 counter += 1
 
 if counter < count {
 addMe.insert(ad)
 }
 } else {
 addMe.insert(ad)
 }
 }
 */
    func minpath(to dest:MapPoint,map:MapHandler, using:Set<Landscape>, existing:[Set<MapPoint>])->[MapPoint]{
        
        var nextMin = 0
        while nextMin < existing.count{
            
            let p = _minpath(to: dest, map: map, using: using, existing: existing, count: nextMin)
            if !p.isEmpty {
                return p
            }
            nextMin = (nextMin + 1) * 4 / 3
        }
        
        return path(to: dest, map: map, using: using)
        
    }
    
}

extension MapPoint:Equatable{
    public static func ==(lhs: MapPoint, rhs: MapPoint) -> Bool{
        return (lhs.row == rhs.row) && (lhs.col == rhs.col)
    }
    
}

extension MapPoint:Hashable {
    var hashValue: Int {
        return row.hashValue ^ col.hashValue &* 16777619
        
    }
}


struct Voyage:Codable {
    let start:MapPoint
    let finish:MapPoint
    
    func shortestRoute(map:MapHandler, using:Set<Landscape>)->[MapPoint]{
        return start.path(to:finish, map: map, using: using)
    }
    
    static func offGrid()->Voyage{
        return Voyage(start:MapPoint.offGrid,finish:MapPoint.offGrid)
    }
    
}

extension Voyage:Equatable{
    public static func ==(lhs: Voyage, rhs: Voyage) -> Bool{
        return (lhs.start == rhs.start) && (lhs.finish == rhs.finish)
    }
    
}

extension Voyage:Hashable {
    var hashValue: Int {
        return start.hashValue ^ finish.hashValue &* 16777619
    }
}
