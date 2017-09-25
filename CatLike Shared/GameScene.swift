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
        mynode.fillColor = .purple
        
        
        let body = SKPhysicsBody(circleOfRadius:
            20)
        
        
        let BlockCategory  : UInt32 = 0x1 << 2
        
        body.isDynamic = false
        body.allowsRotation = false
        body.categoryBitMask = BlockCategory
        body.collisionBitMask = BlockCategory
        
        mynode.physicsBody = body
        body.affectedByGravity = true
        
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
        guard let tile  = self.childNode(withName: "//MapTiles") as? SKTileMapNode else { return }
        mapTiles.load(map:tile)
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 1.0)
        physicsWorld.contactDelegate = self
        mapTiles.refreshMap()
        
    }
    
    func handle(point: CGPoint){

        if let p = mapTiles.map(coordinate: point) {
            
            if  let dest = mapTiles.endIsle?.harbor {
                
                let wSet:Set<Landscape> = [.water,.path]
                let route = p.path(to: dest, map: mapTiles, using: wSet)
                
                if let path = pathCG(of:route), let p1 = CGPointOF(mp:p) {
                    
                    let mynode = shipM.makeShip()
                    mynode.position = p1
                    
                    let time =  0.2 * Double(route.count)
                    
                    /*
                    if let myEmt = SKEmitterNode(fileNamed: "ShipWake") {
                        myEmt.position = CGPoint(x: 20, y: 20)
                        mynode.addChild(myEmt)
                        let wait = SKAction.wait(forDuration: time)
                        let fadeAway = SKAction.fadeOut(withDuration: 0.25)
                        let removeNode = SKAction.removeFromParent()
                        let sequence = SKAction.sequence([ wait, fadeAway, removeNode])
                        
                        myEmt.run(sequence)
                    }
 */
                    self.addChild(mynode)
                    
                    let followLine = SKAction.follow( path, asOffset: false, orientToPath: false, duration: time)
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

extension GameScene : SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact){
        print ("ouch")
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




