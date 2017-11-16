//
//  EditorScene.swift
//  CatLike
//
//  Created by Arthur Conner on 11/15/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import SpriteKit
import GameKit



enum EditorSceneActions:String {
    case island = "Make Islands"
    case water = "Toggle Water"
    case start = "Toggle Target"
    case finish = "Toggle Home"
    case clear = "Clear"
    case run = "Run"
    case save = "Save"
    
}


class EditorScene: SKScene {
    
    
    class func newGameScene() -> EditorScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "EditorScene") as? EditorScene else {
            print("Failed to load EditorScene.sks")
            abort()
        }
        
        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFit
        
        return scene
    }
    
    
    var level = GameLevel()
    var mapTiles = MapHandler()
    var currentName:String?
    
    
    func clear(){
       
        guard let tile  = self.childNode(withName: "//MapTiles") as? SKTileMapNode else { return }

        for r in 0..<tile.numberOfRows{
            for c in 0..<tile.numberOfColumns{
                let p = MapPoint(row:r,col:c)
                mapTiles.changeTile(at:p, to: .water)
            }
        }
    }
    func setUpScene() {
        guard let tile  = self.childNode(withName: "//MapTiles") as? SKTileMapNode else { return }
        mapTiles.load(map:tile)
        mapTiles.refreshMap()
        
        clear()
        
        level.load(map: mapTiles)
        
        
        
        if let name = level.nextLevelName, let l  = GameLevel.read(name: name) {
            level = l
            currentName = name
            level.apply(to: mapTiles)
        }
        
        
        
    }
    
    override func didMove(to view: SKView) {
        
        self.setUpScene()
        
        
    }
    
    
    var gameState: EditorSceneActions = .island {
        didSet {
            
            if gameState == .clear {
                clear()
                gameState = .island
            }
            print("changingState")
        }
    }
    
    
    
    func didSave()->String?{
        
        guard let tile  = mapTiles.tiles else { return nil }
        var home:MapPoint? = nil
        var bases:[MapPoint] = []
        
        for r in 0..<tile.numberOfRows{
            for c in 0..<tile.numberOfColumns{
                
                let p = MapPoint(row:r,col:c)
                let k = mapTiles.kind(point: p)
                if k == .homeBase {
                    home = p
                } else if k == .pirateBase {
                    bases.append(p)
                }
               
            }
        }
        
        
        guard let h = home, !bases.isEmpty else { return nil }
        
        level.load(map: mapTiles)
        
        level.journies.removeAll()
        
        for i in bases {
            
            level.journies.append(Voyage(start: i, finish: h))
            
        }
        
      
        let name = currentName ?? GameLevel.defaultName()
        level.write(name: name)
        
        
        return name
    }
    
    func handle(point: CGPoint){
        
        guard let towerPoint = mapTiles.map(coordinate: point)
            else { return }
        
        print(towerPoint)
        
        guard let tile  = mapTiles.tiles else { return }
        
        
        
        let current = mapTiles.kind(point: towerPoint)
        
        switch  gameState {
        case .run, .save, .clear:
            ErrorHandler.handle(.logic, "should not be clicking here")
        case .island:
            mapTiles.addIsland(at: towerPoint)
            
        
        case .water:
            if current == .water {
                mapTiles.changeTile(at: towerPoint, to: .sand)
            } else {
                mapTiles.changeTile(at: towerPoint, to: .water)
            }
        case .start:
            if current == .pirateBase {
                mapTiles.changeTile(at: towerPoint, to: .sand)
            } else {
                mapTiles.changeTile(at: towerPoint, to: .pirateBase)
            }
        case .finish:
            
            for r in 0..<tile.numberOfRows{
                for c in 0..<tile.numberOfColumns{
                    let check = MapPoint(row:r,col:c)
                    if  mapTiles.kind(point: check) == .homeBase{
                        mapTiles.changeTile(at:check, to: .sand)
                    }
                    
                }
            }
            
            mapTiles.changeTile(at: towerPoint, to: .homeBase)
            
        }
        
    }
    
}




#if os(iOS) || os(tvOS)
    // Touch-based event handling
    extension EditorScene {
        
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
    extension EditorScene {
        
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
