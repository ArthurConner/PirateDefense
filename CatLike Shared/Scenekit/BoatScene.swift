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


class BoatButton:SKSpriteNode {
    
    var kind:ShipKind = .galley
    
    func launch(){
        
        print("launching ship")
        let message = ShipLaunchMessage(ship: ShipProxy(kind: self.kind, shipID: "", position: CGPoint.zero, angle: 0))
  
        PirateServiceManager.shared.send(message, kind: .launchShip)
    }
    
    
    static func makeButton(kind aKind:ShipKind)->BoatButton {
   
        let ship:BoatButton
        
        
        
        switch aKind {
        case .galley:
            ship = BoatButton(imageNamed: "Galley" )
        case .row:
            ship = BoatButton(imageNamed: "Row" )
    
            
            
        case .crusier:
            
            ship = BoatButton(imageNamed: "Crusier" )

            
        case .destroyer:
            
            ship = BoatButton(imageNamed: "Destroyer" )
  
            
    
        case .motor:
            ship = BoatButton(imageNamed: "Motor" )
    
        case .battle:
             ship = BoatButton(imageNamed: "Battleship" )
        }
        
        
        
        
        
        
        ship.kind = aKind
        ship.zPosition = 3

        return ship
    }
    
}




class BoatScene : SKScene {
    
    
    var mapTiles = MapHandler()
    fileprivate var hud = HUD()
    
    var deltaClock = PirateClock(0.5)
    
    var intervalTime:TimeInterval = 5
    
    fileprivate var towers:[String:TowerNode] = [:]
    fileprivate var ships:[String:PirateNode] = [:]
    
    var showButtons = true
    
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
    
    

    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        super.update(currentTime)
        if isPaused { return }
        if gameState != .play {return}
        
        
        
        if deltaClock.needsUpdate() {
          
            
            PirateServiceManager.shared.send(NeedMapMessage(), kind: .NeedMap)
            deltaClock.update()
            
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
        gameState = .play
        
        if showButtons {
        let boats:[ShipKind] = [.crusier,.galley,.motor,.destroyer,.battle]
        
        
        func convert(_ mappoint:MapPoint)->CGPoint? {
            
            guard let background = mapTiles.tiles else {return nil }
            
            let tileCenter  = background.centerOfTile(atColumn:mappoint.col,row:mappoint.row)
            return self.convert(tileCenter, from: background)
            
        }
        
        for (i, boat) in boats.enumerated() {
            
            if let tile = convert(MapPoint(row: 1, col: (i+2)*2)) {
            
                let button = BoatButton.makeButton(kind: boat)
            
                button.run(SKAction.scale(by: 2, duration: 0.2))
                button.position = tile
                self.addChild(button)
            
            
            }
            
        }
        }
        
        
    }
    
    override func didMove(to view: SKView) {
        setupWorldPhysics()
        self.setUpScene()
        
        NotificationCenter.default.addObserver(self, selector: #selector(gotDelta), name: GameNotif.SendingDelta.notification, object: nil)
        
    }
    
    
    func deltaOfShip(_ delta:GameMessage){
        var kills:[String] = []
        let info = delta.info
        
        for (shI, ship) in ships {
            
            if let proxy = info.ships[shI]{
                
                ship.run(SKAction.move(to: proxy.position, duration: deltaClock.length()))
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
        
        for (shI , proxy) in info.ships {
            
            if let _ = self.ships[shI] {
                
            } else {
                let addShip = PirateNode.makeShip(kind: proxy.kind, modfier: 1, route: Voyage.offGrid())
                ships[shI] = addShip
                addShip.position = proxy.position
                self.addChild(addShip)
                addShip.run(SKAction.repeat(SKAction.sequence([SKAction.run(addShip.spawnWake),SKAction.wait(forDuration: 0.3)]), count: 40))
                
                addShip.run(SKAction.scale(by: 2, duration: 1))
                
            }
        }
    }
    
    func deltaOfTower(_ delta:GameMessage){
        var kills:[String] = []
        let info = delta.info
        
        for (shI, tower) in towers {
            
            if let toprox = info.towers[shI]{
                
                if toprox.level != tower.level {
                    tower.adjust(level: toprox.level)
                }
                
            } else {
                
                
                tower.run(SKAction.scale(by: CGFloat(tower.gun.radius) - 0.5, duration: 2))
                tower.run(SKAction.sequence([SKAction.fadeOut(withDuration: 4),
                                             SKAction.removeFromParent()]))
                kills.append(shI)
            }
            
        }
        
        for x in kills {
            towers[x] = nil
            print("killed tower \(x)")
        }
        
        for (shI , proxy) in info.towers {
            
            if let _ = self.towers[shI] {
                
            } else {
                
                
                let tower = TowerNode(range:90)
                
                tower.position = proxy.postition
                self.addChild(tower)
                towers[shI] = tower
                tower.adjust(level:0)
                
            }
        }
    }
    
    @objc func gotDelta(note:NSNotification){
        
        guard let delta = note.object as? GameMessage else {
            print( "Got a delta with the wrong object \(note)")
            return
        }
        
        mapTiles.load(deltas: delta.info)
        deltaOfShip(delta)
        deltaOfTower(delta)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func handle(point: CGPoint){
        
        for n in self.nodes(at: point){
            
            if let button = n as? BoatButton {
                button.launch()
            }
        }
        
    }
    
    
}



#if os(iOS) || os(tvOS)
    // Touch-based event handling
    extension BoatScene {
        
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
    extension BoatScene {
        
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
