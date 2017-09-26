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
    let maxTowers = 7
    
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
        for ship in ships {
            ship.removeFromParent()
        }
        for (_, tower) in towerLocations {
            tower.removeFromParent()
        }
        
        
        guard let background = mapTiles.tiles else {return }
        
        for child in children {
            
            if child != hud && child != background {
                child.removeFromParent()
            }
        }
        
        ships.removeAll()
        towerLocations.removeAll()
        intervalTime = 5
        
    }
    func restart(){
        clear()
        setUpScene()
        gameState = .start
        hud.kills = 0
    }
    
    
    func convert(mappoint:MapPoint)->CGPoint? {
        
        guard let background = mapTiles.tiles else {return nil }
        
        let tileCenter  = background.centerOfTile(atColumn:mappoint.col,row:mappoint.row)
        return self.convert(tileCenter, from: background)
  
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
        guard let towerPoint = mapTiles.map(coordinate: point),
            mapTiles.kind(point: towerPoint) == .sand else { return }
        
        if let t = towerLocations[towerPoint] {
            
            if t.level > 0 {
                t.level = -1
                t.expireInterval = t.expireInterval * 0.9
                t.expireTime = Date(timeIntervalSinceNow: t.expireInterval)
                t.upgrade()
            }

        } else if let place = convert(mappoint: towerPoint), towerLocations.count < maxTowers {
            let tower = TowerNode(range:90)
            
            tower.position = place
            self.addChild(tower)
            towerLocations[towerPoint] = tower
            
            for towerAdjacentPoint in towerPoint.adj(max: mapTiles.mapAdj){
                if mapTiles.kind(point: towerAdjacentPoint) == .water {
                    tower.watchTiles.insert(towerAdjacentPoint)
                    for ta2 in towerAdjacentPoint.adj(max: mapTiles.mapAdj){
                        if mapTiles.kind(point: ta2) == .water {
                            tower.watchTiles.insert(ta2)
                        }
                        
                    }
                    
                }
                
            }
        }
    }
    
    func handle(point: CGPoint){
        
        
        switch gameState {

        case .start:
            gameState = .play
            isPaused = false
            
        case .play:
            manageTower(point: point)
        case .win, .lose:
            self.restart()
        case .reload:
            if let touchedNode =
                atPoint(point) as? SKLabelNode {
                if touchedNode.name == HUDMessages.yes {
                    isPaused = false
                    gameState = .play
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
    
    func adjust(ship:PirateNode){
        
        guard let dest = mapTiles.endIsle?.harbor,
            let source =  self.mapTiles.map(coordinate: ship.position) else { return }
        
        let wSet:Set<Landscape> = [.water,.path]
        let route = source.path(to: dest, map: mapTiles, using: wSet)
        
        if let path = pathOf(mappoints:route) {

            let time =  ship.waterSpeed * Double(route.count)
            ship.removeAllActions()
            ship.run(SKAction.repeat(SKAction.sequence([SKAction.run(ship.spawnWake),SKAction.wait(forDuration: ship.waterSpeed/4)]), count: route.count * 2))
            
            let followLine = SKAction.follow( path, asOffset: false, orientToPath: true, duration: time)
            ship.run(followLine)
            
        }
        
        
    }
    func launchAttack(timeOverTile:Double) {
        
        
        if let source = mapTiles.startIsle?.harbor ,  let shipPosition = convert(mappoint:source) {
            
            let ship = PirateNode(kind:randomShipKind(), modfier:timeOverTile)
            ship.position = shipPosition
           
            self.addChild(ship)
            ships.append(ship)
            adjust(ship: ship)
        }
        
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        super.update(currentTime)
        if isPaused { return }
        if gameState != .play {return}
        
        guard  let dest = mapTiles.endIsle?.harbor else { return }
        
        //Do we need to launch a new wave
        if lastLaunch < Date(timeIntervalSinceNow: 0){
            lastLaunch = Date(timeIntervalSinceNow:intervalTime)
            intervalTime = intervalTime * 0.99
            launchAttack(timeOverTile:intervalTime/8)
        }
        
        //Look at our ships positions
        var fleetPoints:Set<MapPoint> = []
        var navyRetaliation:[MapPoint:PirateNode] = [:]
        
        for ship in ships {
            if let shipPosition = self.mapTiles.map(coordinate: ship.position){
                navyRetaliation[shipPosition] = ship
            }
            if let shipPosition = mapTiles.map(coordinate: ship.position){
                if shipPosition == dest {
                    gameState = .lose
                }
                fleetPoints.insert(shipPosition)
            }
            
        }
        
        
        for (towerPoint,tower) in towerLocations {
            
            if tower.expireTime < Date(timeIntervalSinceNow: 0) {
                
                if tower.level > 2 {
                  self.mapTiles.changeTile(at: towerPoint, to: .inland)
                towerLocations[towerPoint] = nil
                 tower.die()
                } else {
                    tower.expireTime = Date(timeIntervalSinceNow: tower.expireInterval)
                    tower.upgrade()
                }
            } else if let shipTarget = tower.checkFire(targets: fleetPoints, converter: convert) {
                if let ship = navyRetaliation[shipTarget] {
                    ship.fire(target:towerPoint,converter:convert)
                }
            }
            
        }
 
    }
}

extension GameScene : SKPhysicsContactDelegate {
    
    func  hit(ship:PirateNode){
        ship.hitsRemain -= 1
        
        guard  let shipTile = self.mapTiles.map(coordinate: ship.position),
            let dest = mapTiles.endIsle?.harbor,
            let source =  mapTiles.startIsle?.harbor else { return }
        
        if ship.hitsRemain == 0 {
            
            
            ship.die()
            for (i , boat) in ships.enumerated() {
                if boat == ship {
                    ships.remove(at: i)
                    hud.kills += 1
                    if self.mapTiles.kind(point: shipTile) == .water {
                        self.mapTiles.changeTile(at: shipTile, to: .path)
                    } else {
                        self.mapTiles.changeTile(at: shipTile, to: .sand)
                    }
                    let wSet:Set<Landscape> = [.water,.path]
                    let route = source.path(to: dest, map: mapTiles, using: wSet)
                    if route.count < 2 {
                        self.mapTiles.changeTile(at: shipTile, to: .path)
                    }
                    
                }
            }
            
            for (_ , boat) in ships.enumerated() {
                adjust(ship: boat)
            }
            
        }
    }
    
    func hit(tower:TowerNode){
        
        tower.hitsRemain -= 1
        
        if tower.hitsRemain == 0 {
            guard   let towerTile = self.mapTiles.map(coordinate: tower.position),
                let dest = mapTiles.endIsle?.harbor,
                let source =  mapTiles.startIsle?.harbor else { return }
            var killSet:Set<MapPoint> = [towerTile]
            var addSet:Set<MapPoint> = [towerTile]
            
            for _ in 1..<3 {
                var nextSet:Set<MapPoint> = []
                for tile in addSet {
                    for n in tile.adj(max: mapTiles.mapAdj) {
                        if mapTiles.kind(point: n) == .sand &&
                            n != dest && n != source  &&
                            !killSet.contains(n){
                            
                            let keepSet:Set<Landscape> = [.top,.inland]
                            let f = n.adj(max: mapTiles.mapAdj).filter{ keepSet.contains(mapTiles.kind(point: $0))}
                            if f.isEmpty{
                                killSet.insert(n)
                            }
                            nextSet.insert(n)
                            
                        }
                    }
                    addSet = nextSet
                    
                }
            }
            
            for tile in killSet {
                if let t = towerLocations[tile] {
                    t.die()
                    towerLocations[tile] = nil
                }
                self.mapTiles.changeTile(at: tile, to: .water)
            }
            
            for (_ , boat) in ships.enumerated() {
                adjust(ship: boat)
            }
            
        } else {
            tower.run(SKAction.scale(by: 0.9, duration: 0.3))
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




