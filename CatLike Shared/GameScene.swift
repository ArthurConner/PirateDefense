//
//  GameScene.swift
//  Plunder Shared
//
//  Created by Arthur  on 9/21/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import SpriteKit
import GameKit




class GameScene: SKScene {
    
    
    
    
    fileprivate var mapTiles = MapHandler()
    
    fileprivate var hud = HUD()
    
    var intervalTime:TimeInterval = 5
    var lastLaunch:Date = Date.distantPast
    
    var towerLocations:[MapPoint:TowerNode] = [:]
    var ships:[PirateNode] = []
    let maxTowers = 4
    
    var gameState: GameState = .initial {
        didSet {
            hud.updateGameState(from: oldValue, to: gameState)
        }
    }
    
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
        scene.scaleMode = .aspectFit
        
        return scene
    }
    
    
    func clear(){
        for x in ships {
            x.removeFromParent()
        }
        for (_, v) in towerLocations {
            v.removeFromParent()
        }
        
        
        guard let background = mapTiles.tiles else {return }
        
        for x in children {
            
            if x != hud && x != background {
                x.removeFromParent()
            }
        }
        
        ships.removeAll()
        towerLocations.removeAll()
        
    }
    func restart(){
        clear()
        setUpScene()
        gameState = .start
    }
    
    
    func convert(mappoint:MapPoint)->CGPoint? {
        
        guard let background = mapTiles.tiles else {return nil }
        
        let bar  = background.centerOfTile(atColumn:mappoint.col,row:mappoint.row)
        let foo =  self.convert(bar, from: background)
        
        return foo
    }
    
    func pathOf(mappoints route:[MapPoint])->CGPath?{
        
        guard let f1 = route.first, let p1 = convert(mappoint:f1) else { return nil}
        
        let path = CGMutablePath()
        path.move(to: p1)
        
        for hex in route {
            if let p = convert(mappoint:hex){
                path.addLine(to:p)
            }
        }
        
        return path
    }
    
    
    func setupWorldPhysics() {
        
        /*
         guard let background = mapTiles.tiles else {return  }
         background.physicsBody =
         SKPhysicsBody(edgeLoopFrom: background.frame)
         
         background.physicsBody?.categoryBitMask = PhysicsCategory.Edge
         */
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        physicsWorld.contactDelegate = self
    }
    
    func setUpScene() {
        guard let tile  = self.childNode(withName: "//MapTiles") as? SKTileMapNode else { return }
        mapTiles.load(map:tile)
        
        mapTiles.refreshMap()
        gameState = .start
        
    }
    
    func manageTower(point: CGPoint){
        guard let p = mapTiles.map(coordinate: point),
            mapTiles.kind(point: p) == .sand else { return }
        
        if let t = towerLocations[p] {
           // print("handle upgrade for \(t)")
            t.upgrade()
        } else if let place = convert(mappoint: p), towerLocations.count < 4 {
            let tower = TowerNode(range:90)
            
            tower.position = place
            self.addChild(tower)
            towerLocations[p] = tower
            
            for x in p.adj(max: mapTiles.mapAdj){
                if mapTiles.kind(point: x) == .water {
                    tower.watchTiles.insert(x)
                    for y in x.adj(max: mapTiles.mapAdj){
                        if mapTiles.kind(point: y) == .water {
                            tower.watchTiles.insert(y)
                        }
                        
                    }
                    
                }
                
            }
        }
    }
    
    func handle(point: CGPoint){
        
        
        switch gameState {
            // 1
            
        case .start:
            gameState = .play
            isPaused = false
            
        // 2
        case .play:
            // player.move(target: touch.location(in: self))
            manageTower(point: point)
        case .win, .lose:
            // transitionToScene(level: 1)
            self.restart()
        case .reload:
            // 1
            if let touchedNode =
                atPoint(point) as? SKLabelNode {
                // 2
                if touchedNode.name == HUDMessages.yes {
                    isPaused = false
                    gameState = .play
                    // 3
                } else if touchedNode.name == HUDMessages.no {
                    self.clear()
                }
            }
        default:
            break
        }
        
        
        
        
    }
    
    
    
    #if os(watchOS)
    override func sceneDidLoad() {
    self.setUpScene()
    }
    #else
    override func didMove(to view: SKView) {
        setupWorldPhysics()
        self.setUpScene()
        
        self.addChild(hud)
        
        
    }
    #endif
    
    
    func launchAttack(speed:Double) {
        
        
        if  let dest = mapTiles.endIsle?.harbor,
            let source = mapTiles.startIsle?.harbor  {
            
            
            
            let wSet:Set<Landscape> = [.water,.path]
            let route = source.path(to: dest, map: mapTiles, using: wSet)
            
            if let path = pathOf(mappoints:route), let p1 = convert(mappoint:source) {
                
                let ship = PirateNode(named: "BlackBear")
                ship.position = p1
                
                let time =  speed * Double(route.count)
                
                
                self.addChild(ship)
                
            ship.run(SKAction.repeat(SKAction.sequence([SKAction.run(ship.spawnWake),SKAction.wait(forDuration: speed/2)]), count: route.count * 2))
                
                let followLine = SKAction.follow( path, asOffset: false, orientToPath: true, duration: time)
                ship.run(followLine)
                ships.append(ship)
            }
            
        }
        
        
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        super.update(currentTime)
        if isPaused { return }
        if gameState != .play {return}
        
        guard  let dest = mapTiles.endIsle?.harbor else { return }
        
        if lastLaunch < Date(timeIntervalSinceNow: 0){
            lastLaunch = Date(timeIntervalSinceNow:intervalTime)
            intervalTime = intervalTime * 0.999
            launchAttack(speed:intervalTime/4)
        }
        
        var checkSet:Set<MapPoint> = []
        var reponse:[MapPoint:PirateNode] = [:]
        for x in ships {
            if let p = self.mapTiles.map(coordinate: x.position){
                reponse[p] = x
            }
           
            if let p = mapTiles.map(coordinate: x.position){
                if p == dest {
                    gameState = .lose
                }
                checkSet.insert(p)
                
            }
            
        }
        
        for (towerPoint,v) in towerLocations {
            if let shipP = v.checkFire(targets: checkSet, converter: convert) {
                if let ship = reponse[shipP] {
                    ship.fire(target:towerPoint,converter:convert)
                }
            }
            
        }
        
        
        
    }
}

