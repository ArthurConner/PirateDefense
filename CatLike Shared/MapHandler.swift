//
//  MapHandler.swift
//  CatLike
//
//  Created by Arthur  on 9/21/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import Foundation
import SpriteKit
import GameplayKit


enum Landscape {
    case unknown
    case dest
    case inland
    case path
    case water
    case top
    case tower
    case sand
}

fileprivate func nameOf(landscape:Landscape)->String{
    switch landscape {
    case .unknown:
        return "unknown"
    case .dest:
        return "dest"
    case .inland:
        return "inland"
    case .path:
        return "path"
    case .water:
        return "water"
    case .top:
        return "top"
    case .tower:
        return "tower"
    case .sand:
        return "sand"
    }
}

fileprivate func landscapeOf(name:String)->Landscape{
    switch name.lowercased() {
        
    case "dest":
        return .dest
    case "inland":
        return .inland
    case "path":
        return .path
    case "water":
        return .water
    case "top":
        return .top
    case "tower":
        return .tower
    case "sand":
        return .sand
    default:
        return .unknown
    }
}



struct MapPoint{
    let row: Int
    let col: Int
    
    static let offGrid = MapPoint(row: -2, col: -2)
    
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
    
    
}

class Island {
    
    weak var map:MapHandler?
    var terain:[Landscape:Set<MapPoint>] = [:]
    var harbor:MapPoint?
    
    static let islandKinds:[Landscape] = [.sand, .inland, .top, .dest, .tower ]
    
    init(map nMap:MapHandler) {
        self.map = nMap
        
        for ter in Island.islandKinds {
            terain[ter] = Set<MapPoint>()
        }
        
    }
    
    func addPoint(point:MapPoint){
        
        guard let map = map else { return }
        guard var  addSet = self.terain[.top] else { return }
        defer {
            self.terain[.top] = addSet
        }
        
        if addSet.contains(point){
            addSet.remove(point)
        }
        
        func createLand(at:MapPoint, _ confidence:Float, decay:Float){
            guard !addSet.contains(at) else { return }
            guard confidence > GKRandomSource.sharedRandom().nextUniform() else {
                return
            }
            
            map.changeTile(at: at, to: .top)
            addSet.insert(at)
            for p in at.adj(max: map.mapAdj - 2) {
                if p.row > 2 && p.col > 2 {
                    createLand(at: p, confidence * decay, decay: decay)
                }
            }
        }
        
        createLand(at: point, 1, decay: 0.8)
        
    }
    
    func contains(point:MapPoint)->Bool{
        for (_,v) in terain {
            if v.contains(point) {
                return true
            }
        }
        
        return false
    }
    
    
    func peak()->MapPoint?{
        
        guard let tops = self.terain[.top] else {return nil}
        return tops.first
    }
    
    func merge(){
        guard let map = map else { return }
        guard var tops = self.terain[.top],
            let mapP = self.peak() else { return }
        defer {
            self.terain[.top] = tops
        }
        
        
        var visted:Set<MapPoint> = []
        let checkSet:Set<Landscape> =  [.sand, .inland, .top, .dest, .tower ]
        
        func checkPoint(point:MapPoint){
            
            guard !visted.contains(point) else {return}
            visted.insert(point)
            
            guard checkSet.contains(map.kind(point:point)) else { return }
            
            tops.insert(point)
            
            for y in point.adj(max: map.mapAdj) {
                checkPoint(point: y)
            }
            
        }
    }
    
    func terraform(){
        
        guard let map = map else { return }
        
        guard var tops = self.terain[.top],
            var sands = self.terain[.sand],
            var inL = self.terain[.inland],
            let mapP =  peak() else { return }
        
        defer {
            self.terain[.top] = tops
            self.terain[.sand] = sands
            self.terain[.inland] = inL
        }
        
        
        let coast = map.boundaries(point: mapP)
        for x in coast {
            if x != mapP {
                
                map.changeTile(at: x, to: .sand)
                tops.remove(x)
                sands.insert(x)
            }
        }
        
        let base = tops
        for x in base {
            
            for y in x.adj(max: map.mapAdj){
                
                if  sands.contains(y) {
                    map.changeTile(at: x, to: .inland)
                    tops.remove(x)
                    inL.insert(x)
                }
                
            }
            
        }

    }
    
}

class MapHandler{
    
    var tiles : SKTileMapNode?
    let tileSet = SKTileSet(named: "PlunderSet")
    let mapAdj = 24
    var islands:[Island] = []
    var startIsle:Island?
    var endIsle:Island?
    
    func kind(point:MapPoint)->Landscape{
        guard let tiles = tiles ,
            let de = tiles.tileDefinition(atColumn: point.col, row: point.row),
            let name = de.name else {return .unknown}
        
        return landscapeOf(name:name)
    }
    
    func tiles(near place:MapPoint,radius:Int,kinds:Set<Landscape>)->Set<MapPoint>{
        var ret:Set<MapPoint> = []
        var visited:Set<MapPoint> = []
        var toAdd:Set<MapPoint> = [place]
        
        for _ in 0..<radius {
            var nextSet:Set<MapPoint> = []
            for x in toAdd {
                visited.insert(x)
                let c = kind(point: x)
                if kinds.contains(c){
                   ret.insert(x)
                }
                for y in x.adj(max: self.mapAdj){
                    if !visited.contains(y){
                        nextSet.insert(y)
                    }
                }
            }
            toAdd = nextSet
        }
        
        return ret
    }
    
    func isBoundary(point:MapPoint)->Bool{
        let x = kind(point: point)
        for y in point.adj(max: mapAdj) {
            if kind(point: y) != x {
                return true
            }
        }
        return false
    }
    
