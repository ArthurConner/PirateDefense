//
//  EditorScene.swift
//  CatLike
//
//  Created by Arthur Conner on 11/15/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import SpriteKit
import GameKit



enum EditorSceneActions:String {
    case island = "Make Islands"
    case water = "Toggle Water"
    case start = "Toggle Target"
    case finish = "Toggle Home"
    case clear = "Clear"
    case ships = "Ship Sequence"
    case prob = "Ship Probability"
    case run = "Run"
    case save = "Save"
    case exit = "Exit"
    
}


class EditorScene: SKScene {
    
    
    class func newGameScene() -> EditorScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "EditorScene") as? EditorScene else {
            print("Failed to load EditorScene.sks")
            abort()
        }
        
        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFit
        
        return scene
    }
    
    
    var level = GameLevel()
    var mapTiles = MapHandler()
    var currentName:String?
    var lastPoint:CGPoint? = nil
    var currentNode:PirateNode? = nil
    var currentTrans:CGAffineTransform? = nil
    var isCumaltive = false
    
    var isToggleOn = false
    
    var gameState: EditorSceneActions = .island {
        didSet {
            loadMapMode()
            if gameState == .ships {
                loadSequenceMode()
            } else if gameState == .prob {
                loadProbMode()
            } 
            
            if gameState == .clear {
                clear()
                gameState = .island
            }
            print("changingState")
        }
    }
    
    func clear(){
        
        guard let tile  = self.childNode(withName: "//MapTiles") as? SKTileMapNode else { return }
        
        for r in 0..<tile.numberOfRows{
            for c in 0..<tile.numberOfColumns{
                let p = MapPoint(row:r,col:c)
                mapTiles.changeTile(at:p, to: .water)
            }
        }
    }
    
    
    func load(levelName name:String){
        if let l  = GameLevel.read(name: name) {
            level = l
            currentName = name
            level.apply(to: mapTiles)
        }
        
    }
    
    func setUpScene() {
        guard let tile  = self.childNode(withName: "//MapTiles") as? SKTileMapNode else { return }
        mapTiles.load(map:tile)
        mapTiles.refreshMap()
        
        clear()
        
        level.load(map: mapTiles)
        
    }
    
    override func didMove(to view: SKView) {
        self.setUpScene()
        
    }
    
    
    
    
    
    func loadMapMode() {
        guard let tile  = mapTiles.tiles else { return  }
        
        tile.isHidden = false
        
        clearProb()
        
    }
    
    
    
    
    
    func didSave()->String?{
        
        guard let tile  = mapTiles.tiles else { return nil }
        var home:MapPoint? = nil
        var bases:[MapPoint] = []
        
        for r in 0..<tile.numberOfRows{
            for c in 0..<tile.numberOfColumns{
                
                let p = MapPoint(row:r,col:c)
                let k = mapTiles.kind(point: p)
                if k == .pirateBase {
                    home = p
                } else if k == .homeBase {
                    bases.append(p)
                }
                
            }
        }
        
        
        guard let h = home, !bases.isEmpty else { return nil }
        level.load(map: mapTiles)
        level.journies.removeAll()
        
        for i in bases {
            
            level.journies.append(Voyage(start: i, finish: h))
            
        }
        
        
        let name = currentName ?? GameLevel.defaultName()
        level.write(name: name)
        
        
        return name
    }
    
    
    func startMapClick(point:CGPoint,want:Landscape,other:Landscape)->Bool{
        
        
        guard let towerTile = mapTiles.map(coordinate: point)
            else { return  false}
        
        let current = mapTiles.kind(point: towerTile)
        isToggleOn = (current == want )
        
        return handleMapClick(point:point, want:want, other:other)
        
    }
    func handleMapClick(point:CGPoint,want:Landscape,other:Landscape)->Bool{
        
        let lastTile:MapPoint?
        
        
        guard let towerTile = mapTiles.map(coordinate: point)
            else { return  false}
        
        
        
        if let p = lastPoint,  let p1 = mapTiles.map(coordinate: p){
            lastTile = p1
        } else {
            lastTile = nil
        }
        
        if let l = lastTile, l == towerTile {
            return false
        }
        
        if isToggleOn {
            mapTiles.changeTile(at: towerTile, to: other)
        } else {
            mapTiles.changeTile(at: towerTile, to: want)
        }
        
        
        return true
    }
    
    func beginWith(point: CGPoint){
        
        switch  gameState {
        case .run, .save, .clear, .exit:
            break
        case .ships:
            handleShipTap(point: point)
        case .prob:
            beginShipProbability(point: point)
        case .island:
            if let towerTile = mapTiles.map(coordinate: point){
                mapTiles.addIsland(at: towerTile)
            }
        case .water:
            if startMapClick(point: point, want: .water, other: .sand) {
                lastPoint = point
            }
            
        case .start:
            if startMapClick(point: point, want: .homeBase, other: .sand) {
                lastPoint = point
            }
        case .finish:
            
            guard let tile  = mapTiles.tiles else { return  }
            
            for r in 0..<tile.numberOfRows{
                for c in 0..<tile.numberOfColumns{
                    let check = MapPoint(row:r,col:c)
                    if  mapTiles.kind(point: check) == .pirateBase{
                        mapTiles.changeTile(at:check, to: .sand)
                    }
                    
                }
            }
            if let towerTile = mapTiles.map(coordinate: point){
                mapTiles.changeTile(at: towerTile, to: .pirateBase)
            }
        }
        
    }
    
    
    func moveWith(point: CGPoint){
        
        switch  gameState {
        case .run, .save, .clear, .exit, .island:
            break
        case .ships:
            break
        case .prob:
            moveShipProbability(point: point)
        case .water:
            if handleMapClick(point: point, want: .water, other: .sand) {
                lastPoint = point
            }
            
        case .start:
            if handleMapClick(point: point, want: .homeBase, other: .sand) {
                lastPoint = point
            }
            
        case .finish:
            beginWith(point: point)
        }
    }
    
    func endWith(point:CGPoint){
        
        switch  gameState {
        case .run, .save, .clear, .exit, .island:
            break
        case .ships:
            break
        case .prob:
            endShipProbability(point: point)
        case .water, .start,.finish:
            break
        }
        
        lastPoint = nil
    }
    
}