extension GameScene : SKPhysicsContactDelegate {
    
    func  hit(ship:PirateNode){
        ship.hitsRemain -= 1
        if ship.hitsRemain == 0 {
            ship.die()
            for (i , v) in ships.enumerated() {
                if v == ship {
                    ships.remove(at: i)
                }
            }
        }
    }
    
    func hit(tower:TowerNode){
        
        guard   let p = self.mapTiles.map(coordinate: tower.position) else { return }
        tower.hitsRemain -= 1
        if tower.hitsRemain == 0 {
            tower.die()
            towerLocations[p] = nil
        }
    }
    func didBegin(_ contact: SKPhysicsContact) {
        /*
         let other = contact.bodyA.categoryBitMask
         == PhysicsCategory.Ship ?
         contact.bodyB : contact.bodyA
         */
        
        for (i,x) in [contact.bodyA.node, contact.bodyB.node].enumerated() {
            
            let y =  i == 0 ? contact.bodyB.node : contact.bodyA.node
            
            if let ship  = x as? PirateNode {
                hit(ship: ship)
                
                y?.run(SKAction.removeFromParent())
                return
            }
            
            if let t = x as? TowerNode {
                hit(tower:t)
                y?.run(SKAction.removeFromParent())
                return
            }
            
        }
    
        
        
    }
    
    
    func didEnd(_ contact: SKPhysicsContact){
        print("ended")
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




