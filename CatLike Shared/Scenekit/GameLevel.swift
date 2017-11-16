//
//  GameLevel.swift
//  CatLike iOS
//
//  Created by Arthur  on 11/14/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import Foundation
import GameKit


fileprivate struct ShipLaunch : Codable {
    let interval:TimeInterval
    let kind:ShipKind
    let modfier:Double
    let routeIndex:Int
    let level:Int
    
    let radius:Int?
    
    
    init( ship:PirateNode,time:TimeInterval, index:Int){
        interval = time
        
        kind = ship.kind
        level = ship.startLevel
        modfier = ship.startModfier
        routeIndex = index
        
        if let n = ship as? BomberNode {
            radius = n.blastRadius
        } else {
            radius = nil
        }
        
    }
    
    func ship(route:Voyage)->PirateNode{
        let x = PirateNode.makeShip(kind: kind, modfier: modfier, route: route, level: level)
        if let n = x as? BomberNode, let r = radius {
            n.blastRadius = r
        }
        return x
    }
    
}

fileprivate struct MapHolder : Codable {
    
    let grid:[String]
    
    init(map tiles:MapHandler){
        var all:[String] = []
        
        if let  m = tiles.tiles {
            
            for r in 0..<m.numberOfRows{
                var currentRow:[Landscape] = []
                for c in 0..<m.numberOfColumns{
                    let p = MapPoint(row:r,col:c)
                    let k = tiles.kind(point: p)
                    currentRow.append(k)
                }
                
                let m = currentRow.map{ return MapHolder.nameOf(landscape:$0)}
                all.append(m.joined(separator: ","))
                
            }
        }
        self.init(grid:all)
    }
    
    func adjust(map:MapHandler){
        
        
        for (r, currentRow) in grid.enumerated() {
            let cols = currentRow.split(separator: ",")
            for (c, k) in cols.enumerated(){
                let p = MapPoint(row: r, col: c)
                let kind = MapHolder.landscapeOf(name: String(k))
                map.changeTile(at: p, to: kind)
            }
        }
        
    }
    
    init(grid ag:[String]){
        grid = ag
    }
    
    
    static func nameOf(landscape:Landscape)->String{
        switch landscape {
        case .unknown:
            return "u"
        case .pirateBase:
            return "p"
        case .inland:
            return "^"
        case .path:
            return "-"
        case .water:
            return "~"
        case .top:
            return "@"
        case .homeBase:
            return "*"
        case .sand:
            return " "
        }
    }
    
    static func landscapeOf(name:String)->Landscape{
        switch name.lowercased() {
            
        case "u" :
            return .unknown
        case  "p" :
            return .pirateBase
        case "^" :
            return .inland
        case "-":
            return .path
        case "~" :
            return .water
        case "@" :
            return .top
        case "*" :
            return .homeBase
        case " " :
            return .sand
        default:
            return .unknown
            
        }
    }
    
}

struct ShipProbality : Codable {
    let base:Double
    let slope:Double
    let final:Double
    
    func percentage(at:TimeInterval)->Double{
        return  min(max((base + slope * at)/5 , 0 ),final)
    }
    
}

class GameLevel : Codable {
    
    let defaultFloor = 0.7
    var maxTowers = 9
    let playSound = false
    let decay = 0.99
    
    fileprivate var launches:[ShipLaunch] = []
    
    var hasAI = false
    var journies:[Voyage] = []
    var points:Int = 0
    var victorySpeed:Double = 1
    var boatLevel = 0
    var victoryShipLevel = 3
    var isRecording = true
    fileprivate var info = MapHolder(grid:[])
    var startTime = Date()
    var currentIndex = 0
    
    
    
    var probalities:[ShipKind:ShipProbality] = [
        .battle:ShipProbality(base: -300, slope: 1.5, final: 80),
        .galley:ShipProbality(base: 1, slope: 2, final: 500),
        .motor:ShipProbality(base: 10, slope: 0.75, final: 20),
        .destroyer:ShipProbality(base: -220, slope: 0.8, final: 150),
        .crusier:ShipProbality(base: 0, slope: 0.8, final: 30),
        
        .bomber:ShipProbality(base: -70, slope: 0.8, final: 80),
        
        ]
    
    enum CodingKeys: String, CodingKey
    {
        case journies
        case info
        case launches
        case defaultFloor
        case maxTowers
        case probalities
        
    }
    
    func clear(){
        points = 0
        currentIndex = 0
        victoryShipLevel = 3
        victorySpeed  = 1
        boatLevel = 0
        victoryShipLevel = 3
        startTime = Date()
    }
    
    func add(ship:PirateNode, at:TimeInterval){
        guard  isRecording else { return }
        
        var routeNum = -1
        
        for (i, x) in self.journies.enumerated() {
            if x == ship.route{
                routeNum = i
            }
        }
        launches.append(ShipLaunch(ship: ship, time: at, index:routeNum))
        currentIndex += 1
    }
    
    func hasShip()->Bool{
        return currentIndex < launches.count
    }
    
    func load( map:MapHandler){
        
        clear()
        clearShips()
        
        self.info = MapHolder(map: map)
        self.journies = map.voyages
    }
    
    func apply(to map:MapHandler){
        map.voyages = self.journies
        info.adjust(map: map)
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
    
    static func read(name:String)->GameLevel?{
        
        let path = "/Users/arthurc/code/catsaves/\(name)"
        let u = URL(fileURLWithPath: path)
        
        do {
            
            let data =  try Data(contentsOf:u)
            let coder = JSONDecoder()
            
            let ret =  try coder.decode(GameLevel.self, from: data)
            
            
            return ret
            
        } catch let error {
            ErrorHandler.handle(.networkIssue, "Unable to send message \(error)")
        }
        
        return nil
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
    
    func nextShip()->(PirateNode,TimeInterval)?{
        
        guard hasShip() else { return nil }
        
        let b = launches[currentIndex]
        guard b.routeIndex < journies.count else { return nil }
        
        let route = journies[b.routeIndex]
        let ship = b.ship(route: route)
        
        currentIndex += 1
        
        return (ship, b.interval)
        
    }
    
    
}

extension GameLevel {
    
    
    
    
    
    func randomShipKind( at:TimeInterval)->ShipKind{
        
        var kinds:[ShipKind] = []
        var ranks:[Double] = []
        for (k,prob) in probalities {
            
            let r = prob.percentage(at: at)
            if r > 0 {
                kinds.append(k)
                ranks.append(r)
            }
            
        }
        
        let total = ranks.reduce(0, +)
        let xp = Double(GKRandomSource.sharedRandom().nextUniform())
        let x = xp * total
        
        var sum:Double = 0
        
        for (i, r) in ranks.enumerated() {
            
            sum += r
            if x < sum {
                return kinds[i]
            }
        }
        
        
        return .galley
        
        
    }
    
    func randomShip( modfier:Double, route:Voyage) -> PirateNode{
        
        let at = -startTime.timeIntervalSinceNow
        let kind = randomShipKind(at:at)
        return PirateNode.makeShip(kind:kind, modfier:modfier, route: route, level:boatLevel)
        
    }
}
