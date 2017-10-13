//
//  WelcomeScene.swift
//  CatLike
//
//  Created by Arthur  on 10/4/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import Foundation
import SpriteKit
import GameKit


class WelcomeScene : SKScene {
    
    
    
    #if os(iOS) || os(tvOS)
    // Touch-based event handling
  let back = UIColor(displayP3Red: 0.64, green: 0.80, blue: 1, alpha: 1)
    #else
    let back = NSColor.blue
    #endif
    var mapTiles = MapHandler()
    fileprivate var hud = HUD()
    
    var deltaClock = PirateClock(0.5)
 

    
    class func newGameScene() -> WelcomeScene {
        // Load 'GameScene.sks' as an SKScene.
        
        
        
        guard let scene = SKScene(fileNamed: "WelcomeScene") as? WelcomeScene else {
            print("Failed to load WelcomeScene.sks")
            abort()
        }
        
        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFit
        
        
        return scene
    }
    
    var gameState: GameState = .initial {
        didSet {
            // hud.updateGameState(from: oldValue, to: gameState)
            print("newState")
        }
    }
    
    
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        super.update(currentTime)
        if isPaused { return }
        if gameState != .play {return}
        
        
        
        if deltaClock.needsUpdate() {
            
     
            
        }
        
        
    }
    
    func setupWorldPhysics() {
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        // physicsWorld.contactDelegate = self
    }
    
    func setUpScene() {
       
       
        self.backgroundColor = self.back
    
        
        
    }
    
    override func didMove(to view: SKView) {
        setupWorldPhysics()
        self.setUpScene()
        
    }
    
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func handle(point: CGPoint){
        
     
        
    }
    
    
}



#if os(iOS) || os(tvOS)
    // Touch-based event handling
    extension WelcomeScene {
        
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
    extension WelcomeScene {
        
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