    func boundaries(point:MapPoint) ->[MapPoint]{
        
        let x = kind(point: point)
        
        var visted:Set<MapPoint> = []
        var ret:[MapPoint] = []
        
        func checkPoint(point:MapPoint){
            
            guard !visted.contains(point) else {return}
            visted.insert(point)
            
            guard kind(point:point) == x else { return }
            
            
            if isBoundary(point: point){
                ret.append(point)
            }
            
            for y in point.adj(max: mapAdj) {
                checkPoint(point: y)
            }
            
        }
        
        checkPoint(point: point)
        return ret
        
    }

    func createHarbors(){
        
        class WaterFront {
            var haborPoint:MapPoint
            var isle:Island
            var coast:Set<MapPoint>
            
            let wSet:Set<Landscape> = [.water,.path]
            
            init?(_ land:Island,_ map:MapHandler){
                self.isle = land
                guard let sandTerain =  land.terain[.sand] else { return nil }
                coast = sandTerain
                
                let wSet:Set<Landscape> = [.water,.path]
                
                let foo = coast
                for x in foo {
                    
                    let list = x.adj(max: 20).filter({ wSet.contains(map.kind(point: $0))})
                    if list.isEmpty {
                        coast.remove(x)
                    }
                    
                }
                
                if let hp = coast.first {
                    self.haborPoint = hp
                } else {
                    return nil
                }
                
            }
            
            func makeMaxPoint(other:MapPoint,map:MapHandler){
                
                var bestVal = haborPoint.path(to: other, map: map, using: wSet).count
                
                for x in self.coast {
                    
                    let checkVal = x.path(to: other, map: map, using: wSet).count
                    
                    if checkVal > bestVal {
                        bestVal = checkVal
                        haborPoint = x
                    }
                }
            }
            
            func updateIsland(map:MapHandler){
                
                var sands = self.isle.terain[.sand] ?? []
                
                sands.remove(haborPoint)
                self.isle.terain[.sand] = sands
                var harbors = self.isle.terain[.dest] ?? []
                harbors.insert(haborPoint)
                self.isle.terain[.dest] = harbors
                self.isle.harbor = haborPoint
                map.changeTile(at: haborPoint, to: .dest)
                
                
            }
            
        }
        
        
        let sIsle = islands[0]
        self.startIsle = sIsle
        
        let dIsle = islands[1]
        self.endIsle = dIsle
        
        
        guard let start =  WaterFront(sIsle,self),
            let dest =  WaterFront(dIsle,self) else { return
        }
        
      
        for _ in 0..<3 {
            start.makeMaxPoint(other: dest.haborPoint, map: self)
            dest.makeMaxPoint(other: start.haborPoint, map: self)
        }
        
        
        start.updateIsland(map: self)
        dest.updateIsland(map: self)
 
        
    }
    
    func refreshMap(){
        guard let map = tiles else { return }
        self.islands.removeAll()
        
        
        while self.islands.count < 3 {
            
            self.islands.removeAll()
            
            for r in 0..<map.numberOfRows{
                for c in 0..<map.numberOfColumns{
                    changeTile(at: MapPoint(row:r,col:c), to: .water)
                }
            }
            
            for c in 0..<map.numberOfColumns {
                 changeTile(at: MapPoint(row:0,col:c), to: .top)
                changeTile(at: MapPoint(row:map.numberOfRows-1,col:c), to: .top)
            }
            var startIslands:[Island] = []
            for _ in 0..<4 {
                
                let isle = Island(map: self)
                
                startIslands.append(isle)
                isle.addPoint(point:  MapPoint(
                    row:GKRandomSource.sharedRandom().nextInt(upperBound:mapAdj-4) + 2,
                    col:GKRandomSource.sharedRandom().nextInt(upperBound:mapAdj - 4 ) + 2))
            }
            
            
            
            for addIdle in startIslands{
                addIdle.merge()
                
                if let peak = addIdle.peak() {
                    
                    var didCreateIsand = false
                    for isle in islands {
                        if isle.contains(point: peak) {
                            didCreateIsand = true
                        }
                    }
                    
                    if (!didCreateIsand){
                        islands.append(addIdle)
                    }
                    
                }
            }
            
            for isle in islands{
                isle.terraform()
            }
            
        }
        
        self.createHarbors()
        
         let wSet:Set<Landscape> = [.water,.path]
        
        if let s = self.startIsle?.harbor,
            let d = self.endIsle?.harbor,  s.path(to:d,map:self, using:wSet).count > 4 {
            
         self.changeTile(at: s, to: .tower)
            
        } else {
            refreshMap()
        }
    }
    
    
    func load(map nextM: SKTileMapNode?) {
        
        guard tiles == nil else {
            print("already have a map")
            return
        }
        tiles = nextM
        refreshMap()
        
    }
    
    func map(coordinate:CGPoint)->MapPoint?{
        guard let tiles =   tiles  else {
            
            return nil
        }
        let y = tiles.tileColumnIndex( fromPosition: coordinate)
        let x = tiles.tileRowIndex( fromPosition: coordinate)
        return MapPoint(row: x, col: y)
        
    }
    
    func changeTile(at:MapPoint, to:Landscape){
        
        let name = nameOf(landscape: to)
        
        guard let tiles = tiles  else {
            return
        }

        guard  let waterTile = tileSet?.tileGroups.first(where: {$0.name == name}) else {
            fatalError("No \(name) tile definition found")
        }
        
        tiles.setTileGroup(waterTile, forColumn: at.col, row: at.row)
    }
    
}