#if os(iOS) || os(tvOS)
    // Touch-based event handling
    extension EditorScene {
        
        func handle(touches: Set<UITouch>){
            
            for t in touches {
                let loc = t.location(in: self)
                beginWith(point: loc)
            }
        }
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            //handle(touches: touches)
            for t in touches {
                let loc = t.location(in: self)
                beginWith(point: loc)
            }
            
        }
        
        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            // handle(touches: touches)
            //mo
            for t in touches {
                let loc = t.location(in: self)
                moveWith(point: loc)
            }
            
        }
        
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            for t in touches {
                let loc = t.location(in: self)
                endWith(point: loc)
            }
            
        }
        
        
        
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            
        }
        
    }
    
#endif

#if os(OSX)
    // Mouse-based event handling
    extension EditorScene {
        
        override func mouseDown(with event: NSEvent) {
            beginWith(point:  event.location(in: self))
        }
        
        override func mouseDragged(with event: NSEvent) {
            moveWith(point:  event.location(in: self))
        }
        
        override func mouseUp(with event: NSEvent) {
            endWith(point:  event.location(in: self))
        }
        
    }
#endif

extension EditorScene {
    func loadSequenceMode(){
        guard let tile  = mapTiles.tiles else { return  }
        tile.isHidden = true
        
        let width:CGFloat = 550
        var y:CGFloat = 400
        var x:CGFloat = -width
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        
        
        for launch in level.launches {
            
            
            
            let ship = PirateNode.makeShip(kind: launch.kind, modfier: launch.modfier, route: Voyage.offGrid(), level:  launch.level)
            
            ship.position = CGPoint(x:x,y:y)
            if let x = ship.childNode(withName: "seasound"){
                x.removeFromParent()
            }
            ship.physicsBody = nil
            //ship.removeAllActions()
            self.addChild(ship)
            
            
            x += 15 * CGFloat(launch.modfier * 8 / level.defaultFloor)
            if x > width{
                x = -width
                y -= 70
            }
        }
        
    }
    
    
    
    func handleShipTap(point: CGPoint){
        
        if let p:PirateNode = self.nodes(at: point).filter({if let _ = $0 as? PirateNode{
            return true
            }
            return false}).first as? PirateNode {
            
            print("touched p \(p.kind)")
        }
    }
}

extension EditorScene {
    
    func clearProb() {
        let x = children
        
        for n in x {
            
            if let a = n as? PirateNode {
                a.removeFromParent()
            } else if let a = n as? SKShapeNode {
                a.removeFromParent()
            }
        }
    }
    
