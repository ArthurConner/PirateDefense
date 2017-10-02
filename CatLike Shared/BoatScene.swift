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
    fileprivate var ships:[PirateNode] = []
    
    
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
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}
