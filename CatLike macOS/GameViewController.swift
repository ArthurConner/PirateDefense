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

    
    var myScene:GameScene?
    
    @IBAction func ReloadClicked(_ sender: Any) {
        
        guard let scene = myScene
            
            else { return}
        
        scene.restart()
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scene = GameScene.newGameScene()
        myScene = scene
        // Present the scene
        let skView = self.view as! SKView
        skView.presentScene(scene)
        
        skView.ignoresSiblingOrder = true
        
        skView.showsFPS = true
        skView.showsNodeCount = true
    }

}