    func refreshLineProb(){
        
        clearProb()
        self.backgroundColor = ColorUtils.shared.seaColor()
        
        var probs:[ProbRamp] = []
        
        for (k,prob) in level.probalities {
            probs.append(ProbRamp(prob: prob, kind: k))
        }
        
        let maxX = probs.map{ return $0.p2.x }.reduce(0, { x ,y in return max(x,y)})
        
        let maxY = probs.map{ return max($0.p2.y,$0.p1.y) }.reduce(0, { x ,y in return max(x,y)})
        let minY = probs.map{ return min($0.p2.y,$0.p1.y) }.reduce(0, { x ,y in return min(x,y)})
        
        
        
        let trans = CGAffineTransform(translationX: -maxX/2, y: 0).concatenating(CGAffineTransform(scaleX: 2, y: 1))
        
        
        currentTrans = trans
        
        let axisLine = CGMutablePath()
        axisLine.move(to: CGPoint(x:0,y:maxY).applying(trans))
        axisLine.addLine(to: CGPoint(x:0,y:minY).applying(trans))
        axisLine.addLine(to:  CGPoint(x:0,y:0).applying(trans))
        axisLine.addLine(to:  CGPoint(x:maxX,y:0).applying(trans))
        
        let axis = SKShapeNode(path: axisLine)
        axis.lineWidth = 3
        axis.strokeColor = .white
        axis.zPosition = 6
        self.addChild(axis)
        
        for prob in probs {
            
            let p1 = prob.p1.applying(trans)
            let f = prob.makeShip(isFirst: true)
            f.position = p1
            self.addChild(f)
            
            let p2 = prob.p2.applying(trans)
            let l = prob.makeShip(isFirst: false)
            l.position = p2
            self.addChild(l)
            
            
            let p3 = CGPoint(x:maxX,y:p2.y).applying(trans)
            let a = CGMutablePath()
            a.move(to: p1)
            a.addLine(to: p2)
            a.addLine(to: p3)
            
            let axis = SKShapeNode(path: a)
            axis.lineWidth = 3
            axis.strokeColor = l.wakeColor
            axis.zPosition = 5
            self.addChild(axis)
            
        }
        
        
        
    }
    
    
    
    func refreshCumlative(){
        
        clearProb()
        self.backgroundColor = ColorUtils.shared.seaColor()
        
        let xMax:CGFloat = 500.0
        
        let trans = CGAffineTransform(translationX: -xMax/2, y: -0.5).concatenating(CGAffineTransform(scaleX: 2, y: 500))
        
        currentTrans = trans
        
        let keys = level.probalities.keys.sorted(by:{$0.rawValue < $1.rawValue})
        var upperPoint:[ShipKind:[CGPoint]] = [:]
        var lowerPoint:[ShipKind:[CGPoint]] = [:]
        
        
        
        for i in 0..<50 {
            let t = Double(i * 10)
            
            var upperTotal:CGFloat = 0
            
            
            var upperMax:CGFloat = 0
            
            for k in keys {
                let prob = level.probalities[k]
                upperMax += CGFloat(max(prob?.percentage(at: t) ?? 0 ,0))
            }
            
            if upperMax > 0 {
                
                for k in keys {
                    let prob = level.probalities[k]
                    let add = CGFloat(max(prob?.percentage(at: t) ?? 0 ,0))/upperMax
                    var list = lowerPoint[k] ?? []
                    list.append(CGPoint(x:CGFloat(t),y:upperTotal))
                    lowerPoint[k] = list
                    
                    upperTotal =  upperTotal + CGFloat(add)
                    
                    var ulist = upperPoint[k] ?? []
                    ulist.append(CGPoint(x:CGFloat(t),y:upperTotal))
                    upperPoint[k] = ulist
                    
                    
                    
                }
                
            }
            
            
            
        }
        
        
        for k in keys {
            
            
            
            if let l = lowerPoint[k], let u = upperPoint[k], let f = l.first{
                let body = CGMutablePath()
                body.move(to: f.applying(trans))
                var b:[CGPoint] = l
                b.append(contentsOf:u.reversed())
                
                for i in 1..<b.count{
                    let p = b[i].applying(trans)
                    body.addLine(to: p)
                    
                }
                
                body.closeSubpath()
                
                
                let s1 = PirateNode.makeShip(kind: k, modfier:0, route: Voyage.offGrid(), level: 0)
                
                let region = SKShapeNode(path: body)
                region.fillColor = s1.wakeColor
                region.strokeColor = s1.wakeColor
                self.addChild(region)
            }
            
            
            
        }
        
        let button = SKShapeNode(circleOfRadius: 50)
        button.name = "Generate"
        button.fillColor = .yellow
        button.position = CGPoint(x: -10, y: 0).applying(trans)
        self.addChild(button)
        
        
        
        
        
    }
    
