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
    case prob = "Ship Probality"
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
        
        let nodes = self.children
        
        for n in nodes {
            
            if let x = n as? PirateNode {
                x.removeFromParent()
            }
        }
        
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
    
    func handle(point: CGPoint){
        
        guard let towerPoint = mapTiles.map(coordinate: point)
            else { return }
        
        print(towerPoint)
        
        guard let tile  = mapTiles.tiles else { return }
        
        
        
        let current = mapTiles.kind(point: towerPoint)
        
        switch  gameState {
        case .run, .save, .clear, .exit:
            ErrorHandler.handle(.logic, "should not be clicking here")
        case .ships:
            handleShipTap(point: point)
        case .prob:
            handleShipProbality(point: point)
        case .island:
            mapTiles.addIsland(at: towerPoint)

        case .water:
            if current == .water {
                mapTiles.changeTile(at: towerPoint, to: .sand)
            } else {
                mapTiles.changeTile(at: towerPoint, to: .water)
            }
        case .start:
            if current == .homeBase {
                mapTiles.changeTile(at: towerPoint, to: .sand)
            } else {
                mapTiles.changeTile(at: towerPoint, to: .homeBase)
            }
        case .finish:
            
            for r in 0..<tile.numberOfRows{
                for c in 0..<tile.numberOfColumns{
                    let check = MapPoint(row:r,col:c)
                    if  mapTiles.kind(point: check) == .pirateBase{
                        mapTiles.changeTile(at:check, to: .sand)
                    }
                    
                }
            }
            
            mapTiles.changeTile(at: towerPoint, to: .pirateBase)
            
        }
        
    }
    
}




#if os(iOS) || os(tvOS)
    // Touch-based event handling
    extension EditorScene {
        
        func handle(touches: Set<UITouch>){
            
            for t in touches {
                let loc = t.location(in: self)
                handle(point: loc)
            }
        }
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            handle(touches: touches)
        }
        
        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            // handle(touches: touches)
        }
        
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            
        }
        
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            
        }
        
        
    }
#endif

#if os(OSX)
    // Mouse-based event handling
    extension EditorScene {
        
        override func mouseDown(with event: NSEvent) {
            handle(point:  event.location(in: self))
        }
        
        override func mouseDragged(with event: NSEvent) {
            handle(point:  event.location(in: self))
        }
        
        override func mouseUp(with event: NSEvent) {
            
        }
        
    }
#endif

extension EditorScene {
    func loadSequenceMode(){
        guard let tile  = mapTiles.tiles else { return  }
        tile.isHidden = true
        
        var row = 0
        var col = 0

        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        
        
        for x in level.launches {
            
            let p = MapPoint(row: row, col: col)
            if let d = mapTiles.convert(mappoint: p) {
                let ship = PirateNode.makeShip(kind: x.kind, modfier: x.modfier, route: Voyage(start: p, finish: p), level:  x.level)
                ship.position = d
                ship.position = CGPoint(x:30 * row,y:70 * col)
                if let x = ship.childNode(withName: "seasound"){
                    x.removeFromParent()
                }
                self.addChild(ship)
            }
            
            col += 1
            if col > tile.numberOfColumns {
                col = 0
                row += 1
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
    
    func refreshProb(){
        
        clearProb()
        self.backgroundColor = ColorUtils.shared.seaColor()

        
        struct ProbRamp{
            let p1:CGPoint
            let p2:CGPoint
            let kind:ShipKind
            
            init(prob:ShipProbality, kind k:ShipKind) {
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
                if let x = s1.childNode(withName: "seasound"){
                    x.removeFromParent()
                }
                return s1
            }
            
        }
        
        var probs:[ProbRamp] = []

        for (k,prob) in level.probalities {
            probs.append(ProbRamp(prob: prob, kind: k))
        }
        
        let maxX = probs.map{ return $0.p2.x }.reduce(0, { x ,y in return max(x,y)})
        
        let maxY = probs.map{ return max($0.p2.y,$0.p1.y) }.reduce(0, { x ,y in return max(x,y)})
        let minY = probs.map{ return min($0.p2.y,$0.p1.y) }.reduce(0, { x ,y in return min(x,y)})
        
        
        
        let trans = CGAffineTransform(translationX: -maxX/2, y: 0).concatenating(CGAffineTransform(scaleX: 2, y: 1))
        
        
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
    
    func loadProbMode(){
        guard let tile  = mapTiles.tiles else { return  }
        tile.isHidden = true

        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        refreshProb()
 
        
    }
    
    func handleShipProbality(point: CGPoint){
        
        if let p:PirateNode = self.nodes(at: point).filter({if let _ = $0 as? PirateNode{
            return true
            }
            return false}).first as? PirateNode {
            
            print("touched p \(p.kind)")
        }
    }

}
