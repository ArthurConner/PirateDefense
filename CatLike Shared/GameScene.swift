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
    
    var mapTiles = MapHandler()
    fileprivate var hud = HUD()
    
    var intervalTime:TimeInterval = 5
    var lastLaunch:Date = Date.distantPast
    
    fileprivate var towerLocations:[MapPoint:TowerNode] = [:]
    fileprivate var ships:[PirateNode] = []
    let maxTowers = 7
    
    var ai:TowerAI? = TowerAI()
    
    var gameState: GameState = .initial {
        didSet {
            hud.updateGameState(from: oldValue, to: gameState)
        }
    }
    
    //var isSending = false
    
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
    
    func tileOf(node:SKNode)->MapPoint? {
        return self.mapTiles.map(coordinate: node.position)
    }
    
    func convert(mappoint:MapPoint)->CGPoint? {
        
        guard let background = mapTiles.tiles else {return nil }
        
        let tileCenter  = background.centerOfTile(atColumn:mappoint.col,row:mappoint.row)
        return self.convert(tileCenter, from: background)
        
    }
    
    func pathOf(mappoints route:[MapPoint], startOveride:CGPoint? = nil)->CGPath?{
        
        guard let f1 = route.first, var p1 = convert(mappoint:f1) else { return nil}
        
        let path = CGMutablePath()
       
        
        p1 = startOveride ?? p1
        
        path.move(to: p1)
        
        for (i, hex) in route.enumerated() {
            if let p = convert(mappoint:hex){
                if i > 0 {
                    path.addLine(to:p)
                }
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
    
    
    #if os(watchOS)
    override func sceneDidLoad() {
    self.setUpScene()
    }
    #else
    
    @objc func sendMap(){
        
        let obj = GameMessage(info:mapTiles.deltas)
      //  NotificationCenter.default.post(name: <#T##NSNotification.Name#>, object: <#T##Any?#>)
        NotificationCenter.default.post(name: GameNotif.SendingDelta.notification, object: obj)
    }
    override func didMove(to view: SKView) {
        setupWorldPhysics()
        self.setUpScene()
        self.addChild(hud)
        self.ai = nil
        
        NotificationCenter.default.addObserver(self, selector: #selector(sendMap), name: GameNotif.NeedMap.notification, object: nil)
    }
    #endif
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
        
        if !ships.filter({ self.tileOf(node: $0) ?? MapPoint.offGrid == dest}).isEmpty {
            gameState = .lose
        }
        
        
        if let ai = self.ai {
            ai.update(scene: self)
            
        }
        
        
        //let shipPoints = ships.map(self.tileOf(node: $0) ?? MapPoint.offGrid}
        let shipPoints:[MapPoint] = ships.map({self.tileOf(node: $0) ?? MapPoint.offGrid})
        var navalTarget:[MapPoint] = []
        
        for (towerPoint,tower) in towerLocations {
            if tower.checkAge(scene: self) {
                navalTarget.append(towerPoint)
                let targets = tower.targetTiles(scene: self)
                for target in shipPoints {
                    if targets.contains(target) {
                        tower.fire(at:target,scene:self)
                    }
                }
            }
        }
        
        for ship in ships  {
            let targets = ship.targetTiles(scene: self)
            for target in navalTarget {
                
                if targets.contains(target) {
                    ship.fire(at:target,scene:self)
                }
            }
        }
        
    }
    
    
}

extension GameScene {
    
    func add(towerAt towerPoint:MapPoint){
        if let place = convert(mappoint: towerPoint){
        let tower = TowerNode(range:90)
        
        tower.position = place
        self.addChild(tower)
        towerLocations[towerPoint] = tower
        tower.adjust(level:0)
    }
    }
    
    
    func remove(tower:TowerNode) {
        
        if  let towerTile = tileOf(node: tower) {
            towerLocations[towerTile] = nil
            tower.removeFromParent()
        }
        
    }
    
    func tower(at:MapPoint) -> TowerNode? {
        return towerLocations[at]
    }
    
    func towersRemaining()->Int{
        return  maxTowers - towerLocations.count
    }
    
    func manageTower(point: CGPoint){
        guard let towerPoint = mapTiles.map(coordinate: point),
            mapTiles.kind(point: towerPoint) == .sand else { return }
        
        if let t = towerLocations[towerPoint] {
            
            if t.level > 0 {
                t.levelTimer.reduce(factor:0.9)
                t.level = -1
                t.adjust(level: -1)
                
            }
            
        } else if towerLocations.count < maxTowers {
          add(towerAt: towerPoint)
        
            
        }
    }
    

    
    

}


extension GameScene {
    
    func adjust(ship:PirateNode){
        
        guard let dest = mapTiles.endIsle?.harbor,
            let source =  self.mapTiles.map(coordinate: ship.position) else { return }
        
        
        guard dest != source else {
            self.gameState = .lose
            return
        }
        
        let wSet:Set<Landscape> = [.water,.path]
        let route = source.path(to: dest, map: mapTiles, using: wSet)
        
        if let path = pathOf(mappoints:route, startOveride:ship.position) {
            
            let time =  ship.waterSpeed * Double(route.count)
            ship.removeAllActions()
            ship.run(SKAction.repeat(SKAction.sequence([SKAction.run(ship.spawnWake),SKAction.wait(forDuration: ship.waterSpeed/4)]), count: route.count * 2))
            
            let followLine = SKAction.follow( path, asOffset: false, orientToPath: true, duration: time)
            ship.run(followLine)
            
        }
        
        
    }
    
    
    func add(ship:PirateNode){
      ships.append(ship)
      self.addChild(ship)
        adjust(ship: ship)
        
    }
    
    func remove(ship:PirateNode){
        ship.removeFromParent()
        
        ships = ships.filter({$0 != ship})
        hud.kills += 1
       
    }
    func launchAttack(timeOverTile:Double) {
        
        if let source = mapTiles.startIsle?.harbor ,  let shipPosition = convert(mappoint:source) {
            
            let ship =  randomShip( modfier:timeOverTile)
            ship.position = shipPosition
            
            add(ship: ship)
        }
        
    }
    
    func availableWater(around tile:MapPoint)->Set<MapPoint>{
        let water:Set<Landscape> = [.water,.path]
        var lifeBoatTiles = mapTiles.tiles(near:tile,radius:2,kinds:water)
        lifeBoatTiles.remove(tile)
        
        for x in ships {
            
            if let otherTile = tileOf(node: x){
                lifeBoatTiles.remove(otherTile)
            }
            
        }
        return lifeBoatTiles
    }
    
    
    func removeFrom(shipTile:MapPoint){
        
        var keepShip:[PirateNode] = []
        var killShips:[PirateNode] = []
        defer{
            for x in killShips {
                remove(ship: x)
            }
        }
        
        for (_ , boat) in self.ships.enumerated() {
            if let boatTile = self.tileOf(node: boat), boatTile == shipTile {
                
                self.hud.kills += 1
                if self.mapTiles.kind(point: shipTile) == .water {
                    self.mapTiles.changeTile(at: shipTile, to: .sand)
                } else {
                    self.mapTiles.changeTile(at: shipTile, to: .sand)
                }
                
                if boat != self {
                    killShips.append(boat)
                }
     
                
            } else {
                keepShip.append(boat)
            }
        }
        
        self.ships = keepShip
    }
    
    func redirectAllShips(){
        for (_ , boat) in ships.enumerated() {
            adjust(ship: boat)
        }
    }
    

    

}

extension GameScene : SKPhysicsContactDelegate {
    
    
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        /*
         let other = contact.bodyA.categoryBitMask
         == PhysicsCategory.Ship ?
         contact.bodyB : contact.bodyA
         */
        
        for (i,x) in [contact.bodyA.node, contact.bodyB.node].enumerated() {
            
            let y =  i == 0 ? contact.bodyB.node : contact.bodyA.node
            
            if let ship  = x as? PirateNode {
                ship.hit(scene: self)
                y?.run(SKAction.removeFromParent())
                return
            }
            
            if let t = x as? TowerNode {
                
                t.hit(scene: self)
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




