//
//  GameScene.swift
//  Plunder Shared
//
//  Created by Arthur  on 9/21/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import SpriteKit
import GameKit



class ShipNode :SKShapeNode {
    
    
    
    
}

class ShipMaker {
    
    func makeShip()->SKNode{
        
        
        //let node = SKSpriteNode(imageNamed: "PirateShip")
        let mynode = SKShapeNode(circleOfRadius: 20)
        mynode.fillColor = .green
        
        return mynode
    }
}

class GameScene: SKScene {
    
    
    
    
    fileprivate var mapTiles = MapHandler()
    
    let shipM = ShipMaker()
    /*
     
     lazy var componentSystems: [GKComponentSystem] = {
     let animationSystem = GKComponentSystem(
     componentClass: AnimationComponent.self)
     let firingSystem = GKComponentSystem(componentClass: FiringComponent.self)
     return [animationSystem, firingSystem]
     }()
     
     */
    
    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        
        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFill
        
        return scene
    }
    
    
    func restart(){
        
        setUpScene()
        
    }
    
    
    func CGPointOF(mp:MapPoint)->CGPoint? {
        
        guard let background = mapTiles.tiles else {return nil }
        
        
        
        
        let bar  = background.centerOfTile(atColumn:mp.col,row:mp.row)
        let foo =  self.convert(bar, from: background)
        
        // print("\(bar) \(foo)")
        return foo
        
        
        
    }
    func pathCG(of route:[MapPoint])->CGPath?{
        
        
        
        guard let f1 = route.first, let p1 = CGPointOF(mp:f1) else { return nil}
        
        let path = CGMutablePath()
        path.move(to: p1)
        
        for hex in route {
            if let p = CGPointOF(mp:hex){
                path.addLine(to:p)
            }
        }
        
        return path
    }
    
    
    func setUpScene() {
        // Get label node from scene and store it for use later
        guard let tile  = self.childNode(withName: "//MapTiles") as? SKTileMapNode else { return }
        mapTiles.load(map:tile)
        
        
        mapTiles.refreshMap()
        
        /*
         let wSet:Set<Landscape> = [.water,.path]
         let path = sHarbor.path(to: dHarbor, map: self, using: wSet)
         
         for i in path {
         
         if wSet.contains(kind(point: i)){
         changeTile(at: i, to:.path)
         }
         
         }
         */
        
        /*
         if let harbor = mapTiles.startIsle?.harbor, let dest = mapTiles.endIsle?.harbor {
         let ship = self.shipM.makeShip()
         
         func loc(_ harbor:MapPoint)->CGPoint{
         
         let bar  = tile.centerOfTile(atColumn:harbor.col,row:harbor.col)
         let foo =  self.convert(bar, from: tile)
         
         print("\(bar) \(foo)")
         return foo
         
         }
         ship.position = loc(harbor)
         
         
         self.addChild(ship)
         
         let wSet:Set<Landscape> = [.water,.path]
         
         let route = harbor.path(to: dest, map: mapTiles, using: wSet)
         
         let path = CGMutablePath()
         path.move(to: ship.position)
         
         for hex in route {
         if wSet.contains(mapTiles.kind(point: hex)){
         mapTiles.changeTile(at: hex, to:.path)
         }
         path.addLine(to:loc(hex))
         }
         
         let followLine = SKAction.follow( path, asOffset: true, orientToPath: false, duration: 8.0)
         ship.run(followLine)
         
         }
         
         */
        
    }
    
    func handle(point: CGPoint){
        
        
       // guard let background = mapTiles.tiles else {return}

        if let p = mapTiles.map(coordinate: point) {
            
            if  let dest = mapTiles.endIsle?.harbor {
                
                let wSet:Set<Landscape> = [.water,.path]
                let route = p.path(to: dest, map: mapTiles, using: wSet)
                
                if let path = pathCG(of:route), let p1 = CGPointOF(mp:p) {
                    
                    let mynode = SKShapeNode(circleOfRadius: 20)
                    mynode.fillColor = .orange
                    
                    //let bar2 = self.convert(bar, from: background)
                    mynode.position = p1
                    self.addChild(mynode)
                    
                    
                    
                    let followLine = SKAction.follow( path, asOffset: false, orientToPath: false, duration: 8.0)
                    mynode.run(followLine)
                }

            }
            
        }

    }
    
    
    #if os(watchOS)
    override func sceneDidLoad() {
    self.setUpScene()
    }
    #else
    override func didMove(to view: SKView) {
        self.setUpScene()
    }
    #endif
    
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        super.update(currentTime)
        if isPaused { return }
        
    }
}

#if os(iOS) || os(tvOS)
    // Touch-based event handling
    extension GameScene {
        
        
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
            handle(touches: touches)
        }
        
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            
        }
        
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            
        }
        
        
    }
#endif

#if os(OSX)
    // Mouse-based event handling
    extension GameScene {
        
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