    func refreshProb() {
        if isCumaltive {
            refreshCumlative()
        } else {
            refreshLineProb()
        }
    }
    
    func loadProbMode(){
        guard let tile  = mapTiles.tiles else { return  }
        tile.isHidden = true
        
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        refreshProb()
        
        
    }
    
    func beginShipProbability(point: CGPoint){
        
        let list = self.nodes(at: point).filter{  return $0.name == "Generate" }
        if let _ = list.first {
            generateLaunches()
            self.gameState = .ships
            return
        }
        
        if let p:PirateNode = self.nodes(at: point).filter({if let _ = $0 as? PirateNode{
            return true
            }
            return false}).first as? PirateNode {
            
            currentNode = p
            print("touched p \(p.kind)")
        }
    }
    
    func moveShipProbability(point: CGPoint){
        guard let ship = currentNode else { return }
        ship.position = point
    }
    
    func endShipProbability(point: CGPoint){
        guard let ship = currentNode else {
            isCumaltive = !isCumaltive
            refreshProb()
            return
            
        }
        print(ship.name ?? "foo")
        currentNode = nil
        
        let list = self.nodes(at: point).filter{  return $0.name == "Generate" }
        if let _ = list.first {
            generateLaunches()
            self.gameState = .ships
            return
        }
        
        if  let p = level.probalities[ship.kind], let trans = currentTrans{
            
            let prob = ProbRamp(prob: p, kind: ship.kind)
            let final:ShipProbability
            
            if ship.name ==  "start\(ship.kind)"   {
                final = prob.adjust(first: ship.position, trans: trans.inverted())
            } else {
                final = prob.adjust(last: ship.position, trans: trans.inverted())
            }
            level.probalities[ship.kind] = final
            refreshProb()
            
        }
        
        
    }
    
    func generateLaunches(){
        level.launches.removeAll()
        
        var t:Double = 0
        var mod:Double = 5
        
        while t < 600 {
            let shipK = level.randomShipKind(at: t)
            let boat =  PirateNode.makeShip(kind:shipK, modfier:mod/8, route:Voyage.offGrid(), level:0)
            let prob = ShipLaunch(ship: boat, time: mod, index: 0)
            level.launches.append(prob)
            
            mod = max(mod * level.decay, level.defaultFloor)
            t += mod
            
        }
    }
    
}



struct ProbRamp{
    let p1:CGPoint
    let p2:CGPoint
    let kind:ShipKind
    
    init(prob:ShipProbability, kind k:ShipKind) {
        p1 = CGPoint(x: 0, y: prob.base)
        
        if prob.slope != 0 {
            let lastX = (prob.final - prob.base)/prob.slope
            p2 = CGPoint(x:lastX,y:prob.final)
        } else {
            p2 = p1
        }
        
        kind = k
        
    }
    
    func makeShip(isFirst:Bool)->PirateNode{
        let p = isFirst ? p1 : p2
        
        let s1 = PirateNode.makeShip(kind: kind, modfier: Double(p.x), route: Voyage.offGrid(), level: 0)
        s1.position = p
        s1.zPosition = 10
        
        s1.name = isFirst ? "start\(kind)" : "final\(kind)"
        s1.physicsBody = nil
        
        
        s1.run(SKAction.scale(by: 90, duration: 0.25))
        if let x = s1.childNode(withName: "seasound"){
            x.removeFromParent()
        }
        return s1
    }
    
    func adjust(first:CGPoint, trans:CGAffineTransform) -> ShipProbability {
        
        let base = first.applying(trans).y
        let final = p2.y
        let slope:CGFloat
        
        if p2.x != 0 {
            slope = (p2.y - base)/p2.x
        } else {
            slope = 0
        }
        
        return  ShipProbability(base: Double(base), slope: Double(slope), final: Double(final))
        
    }
    
    func adjust(last:CGPoint, trans:CGAffineTransform) -> ShipProbability {
        
        let p3 = last.applying(trans)
        let base = p1.y
        let final = p3.y
        let slope:CGFloat
        
        if p3.x != 0 {
            slope = (p3.y - base)/p3.x
        } else {
            slope = 0
        }
        
        return  ShipProbability(base: Double(base), slope: Double(slope), final: Double(final))
        
    }
    
}
