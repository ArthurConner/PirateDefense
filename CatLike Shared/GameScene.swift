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
        
      
        let node = SKSpriteNode(imageNamed: "PirateShip")
        
        
        return node
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
        
        
        if let harbor = mapTiles.startIsle?.harbor, let dest = mapTiles.endIsle?.harbor {
             let ship = self.shipM.makeShip()
            ship.position = tile.centerOfTile(atColumn:harbor.col,row:harbor.col)
           
            
            tile.addChild(ship)
            
            let wSet:Set<Landscape> = [.water,.path]
            
            let route = harbor.path(to: dest, map: mapTiles, using: wSet)
            
            let path = CGMutablePath()
            path.move(to: ship.position)
            
            for hex in route {
                if wSet.contains(mapTiles.kind(point: hex)){
                 mapTiles.changeTile(at: hex, to:.path)
                }
                path.addLine(to:  tile.centerOfTile(atColumn: hex.col, row: hex.row))
            }
      
            let followLine = SKAction.follow( path, asOffset: true, orientToPath: false, duration: 8.0)
            ship.run(followLine)
            
        }
        
        
        
    }
    
    func handle(point: CGPoint){
        
        return
        
        if let p = mapTiles.map(coordinate: point) {
            mapTiles.changeTile(at: p, to: .sand)
            /*
            if mapTiles.isBoundary(point: p) {
                print("boundary")
            } else {
                print("nope")
            }
 */
           
            print("")
            for x in p.adj(max: 24) {
                mapTiles.changeTile(at: x, to: .tower)
            }
            print("---")
 
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

