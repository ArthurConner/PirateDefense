//
//  GameViewController.swift
//  CatLike iOS
//
//  Created by Arthur  on 9/21/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension GameViewController:GameTypeModeDelegate {
    func didSet(game: GameTypeModes) {
        let nextGame:SKScene?
        
        switch game{
        case .tower:
            nextGame = GameScene.newGameScene()
        case .ship:
            let b = BoatScene.newGameScene()
            b.showButtons = false
            nextGame = b
        case .unknown:
            nextGame = nil
            
        }
        
        
        if let scene = nextGame {
            
            let skView = self.view as! SKView
            skView.presentScene(scene)
            
            skView.ignoresSiblingOrder = true
            skView.showsFPS = true
            skView.showsNodeCount = true
        }
        
    }
}
