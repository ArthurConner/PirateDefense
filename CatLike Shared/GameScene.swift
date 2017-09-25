//
//  GameScene.swift
//  Plunder Shared
//
//  Created by Arthur  on 9/21/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import SpriteKit
import GameKit




class GameScene: SKScene {
    
    
    
    
    fileprivate var mapTiles = MapHandler()
    
 
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
    
    
    func convert(mappoint:MapPoint)->CGPoint? {
        
        guard let background = mapTiles.tiles else {return nil }

        let bar  = background.centerOfTile(atColumn:mappoint.col,row:mappoint.row)
        let foo =  self.convert(bar, from: background)

        return foo
    }
    
    func pathOf(mappoints route:[MapPoint])->CGPath?{
        
        guard let f1 = route.first, let p1 = convert(mappoint:f1) else { return nil}
        
        let path = CGMutablePath()
        path.move(to: p1)
        
        for hex in route {
            if let p = convert(mappoint:hex){
                path.addLine(to:p)
            }
        }
        
        return path
    }
    
    
    func setupWorldPhysics() {
        
       /*
        guard let background = mapTiles.tiles else {return  }
        background.physicsBody =
            SKPhysicsBody(edgeLoopFrom: background.frame)
        
        background.physicsBody?.categoryBitMask = PhysicsCategory.Edge
*/
       physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
       physicsWorld.contactDelegate = self
    }
    
    func setUpScene() {
        guard let tile  = self.childNode(withName: "//MapTiles") as? SKTileMapNode else { return }
        mapTiles.load(map:tile)
        
  
        mapTiles.refreshMap()
        
    }
    
    func handle(point: CGPoint){

        if let p = mapTiles.map(coordinate: point) {
            
            if  let dest = mapTiles.endIsle?.harbor {
                
                let wSet:Set<Landscape> = [.water,.path]
                let route = p.path(to: dest, map: mapTiles, using: wSet)
                
                if let path = pathOf(mappoints:route), let p1 = convert(mappoint:p) {
                    
                    let ship = PirateNode(named: "BlackBear")
                    ship.position = p1
                    
                    let time =  0.2 * Double(route.count)
 
 
                    self.addChild(ship)
                    
                ship.run(SKAction.repeat(SKAction.sequence([SKAction.run(ship.spawnWake),SKAction.wait(forDuration: 0.1)]), count: route.count * 2))
                    
                    let followLine = SKAction.follow( path, asOffset: false, orientToPath: true, duration: time)
                    ship.run(followLine)
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
        setupWorldPhysics()
        self.setUpScene()
    }
    #endif
    
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        super.update(currentTime)
        if isPaused { return }
        
    }
}

extension GameScene : SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        let other = contact.bodyA.categoryBitMask
            == PhysicsCategory.Player ?
                contact.bodyB : contact.bodyA
        
        print(other)
    }
    
    
     func didEnd(_ contact: SKPhysicsContact){
        print("ended")
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




