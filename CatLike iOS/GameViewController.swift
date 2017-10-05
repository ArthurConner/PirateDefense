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
        
        if let   buttonItem  = splitViewController?.displayModeButtonItem{
            self.navigationItem.leftBarButtonItem = buttonItem
            self.navigationItem.leftItemsSupplementBackButton = true
        }
        
        
        didSet(game: .unknown)
        
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
    
  
}

extension GameViewController:GameTypeModeDelegate {
    func didSet(game: GameTypeModes) {
        let nextGame:SKScene?
        
        if let nav = self.navigationController {
            print(nav)
        }
        switch game{
        case .tower:
            nextGame = GameScene.newGameScene()
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
        }
        
    }
}
