//
//  BoatScene.swift
//  CatLike
//
//  Created by Arthur  on 10/2/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import Foundation
import SpriteKit
import GameKit

class BoatScene : SKScene {
    
    
    var mapTiles = MapHandler()
    fileprivate var hud = HUD()
    
    var deltaClock = PirateClock(0.1)
    
    var intervalTime:TimeInterval = 5
    
    fileprivate var towerLocations:[MapPoint:TowerNode] = [:]
    fileprivate var ships:[String:PirateNode] = [:]
    
    
    class func newGameScene() -> BoatScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "BoatScene") as? BoatScene else {
            print("Failed to load BoatScene.sks")
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

    
    /*
    @objc func sendMap(){
        
        let obj = GameMessage(info:mapTiles.deltas)
        //  NotificationCenter.default.post(name: <#T##NSNotification.Name#>, object: <#T##Any?#>)
        NotificationCenter.default.post(name: GameMessages.SendingDelta.notification, object: obj)
    }
    override func didMove(to view: SKView) {
        setupWorldPhysics()
        self.setUpScene()
        self.addChild(hud)
        self.ai = nil
        
        NotificationCenter.default.addObserver(self, selector: #selector(sendMap), name: GameMessages.NeedMap.notification, object: nil)
}
#endif


    */
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        super.update(currentTime)
        if isPaused { return }
        if gameState != .play {return}
        
        
        
        if deltaClock.needsUpdate() {
            NotificationCenter.default.post(name: GameNotif.NeedMap.notification, object: nil)
        }
        
        
    }
    
    func setupWorldPhysics() {
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
       // physicsWorld.contactDelegate = self
    }
    
    func setUpScene() {
        guard let tile  = self.childNode(withName: "//MapTiles") as? SKTileMapNode else { return }
        mapTiles.load(map:tile)
        
        mapTiles.refreshMap()
       // gameState = .start
        gameState = .play
        
    }
    
    override func didMove(to view: SKView) {
        setupWorldPhysics()
        self.setUpScene()
        
       NotificationCenter.default.addObserver(self, selector: #selector(gotDelta), name: GameNotif.SendingDelta.notification, object: nil)
    
    }
    
    
    
    @objc func gotDelta(note:NSNotification){
        
        guard let delta = note.object as? GameMessage else {
           print( "Got a delta with the wrong object \(note)")
            return
        }
        
        mapTiles.load(deltas: delta.info)
        var kills:[String] = []
        
        for (shI, ship) in ships {
            
            if let proxy = delta.info.ships[shI]{
                /*
                let path = CGMutablePath()
                path.move(to: ship.position)
                path.addLine(to: proxy.position )
                
                let followLine = SKAction.follow( path, asOffset: false, orientToPath: true, duration: delta.info.interval)
               
                
                ship.run(followLine)
 */
                ship.run(SKAction.move(to: proxy.position, duration: delta.info.interval))
                ship.zRotation = proxy.angle
            } else {
                ship.removeAllActions()
                ship.run(SKAction.sequence([SKAction.scale(by: 0.2, duration: 0.2),SKAction.removeFromParent()]))
                kills.append(shI)
            }
            
        }
        
        for x in kills {
            ships[x] = nil
        }
        
        for (shI , proxy) in delta.info.ships {
            
            if let _ = self.ships[shI] {
                
            } else {
                let addShip = PirateNode.makeShip(kind: proxy.kind, modfier: 1)
                ships[shI] = addShip
                addShip.position = proxy.position
                self.addChild(addShip)
                
                addShip.run(SKAction.repeat(SKAction.sequence([SKAction.run(addShip.spawnWake),SKAction.wait(forDuration: 0.3)]), count: 40))
                
               
               
            }
  
            
        }
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}
