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
    var playableRect = CGRect.zero
    
    let pavementClock = PirateClock(1)
    let livesLabel = SKLabelNode(fontNamed: "Chalkduster")
    let catsLabel = SKLabelNode(fontNamed: "Chalkduster")
    
    fileprivate var towers:[TowerNode] = []
    fileprivate var ships:[PirateNode] = []
    let maxTowers = 7
    
    var ai:TowerAI? = TowerAI()
    
    var gameState: GameState = .initial {
        didSet {
            hud.updateGameState(from: oldValue, to: gameState)
        }
    }
    
    
    func towerTiles()->Set<MapPoint>{
        
        return  Set<MapPoint>(towers.flatMap({tileOf(node:$0)}))
        
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
        for ( tower) in towers {
            tower.removeFromParent()
        }
        
        
        guard let background = mapTiles.tiles else {return }
        
        for child in children {
            
            if child != hud && child != background {
                child.removeFromParent()
            }
        }
        
        ships.removeAll()
        towers.removeAll()
       updateLabels()
        intervalTime = 5
        lastLaunch = Date(timeIntervalSinceNow:0)
        pavementClock.adjust(interval:5)
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
        
         let maxAspectRatio:CGFloat = 16.0/9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height-playableHeight)/2.0
        playableRect = CGRect(x: 0, y: playableMargin,
                              width: size.width,
                              height: playableHeight)
      

       // livesLabel.fontColor = SKColor.black
        livesLabel.fontSize = 32
        livesLabel.zPosition = 150
        livesLabel.horizontalAlignmentMode = .left
        livesLabel.verticalAlignmentMode = .bottom
        livesLabel.position = CGPoint(
            x: -playableRect.size.width/2 + CGFloat(20),
            y: -playableRect.size.height/2 + CGFloat(20) - 100)
        self.addChild(livesLabel)
        
        
        

       // catsLabel.fontColor = SKColor.black
        catsLabel.fontSize = 32
        catsLabel.zPosition = 150
        catsLabel.horizontalAlignmentMode = .right
        catsLabel.verticalAlignmentMode = .bottom
        catsLabel.position = CGPoint(x: playableRect.size.width/2 - CGFloat(20),
                                     y: -playableRect.size.height/2 + CGFloat(20) - 100 )
        self.addChild(catsLabel)
        updateLabels()
    }
    
    func updateLabels() {
        
        
        catsLabel.text = "Towers Remaining: \(towersRemaining())"
        if towersRemaining() > 0 {
            catsLabel.fontColor = .white
        } else {
            catsLabel.text = "No towers left"
            catsLabel.fontColor = .red
        }
        
        livesLabel.text = "Ships: \(hud.kills)"
        if hud.kills < 1 {
            livesLabel.text = ""
        }
    }
    
    
    #if os(watchOS)
    override func sceneDidLoad() {
    self.setUpScene()
    }
    #else
    
    @objc func sendMap(){
        
        mapTiles.deltas.ships.removeAll()
        
        for ship in ships {
            mapTiles.deltas.ships[ship.shipID] = ship.proxy()
        }
        
        mapTiles.deltas.towers.removeAll()
        
        for  tower in self.towers {
            mapTiles.deltas.towers[tower.towerID] = tower.proxy()
        }
        
        let obj = GameMessage(info:mapTiles.deltas)
        
        PirateServiceManager.shared.send(obj, kind: .SendingDelta)
        
        mapTiles.deltas.clear()
    }
    
    
    @objc func launchFromRemote(note:NSNotification){
        
        guard let shipInfo = note.object as? ShipLaunchMessage else {
            print( "Got a shipInfo with the wrong object \(note)")
            return
        }
        
        if let  trip = mapTiles.randomRoute() ,  let shipPosition = convert(mappoint:trip.start) {
            
            lastLaunch = Date(timeIntervalSinceNow:10)
            let ship =  PirateNode.makeShip(kind: shipInfo.ship.kind, modfier:intervalTime/8, route:trip)
            ship.position = shipPosition
            add(ship: ship)
        }
        
        
    }
    
    
    override func didMove(to view: SKView) {
        setupWorldPhysics()
        self.setUpScene()
        self.addChild(hud)
        self.ai = nil
        
        NotificationCenter.default.addObserver(self, selector: #selector(sendMap), name: GameNotif.NeedMap.notification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(launchFromRemote), name: GameNotif.launchShip.notification, object: nil)
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
        
        
        
        //Do we need to launch a new wave
        if lastLaunch < Date(timeIntervalSinceNow: 0){
            lastLaunch = Date(timeIntervalSinceNow:intervalTime)
            intervalTime = intervalTime * 0.99
            launchAttack(timeOverTile:intervalTime/8)
        }
        
        if !ships.filter({ $0.didFinish(map:mapTiles)}).isEmpty {
            gameState = .lose
        }
        
        
        if let ai = self.ai {
            ai.update(scene: self)
        }
        
        if pavementClock.needsUpdate() {
            launchTroll()
            pavementClock.update()
        }
        
        //let shipPoints = ships.map(self.tileOf(node: $0) ?? MapPoint.offGrid}
        let shipPoints:[MapPoint] = ships.map({self.tileOf(node: $0) ?? MapPoint.offGrid})
        var navalTarget:[MapPoint] = []
        
        for tower in towers {
            if tower.checkAge(scene: self), let towerPoint = tileOf(node: tower) {
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
            towers.append(tower)
            tower.adjust(level:0)
        }
        
        updateLabels()
    }
    
    
    func remove(tower:TowerNode) {
        
        defer{
           updateLabels()
        }
        
        for (i, x) in towers.enumerated(){
            if x.towerID == tower.towerID {
                towers.remove(at: i)
                tower.removeFromParent()
                return
            }
        }
        
       
        
    }
    
    func tower(at:MapPoint) -> TowerNode? {
        
        let list = towers.filter({tileOf(node: $0) == at})
        return list.first
    }
    
    func towersRemaining()->Int{
        return  maxTowers - towers.count
    }
    
    func manageTower(point: CGPoint){
        guard let towerPoint = mapTiles.map(coordinate: point),
            mapTiles.kind(point: towerPoint) == .sand else { return }
        
        if let t = tower(at:towerPoint) {
            
            if t.level > 0 {
                t.levelTimer.reduce(factor:0.9)
                t.level = -1
                t.adjust(level: -1)
                
            }
            
        } else if towersRemaining() > 0 {
            add(towerAt: towerPoint)
            
            
        }
    }
    
    
    
    
    
}


extension GameScene {
    
    func adjust(traveler:Navigatable ){
        
        let dest = traveler.route.finish
        
        guard let ship = traveler as? SKNode else {return}
        guard
            let source =  self.mapTiles.map(coordinate: ship.position) else { return }
        
        
        
        let route = source.path(to: dest, map: mapTiles, using: traveler.allowedTiles())
        
        if let path = pathOf(mappoints:route, startOveride:ship.position) {
            
            let time =  traveler.waterSpeed * Double(route.count)
            ship.removeAllActions()
            ship.run(SKAction.repeat(SKAction.sequence([SKAction.run(traveler.spawnWake),SKAction.wait(forDuration: traveler.waterSpeed/4)]), count: route.count * 2))
            
            let followLine = SKAction.follow( path, asOffset: false, orientToPath: true, duration: time)
            ship.run(followLine)
            
        }
        
        
    }
    
    
    func add(ship:PirateNode){
        ships.append(ship)
        self.addChild(ship)
        adjust(traveler: ship)
        
    }
    
    func remove(ship:PirateNode){
        ship.removeFromParent()
        
        ships = ships.filter({$0 != ship})
        hud.kills += 1
        updateLabels()
        
    }
    func launchAttack(timeOverTile:Double) {
        
        
        if let trip = mapTiles.randomRoute(),  let shipPosition = convert(mappoint:trip.start) {
            
            let ship =  randomShip( modfier:timeOverTile, route: trip)
            ship.position = shipPosition
            
            add(ship: ship)
            
            
            
            
        }
        
        
        
    }
    
    func launchTroll(){
        
        if let trip = mapTiles.randomRoute(),   let trollPosition = convert(mappoint: trip.finish) {
            
            
           // let troll = SandTower(timeOverTile: 1.5, route: Voyage(start: trip.finish, finish: trip.start))
            let troll = DefenderTower(timeOverTile: 1, route: Voyage(start: trip.finish, finish: trip.start))
            
            //troll.gun.clock.adjust(interval: 0.2)
            troll.position = trollPosition
            troll.fillColor = .purple
            
            self.towers.append(troll)
            self.addChild(troll)
            updateLabels()
            
            adjust(traveler: troll)
            
            
            pavementClock.adjust(interval: Double(troll.route.shortestRoute(map: mapTiles, using: waterSet).count) * troll.waterSpeed * 0.8 )
            pavementClock.update()
            
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
        
        for x in children {
            
            if let boat = x as? Navigatable {
                adjust(traveler: boat)
            }
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




