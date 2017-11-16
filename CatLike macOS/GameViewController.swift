//
//  GameViewController.swift
//  CatLike macOS
//
//  Created by Arthur  on 9/21/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import Cocoa
import SpriteKit
import GameplayKit

class GameViewController: NSViewController {
    
    
    var myScene:SKScene?
    
    @IBAction func ReloadClicked(_ sender: Any) {
        
        guard let scene = myScene as? GameScene
            
            else { return}
        
        scene.restart()
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        didSet(game: .unknown)
        // Present the scene
        let skView = self.view as! SKView
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
    }
    
    
    func load(levelName:String){
        guard let scene = myScene as? GameScene
            
            else { return}
        
        scene.level.nextLevelName = levelName
        scene.restart()
    }
    
}



extension GameViewController:GameTypeModeDelegate {
    func didSet(game: GameTypeModes) {
        let nextGame:SKScene?
        
        
        switch game{
        case .tower:
            nextGame = GameScene.newGameScene(numTiles: 24)
        case .ship:
            let b = BoatScene.newGameScene()
            b.showButtons = false
            nextGame = b
        case .unknown:
            nextGame = WelcomeScene.newGameScene()
            
        }
        
        
        if let scene = nextGame {
            
            let skView = self.view as! SKView
            
            let trans = SKTransition.doorsOpenHorizontal(withDuration: 3)
            skView.presentScene(scene, transition:trans)
            
            skView.ignoresSiblingOrder = true
            skView.showsFPS = true
            skView.showsNodeCount = true
            
            myScene = scene
        }
        
    }
}

extension GameViewController: TowerPlayerActionDelegate {
    
    
    
    func didTower(action:TowerPlayerActions){
        if let responder = myScene as? TowerPlayerActionDelegate {
            responder.didTower(action: action)
        }
    }
}
