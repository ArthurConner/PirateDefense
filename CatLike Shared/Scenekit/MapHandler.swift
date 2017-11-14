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


enum Landscape : Int, Codable {
    
    
    
    case unknown
    case pirateBase
    case inland
    case path
    case water
    case top
    case homeBase
    case sand
}

let waterSet:Set<Landscape> = [.water,.path]
let routeSet:Set<Landscape> = [.water,.path,.pirateBase,.homeBase]

fileprivate func nameOf(landscape:Landscape)->String{
    switch landscape {
    case .unknown:
        return "unknown"
    case .pirateBase:
        return "dest"
    case .inland:
        return "inland"
    case .path:
        return "path"
    case .water:
        return "water"
    case .top:
        return "top"
    case .homeBase:
        return "tower"
    case .sand:
        return "sand"
    }
}

fileprivate func landscapeOf(name:String)->Landscape{
    switch name.lowercased() {
        
    case "dest":
        return .pirateBase
    case "inland":
        return .inland
    case "path":
        return .path
    case "water":
        return .water
    case "top":
        return .top
    case "tower":
        return .homeBase
    case "sand":
        return .sand
    default:
        return .unknown
    }
}

fileprivate class Island {
    
    weak var map:MapHandler?
    var terain:[Landscape:Set<MapPoint>] = [:]
    var harbor:MapPoint?
    
    static let islandKinds:[Landscape] = [.sand, .inland, .top, .pirateBase, .homeBase ]
    
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
        let checkSet:Set<Landscape> =  [.sand, .inland, .top, .pirateBase, .homeBase ]
        
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
    var mapAdj = 24
    fileprivate var islands:[Island] = []
    fileprivate var startIslands:[Island] = []
    fileprivate var endIsle:Island?
    
    var deltas = GameInfo()
    var voyages:[Voyage] = []
    
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
    
    fileprivate func createHarbors(){
        startIslands.removeAll()
        
        class WaterFront {
            var haborPoint:MapPoint
            var isle:Island
            var coast:Set<MapPoint>
            
            init?(_ land:Island,_ map:MapHandler){
                self.isle = land
                guard let sandTerain =  land.terain[.sand] else { return nil }
                coast = sandTerain

                let foo = coast
                for x in foo {
                    let list = x.adj(max: 20).filter({ waterSet.contains(map.kind(point: $0))})
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
                
                var bestVal = haborPoint.path(to: other, map: map, using: waterSet).count
                
                for x in self.coast {
                    
                    let checkVal = x.path(to: other, map: map, using: waterSet).count
                    
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
                var harbors = self.isle.terain[.pirateBase] ?? []
                harbors.insert(haborPoint)
                self.isle.terain[.pirateBase] = harbors
                self.isle.harbor = haborPoint
                map.changeTile(at: haborPoint, to: .pirateBase)
                
                
            }
            
        }
        
        
        let dIsle = islands[0]
        guard  let destWaterfront = WaterFront(dIsle,self) else {
            return
        }
        
        self.endIsle = dIsle
        
        startIslands.removeAll()
        var sWaters:[WaterFront] = []
        //islands.count
        for i in 1..<2 {
            let x = islands[i]
            if let h = WaterFront(x,self) {
                startIslands.append(x)
                sWaters.append(h)
            }
        }
        //let sWaters = islands.dropFirst().flatMap({WaterFront($0,self)})
        
        guard !sWaters.isEmpty else { return }
        for _ in 0..<3{
            for startWaterFront in sWaters {
                startWaterFront.makeMaxPoint(other: destWaterfront.haborPoint, map: self)
                destWaterfront.makeMaxPoint(other: startWaterFront.haborPoint, map: self)
                
            }
            
            
        }
        
        for startWaterFront in sWaters {
            startWaterFront.updateIsland(map: self)
            
        }
        
        destWaterfront.updateIsland(map: self)

    }
    
    func refreshMap(){
        guard let map = tiles else { return }
        self.islands.removeAll()
        self.voyages.removeAll()
        
        let iLimit = 2 +  GKRandomSource.sharedRandom().nextInt(upperBound: 5)
        
        while self.islands.count < iLimit {
            
            self.islands.removeAll()
        
            for r in 0..<map.numberOfRows{
                for c in 0..<map.numberOfColumns{
                    let p = MapPoint(row:r,col:c)
                    changeTile(at:p, to: .water)
                }
            }
            
            
            var startIslands:[Island] = []
            for _ in 0..<iLimit + 2 {
                
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
        
        guard !startIslands.isEmpty, let d = self.endIsle?.harbor else {
            refreshMap()
            return
        }
        
        self.voyages.removeAll()
        for startIsle in startIslands {
            if  let s = startIsle.harbor {
                let v = Voyage(start: s, finish: d)
                self.voyages.append(v)

            }
            
        }
        
        guard !voyages.isEmpty else {
            refreshMap()
            return
        }
        
        for x in self.voyages {
            if x.shortestRoute(map: self, using: waterSet).count > 4 {
                self.changeTile(at: x.start, to: .homeBase)
            } else {
                refreshMap()
                return
            }
        }
        
        
    }
    
    
    func randomRoute()->Voyage?{
        guard !voyages.isEmpty else { return nil}
        return voyages[GKRandomSource.sharedRandom().nextInt(upperBound: voyages.count)]
        
    }
    
    
    func load(map nextM: SKTileMapNode?) {
        
        guard tiles == nil else {
            print("already have a map")
            return
        }
        tiles = nextM
        
        if let t = nextM {
            mapAdj = t.numberOfRows
        }
        refreshMap()

    }
    
    

    
    func map(coordinate:CGPoint)->MapPoint?{
        guard let tiles =   tiles  else {
            
            return nil
        }
        
        let y = tiles.tileColumnIndex( fromPosition: coordinate)
        let x = tiles.tileRowIndex( fromPosition: coordinate)
        
       // guard x >= 0, y >= 0 else  { return nil }
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
        self.deltas.tileDelta[at] = to
    }
    
    
}

extension MapHandler {
    
    func convert(mappoint:MapPoint)->CGPoint? {
        guard let background = self.tiles, let sup = background.parent as? SKScene else {return nil }
        let tileCenter  = background.centerOfTile(atColumn:mappoint.col,row:mappoint.row)
        return sup.convert(tileCenter, from: background)
    }
    
    func pathOf(mappoints route:[MapPoint], startOveride:CGPoint? = nil)->CGPath?{
        
        guard let f1 = route.first, var p1 = convert(mappoint:f1) else { return nil}
        
        let path = CGMutablePath()
        p1 = startOveride ?? p1
       // if  p1 != startOveride {
        path.move(to: p1)
       // }
        
        if p1 != startOveride {
            print("oops")
        }
        
        var lastP = p1
        
        
        for (i, hex) in route.enumerated() {
            
            
            if let p = convert(mappoint:hex){
                if i > 0 {
                    
                    for dist:CGFloat in [0.25,0.5,1]{
                        let rev = 1 - dist
                        let nextp = CGPoint(x:(rev * lastP.x)+(dist * p.x), y:(rev * lastP.y)+(dist * p.y))
                    
                    
                    path.addLine(to:nextp)
                    }
                    lastP = p
                }
                
            }
        }
        
        return path
    }
}
