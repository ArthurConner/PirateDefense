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
    
    
    fileprivate var hud = HUD()
    
    var level = GameLevel()
    
    var mapTiles = MapHandler()
    var launchClock = PirateClock(5)
    var playableRect = CGRect.zero
    
    let tapClock = PirateClock(0.5)
    
    let counterShipClock = PirateClock(1)
    fileprivate let shipsKilledLabel = SKLabelNode(fontNamed: "Chalkduster")
    fileprivate let towersRemainingLabel = SKLabelNode(fontNamed: "Chalkduster")
    
    fileprivate var towers:[TowerNode] = []
    fileprivate var ships:[PirateNode] = []
    
    fileprivate var routeDebug:[String:[MapPoint]] = [:]
    
    
    weak var followingShip:TowerNode?
    
    var zoomOutOnRedirect = false
    var ai:TowerAI? = TowerAI()
    
    var gameState: GameState = .initial {
        didSet {
            hud.updateGameState(from: oldValue, to: gameState)
            playBackgroundNoise()
        }
    }
    
    
    //MARK: scene loading
    
    class func newGameScene(numTiles:Int) -> GameScene {
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        
        scene.scaleMode = .aspectFit
        scene.backgroundColor = .orange
            
        scene.backgroundColor =  ColorUtils.shared.r( 0, g: 0.33, b: 0.44)
        
        return scene
    }
    
    
    func clear(){
        for ship in ships {
            ship.removeFromParent()
        }
        for ( tower) in towers {
            tower.removeFromParent()
        }
        
        level.clear()
        guard let background = mapTiles.tiles else {return }
        
        hud.removeFromParent()
        self.addChild(hud)
        for child in children {
            
            if child != hud && child != background {
                child.removeFromParent()
            }
        }
        
        ships.removeAll()
        towers.removeAll()
        updateLabels()
        launchClock.adjust(interval:5)
        launchClock.tickNext()
        launchClock.floor = level.defaultFloor
        counterShipClock.adjust(interval:5)
        
    }
    
    func restart(){
        clear()
        setUpScene()
        gameState = .start
        hud.kills = 0
    }

    func setupWorldPhysics() {
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        physicsWorld.contactDelegate = self
    }
    
    func setUpScene() {
        guard let tile  = self.childNode(withName: "//MapTiles") as? SKTileMapNode else { return }
        mapTiles.load(map:tile)
        
        mapTiles.multipleStart = ( GKRandomSource.sharedRandom().nextUniform() > 0.75)
        mapTiles.refreshMap()
        gameState = .start
        
        level.load(map: mapTiles)
 
        if let name = level.nextLevelName, let l  = GameLevel.read(name: name) {
            level = l
            level.apply(to: mapTiles)
        }

        if level.hasAI, ai == nil {
            self.ai = TowerAI()
        } else {
            self.ai = nil
        }
        
        let maxAspectRatio:CGFloat = 16.0/9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height-playableHeight)/2.0
        playableRect = CGRect(x: 0, y: playableMargin,
                              width: size.width,
                              height: playableHeight)
        
        shipsKilledLabel.fontSize = 32
        shipsKilledLabel.zPosition = 150
        shipsKilledLabel.horizontalAlignmentMode = .left
        shipsKilledLabel.verticalAlignmentMode = .bottom
        shipsKilledLabel.position = CGPoint(
            x: -playableRect.size.width/2 + CGFloat(20),
            y: -playableRect.size.height/2 + CGFloat(20) - 100)
        self.addChild(shipsKilledLabel)
        
        towersRemainingLabel.fontSize = 32
        towersRemainingLabel.zPosition = 150
        towersRemainingLabel.horizontalAlignmentMode = .right
        towersRemainingLabel.verticalAlignmentMode = .bottom
        towersRemainingLabel.position = CGPoint(x: playableRect.size.width/2 - CGFloat(20),
                                                y: -playableRect.size.height/2 + CGFloat(20) - 100 )
        self.addChild(towersRemainingLabel)
        updateLabels()
        
        guard let v = mapTiles.voyages.first, let pos =  mapTiles.convert(mappoint: v.finish) else {return}
        
        let hearer = SKShapeNode(circleOfRadius:20)
        hearer.fillColor = .clear
        hearer.position = pos
        self.listener = hearer
        self.addChild(hearer)
    }
    
    func updateLabels() {
        let strength = level.victoryShipStartingLevel()
        towersRemainingLabel.text = "Towers Remaining: \(towersRemaining()) Str:\(strength)"
        if towersRemaining() > 0 {
            towersRemainingLabel.fontColor = .white
        } else {
            towersRemainingLabel.text = "No towers left"
            towersRemainingLabel.fontColor = .red
        }
        
        shipsKilledLabel.text = "Ships: \(hud.kills) Points:\(level.points)"
        if hud.kills < 1 {
            shipsKilledLabel.text = ""
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
        
        if let  trip = mapTiles.randomRoute() ,  let shipPosition =  mapTiles.convert(mappoint:trip.start) {
            let ship =  PirateNode.makeShip(kind: shipInfo.ship.kind, modfier:launchClock.length()/8, route:trip, level: level.boatLevel)
            launchClock.adjust(interval: 10)
            ship.position = shipPosition
            add(ship: ship)
        }
        
        
    }
    
    
    override func didMove(to view: SKView) {
        setupWorldPhysics()
        self.setUpScene()
        self.addChild(hud)
        // self.ai = nil
        
        NotificationCenter.default.addObserver(self, selector: #selector(sendMap), name: GameNotif.NeedMap.notification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(launchFromRemote), name: GameNotif.launchShip.notification, object: nil)
    }
    #endif
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: Helper Functions
    
    func playBackgroundNoise() {
        stopBackgroundNoise()
        guard let f = mapTiles.voyages.first?.finish, let p = mapTiles.convert(mappoint: f) else {
            ErrorHandler.handle(.wrongGameState, "we don't have a starting point")
            return
            
        }
        
        for x in children {
            if let kill = x.childNode(withName: "seasound") as? SKAudioNode{
                kill.run(SKAction.sequence([SKAction.stop(),SKAction.removeFromParent()]))
            }
            
            if let b = x as? Fireable {
                b.gun.clock.enabled = false
            }
            
            if let b = x as? CannonBall {
                b.removeFromParent()
            }
        }
        
        if level.playSound {
            let me = SKAudioNode(fileNamed:"SeaStorm.caf")
            me.name = "backgroundStorm"
            me.autoplayLooped = true
            me.isPositional = true
            me.position = p
            
            me.run(SKAction.changeVolume(to: 0.1, duration: 0.3))
            
            
            self.addChild(me)
            
            
        }
    }
    
    func stopBackgroundNoise(){
        for x in self.children{
            x.removeAction(forKey: "wake")
            x.removeAction(forKey: "move")
        }
        
        if let m = self.childNode(withName: "backgroundStorm") {
            m.removeFromParent()
        }
        self.mapTiles.tiles?.removeAllActions()
    }
    
    
    func towerTiles()->Set<MapPoint>{
        return  Set<MapPoint>(towers.flatMap({tileOf(node:$0)}))
    }
    
    func shipTiles()->Set<MapPoint>{
        return  Set<MapPoint>(ships.flatMap({tileOf(node:$0)}))
    }
    
    func navigatableBoats(at point:MapPoint)->[Navigatable]{
        let p1 = self.children.filter({self.tileOf(node: $0) == point})
        return p1.flatMap{$0 as? Navigatable}
        
    }
    
    func tileOf(node:SKNode)->MapPoint? {
        return self.mapTiles.map(coordinate: node.position)
    }
    
    
    
    func handle(point: CGPoint){
        
        switch gameState {
            
        case .start:
            gameState = .play
            isPaused = false
            
        case .play:
            manageTapWhilePlaying(point: point)
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
        if launchClock.needsUpdate(){
            
            let s = shipTiles().count
            let r = self.mapTiles.voyages[0]
            if r.shortestRoute(map: self.mapTiles, using: waterSet).count > s * 2 {
                
                
                launchAttack(timeOverTile:max(2.5,launchClock.length())/8)
                
            } else {
                level.boatLevel += 1
                launchClock.reduce(factor: 1.5)
                print("next level for boats \(level.boatLevel)")
            }
        }
        
        if !ships.filter({ $0.didFinish(map:mapTiles)}).isEmpty {
            gameState = .lose
        }
        
        
        if let ai = self.ai {
            ai.update(scene: self)
        }
        
        if counterShipClock.needsUpdate() && towersRemaining() > 0 {
            launchVictoryShip()
            counterShipClock.update()
        }
        
        
        let shipPoints:[MapPoint] = ships.flatMap({self.tileOf(node: $0)})
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
    
    func manageTapWhilePlaying(point: CGPoint){
        guard let towerPoint = mapTiles.map(coordinate: point)
            else { return }
        
        
        if let t = tower(at:towerPoint) {
            if let _ = t as? Navigatable {
                self.followingShip = t
                zoomOutOnRedirect = false
                
            } else if t.level > 0 {
                t.levelTimer.reduce(factor:0.9)
                t.level = -1
                t.adjust(level: -1)
                
                self.followingShip = t
                zoomOutOnRedirect = false
            }
            
        } else if towersRemaining() > 0, mapTiles.kind(point: towerPoint) == .sand  {
            add(towerAt: towerPoint)
        } else if  mapTiles.kind(point: towerPoint) == .water {
            
            self.followingShip = nil
            
            if tapClock.needsUpdate() {
                let (cam,_) = makeCamera()
                sweep(camera: cam, to: point)
            } else {
                zoomOutOnRedirect = !zoomOutOnRedirect
            }
            
        }
        
        tapClock.update()
        redirectAllShips()
        
    }
    
}

extension GameScene {
    
    
    /// adds a tower to our scene
    ///
    /// - Parameter towerPoint: The map point we want to use
    func add(towerAt towerPoint:MapPoint){
        
        if let place = mapTiles.convert(mappoint: towerPoint){
            let tower = TowerNode(range:90)
            tower.hitsRemain = level.towerStartingLevel()
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
        
        if tower == self.followingShip {
            self.followingShip = nil
            
            if let c = self.camera {
                c.removeAllActions()
            }
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
        return  level.maxTowers - towers.count
    }
    
    
    
}


extension GameScene {
    
    func isDeepIntoGame()->Bool{
        
        return  launchClock.length() < launchClock.floor + 2.1
    }
    
    func shouldPlaySound()->Bool{
        if level.playSound,  !isDeepIntoGame()  {
            return true
        }
        return false
    }
    
    func adjust(traveler:Navigatable, existing:Set<MapPoint> ){
        
        
        guard let ship = traveler as? SKNode else {return}
        
        let (f,p) = traveler.sailAction(usingTiles:mapTiles, orient: true, existing: existing)
        if let followLine = f {
            ship.run(followLine,withKey:"move")
            ship.removeAction(forKey: "wake")
            if !isDeepIntoGame() {
                ship.run(traveler.wakeAction(), withKey:"wake")
            } else if let x = ship.childNode(withName: "seasound"), GKRandomSource.sharedRandom().nextUniform() < 0.1 {
                x.removeFromParent()
            }
            
        } else {
            ship.removeAction(forKey:"move")
            ship.removeAction(forKey: "wake")
        }
        
        if let path = p , let b = level.showsPaths, b{
            self.addChild(path)
        }
        
        /*
         let dest = traveler.route.finish
         
         guard let ship = traveler as? SKNode,
         let source =  self.mapTiles.map(coordinate: ship.position),  let de = infoOf(node: ship)  else { return }
         
         
         let k = mapTiles.kind(point: source)
         
         func debug(tile:MapPoint)->String{
         
         let k = mapTiles.kind(point: tile)
         let navs  = self.navigatableBoats(at: tile)
         
         let towers = navs.flatMap({$0 as? TowerNode}).map{return $0.towerID}.joined(separator: ", ")
         let ships =  navs.flatMap({$0 as? PirateNode}).map{return $0.shipID}.joined(separator: ", ")
         
         return "row:\(tile.row),col:\(tile.col),kind:\(k),towers:\(towers),ships:\(ships)"
         
         }
         
         //!traveler.allowedTiles().contains(k) &&
         if  k == .sand {
         
         if let f = traveler as? Fireable {
         
         print("")
         if let key = self.infoOf(node: ship) , let oldR = routeDebug[key]{
         print("\(key) ran ashore at \(debug(tile:source)) \npath is:")
         
         for x in oldR {
         print("\(debug(tile:x))")
         
         //FIXME: somehow we go to points that aren't on the path
         if x == source {
         print("ran ashore")
         f.die(scene: self, isKill: true)
         return
         }
         }
         
         print(" but not on the map")
         
         }
         
         } else if let n = traveler as? SKNode {
         n.removeFromParent()
         return
         }
         
         
         
         
         }
         
         var route = source.path(to: dest, map: mapTiles, using: traveler.allowedTiles())
         
         for r in route {
         
         if mapTiles.kind(point: r) == .sand{
         print("we are going over sand at \(debug(tile:r))")
         
         for p in route {
         print(debug(tile: p))
         }
         route = [source,source]
         
         
         if let key = self.infoOf(node: ship) , let oldR = routeDebug[key]{
         print("\(key)\npath was:")
         
         for x in oldR {
         print("\(debug(tile:x))")
         }
         
         print(" but not on the map")
         
         }
         }
         }
         
         if let path = pathOf(mappoints:route, startOveride:ship.position){
         
         let time =  traveler.waterSpeed * Double(route.count)
         ship.removeAllActions()
         ship.run(SKAction.repeat(SKAction.sequence([SKAction.run(traveler.spawnWake),SKAction.wait(forDuration: traveler.waterSpeed/4)]), count: route.count * 2))
         
         let followLine = SKAction.follow( path, asOffset: false, orientToPath: true, duration: time)
         ship.run(followLine)
         
         routeDebug[de] = route
         
         }
         
         */
    }
    
    
    
    func add(ship:PirateNode){
        ships.append(ship)
        self.addChild(ship)
        adjust(traveler: ship, existing: shipTiles())
        
        if !level.playSound,
            let n = ship.childNode(withName: "seasound") {
            n.removeFromParent()
        }
        
        ship.run(ship.wakeAction(), withKey:"wake")
    }
    
    
    
    func remove(ship:PirateNode){
        ship.removeFromParent()
        ship.removeAction(forKey: "wake")
        ship.removeAction(forKey: "move")
        
        ships = ships.filter({$0 != ship})
        hud.kills += 1
        updateLabels()
        
        self.level.adjustPoints(kind:ship.kind)
        
        
    }
    
    func launchAttack(timeOverTile:Double) {
        
        
        if let (ship,interval) = level.nextShip(),
             let shipPosition =  mapTiles.convert(mappoint:ship.route.start){
            ship.position = shipPosition
            add(ship: ship)
            launchClock.adjust(interval: interval)
            
        } else {
            if let trip = mapTiles.randomRoute(),  let shipPosition =  mapTiles.convert(mappoint:trip.start) {
                
              
                let ship =  level.randomShip( modfier:timeOverTile, route: trip)
                ship.position = shipPosition
                add(ship: ship)
                level.add(ship: ship, at: launchClock.length())
                launchClock.reduce(factor: level.decay)
                
            }
            
        }
        
    }
    
    
    
    func launchVictoryShip(){
        
        let tow = towers.filter({ if let x = $0 as? DefenderTower, x.allowsWin { return true}
            return false })
        
        guard tow.count < 4 else {
            counterShipClock.update()
            return
        }
        
        if let trip = mapTiles.randomRoute(),   let startingPostion =  mapTiles.convert(mappoint: trip.finish) {
            
            
            let victoryShip = DefenderTower(timeOverTile: level.victorySpeed, route: Voyage(start: trip.finish, finish: trip.start))
            
            victoryShip.position = startingPostion
            
            victoryShip.fillColor = ColorUtils.shared.r(152/255.0, g: 104/255.0, b: 31/255.0)
            
            victoryShip.hitsRemain = level.victoryShipStartingLevel()
            level.victoryShipLevel += 2
            
            self.towers.append(victoryShip)
            self.addChild(victoryShip)
            updateLabels()
            
            adjust(traveler: victoryShip,existing: towerTiles())
            
            counterShipClock.adjust(interval: launchClock.length() * 8)
            counterShipClock.update()
            
            
            victoryShip.run(victoryShip.wakeAction(), withKey:"wake")
            victoryShip.setScale(0.3)
            victoryShip.run(SKAction.scale(to: 1, duration: 6))
            
        }
        
    }
    
    
    func launchSandShip(){
        
        if let trip = mapTiles.randomRoute(),   let trollPosition = mapTiles.convert(mappoint: trip.finish) {
            
            let sandShip = SandTower(timeOverTile: 0.25, route: Voyage(start: trip.finish, finish: trip.start))
            
            sandShip.position = trollPosition
            sandShip.fillColor = .blue
            
            self.towers.append(sandShip)
            self.addChild(sandShip)
            updateLabels()
            
            adjust(traveler: sandShip, existing: towerTiles())
            
            sandShip.run(sandShip.wakeAction(), withKey:"wake")
            sandShip.setScale(0.3)
            sandShip.run(SKAction.scale(to: 1, duration: 6))
        }
        
    }
    
    
    
    func launchTeraShip(){
        
        if let trip = mapTiles.randomRoute(),   let trollPosition = mapTiles.convert(mappoint: trip.finish) {
            
            let sandShip = TeraTower(timeOverTile: 0.5, route: Voyage(start: trip.finish, finish: trip.finish))
            
            sandShip.position = trollPosition
            sandShip.fillColor = .green
            
            self.towers.append(sandShip)
            self.addChild(sandShip)
            updateLabels()
            
            adjust(traveler: sandShip,existing: [])
            
            
            sandShip.run(sandShip.wakeAction(), withKey:"wake")
            sandShip.setScale(0.3)
            sandShip.run(SKAction.scale(to: 1, duration: 6))
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
                if !x.isDying {
                    x.die(scene: self, isKill: true)
                }
                remove(ship: x)
                
            }
        }
        
        for boat in self.ships {
            
            if let boatTile = self.tileOf(node: boat), boatTile == shipTile {
                
                if boat != self {
                    killShips.append(boat)
                }
                
                let _ = possibleToSand(at: shipTile)
                
            } else {
                keepShip.append(boat)
            }
        }
        
        self.ships = keepShip
    }
    
    
    func infoOf(node:SKNode)->String?{
        if let n = node  as? PirateNode {
            return "ship \(n.kind) \(n.shipID)"
        }
        
        if let n = node as? TowerNode  {
            return "tower  \(n.towerID)"
        }
        
        return nil
    }
    
    func moveCameraToNeareShip() {
        let launchers = self.towers.flatMap({ $0 as? DefenderTower})
        
        guard var curShip = launchers.first, let dest = mapTiles.voyages.first?.finish else { return }
        
        var bestDist = (mapTiles.map(coordinate: curShip.position) ?? MapPoint.offGrid).distance(manhattan: dest)
        
        for x in launchers {
            
            let curDist = (mapTiles.map(coordinate: x.position) ?? MapPoint.offGrid).distance(manhattan: dest)
            if curDist < bestDist {
                bestDist = curDist
                curShip = x
            }
        }
        
        let cam:SKCameraNode
        if let l = self.camera {
            cam = l
        } else{
            cam = SKCameraNode()
            self.camera = cam
            self.addChild(cam)
        }
        
        cam.position = curShip.position
        let (r,_) = curShip.sailAction(usingTiles:mapTiles, orient:false, existing: [])
        
        if let r = r {
            cam.run(r,withKey:"moveCam")
        }
    }
    
    
    
    func makeCamera()->(SKCameraNode,Bool){
        let cam:SKCameraNode
        let hadCam:Bool
        if let c = self.camera{
            cam = c
            hadCam = false
        } else {
            cam = SKCameraNode()
            self.camera = cam
            self.addChild(cam)
            hadCam = true
            
            for node:SKNode in [hud, shipsKilledLabel, towersRemainingLabel]{
                node.removeFromParent()
                cam.addChild(node)
            }
            
            
        }
        return (cam,hadCam)
    }
    
    func sweep(camera:SKCameraNode, to:CGPoint, time:TimeInterval=1, post:SKAction?=nil){
        
        let act:SKAction
        
        
        
        camera.removeAllActions()
        
        let r = SKAction.move(to: to, duration: time)
        if let p = post {
            act = SKAction.sequence([r,p])
        } else {
            act = r
        }
        camera.run(SKAction.scale(to: 0.7, duration: 3))
        camera.run(act)
        
        if let s = self.listener {
            s.removeAllActions()
            s.run(act)
        }
        
    }
    
    func changeCamera(){
        
        if let x = followingShip {
            
            let (cam,hadCam) = makeCamera()
            
            
            if let nav = x as? Navigatable{
                
                let (rAction, _ )  = nav.sailAction(usingTiles:mapTiles, orient:false, existing: [])
                
                func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
                    let xDist = a.x - b.x
                    let yDist = a.y - b.y
                    return CGFloat(sqrt((xDist * xDist) + (yDist * yDist)))
                }
                
                if hadCam {
                    
                    if distance(cam.position, x.position) < 10 {
                        if let rAction = rAction {
                            cam.run(rAction)
                        }
                    } else {
                        sweep(camera: cam, to: x.position, time: 3, post: rAction)
                    }
                } else {
                    sweep(camera: cam, to: x.position, time: 1, post: rAction)
                }
                
            } else {
                sweep(camera: cam, to: x.position)
            }
        }  else {
            
            if  let c = self.camera, zoomOutOnRedirect {
                c.run(SKAction.scale(to: 1, duration: 0.75))
                
                let p = self.mapTiles.tiles?.position ?? CGPoint(x: self.size.width / 2, y: self.size.height / 2)
                c.run(SKAction.sequence([SKAction.move(to: p , duration: 0.75),SKAction.removeFromParent()]))
                
                for node:SKNode in [hud, shipsKilledLabel, towersRemainingLabel]{
                    node.removeFromParent()
                    self.addChild(node)
                }
                
            }
        }
        
    }
    
    func redirectAllShips(){
        
        let lines = children.filter { if let _ = $0 as? ShipPath {
            return true
            }
            return false
        }
        
        for x in lines {
            x.removeFromParent()
        }
        
        let tow = towerTiles()
        let shi = shipTiles()
        for x in children {
            
            if let boat = x as? Navigatable {
                
                if let _ = boat as? TowerNode {
                    adjust(traveler: boat, existing: tow)
                } else {
                    adjust(traveler: boat, existing: shi)
                }
            }
        }
        
        changeCamera()
        
        
    }
    
    
    func possibleToSand(at point:MapPoint)->Bool{
        
        let k = mapTiles.kind(point: point)
        
        guard k != .pirateBase, k != .homeBase else { return false}
        
        let ships = self.navigatableBoats(at: point)
        guard ships.flatMap({$0 as? TowerNode}).isEmpty else { return false }
        mapTiles.changeTile(at: point, to: .sand)
        
        for trip in mapTiles.voyages {
            if  trip.shortestRoute(map: mapTiles, using: waterSet).count < 2 {
                mapTiles.changeTile(at: point, to: .water)
                return false
            }
        }
        
        return true
    }
    
}

extension GameScene : SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        
        if let _ = contact.bodyA.node as? PirateNode,
            let _  = contact.bodyB.node as? PirateNode {
            //print("\(p1) ship colided with ship \(p2)")
            return
        }
        
        if let _  = contact.bodyA.node as? TowerNode,
            let _ = contact.bodyB.node as? TowerNode {
            // print("\(p1) tower colided with tower \(p2)")
            return
        }
        
        if let p1 = contact.bodyA.node as? TowerNode,
            let p2 = contact.bodyB.node as? PirateNode {
            //print("\(p1) tower colided with ship \(p2)")
            p1.removeAction(forKey: "move")
            p2.removeAction(forKey: "move")
            p1.hit(scene: self)
            p2.hit(scene: self)
            
            // Delay 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                
                [weak p1, weak p2] in
                
                let mytiles = self.towerTiles().union(self.shipTiles())
                if let n = p2 {
                    self.adjust(traveler: n, existing: mytiles)
                }
                if let n = p1 as? Navigatable {
                    self.adjust(traveler: n, existing: mytiles)
                }
            }
            return
        }
        
        if let p1 = contact.bodyA.node as? PirateNode,
            let p2 = contact.bodyB.node as? TowerNode {
            //print("\(p1) ship colided with tower \(p2)")
            p1.removeAction(forKey: "move")
            p2.removeAction(forKey: "move")
            p1.hit(scene: self)
            p2.hit(scene: self)
            
            // Delay 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                
                [weak p1, weak p2] in
                let mytiles = self.towerTiles().union(self.shipTiles())
                
                
                if let n = p1 {
                    self.adjust(traveler: n, existing: mytiles)
                }
                if let n = p2 as? Navigatable {
                    self.adjust(traveler: n, existing: mytiles)
                }
            }
            
            
            return
        }
        
        
        for x in [contact.bodyA.node, contact.bodyB.node]{
            if let target = x as? Fireable {
                target.hit(scene: self)
            } else {
                x?.run(SKAction.removeFromParent())
            }
            
        }
        
    }
}


extension GameScene: TowerPlayerActionDelegate {
    
    func showNextTower(){
        let t:[DefenderTower] = self.towers.filter({ if  let _  = $0 as? DefenderTower{return true}
            return false
        }) as! [DefenderTower]
        
        guard let f = t.first else { return }
        
        if f == self.followingShip {
            
            if t.count > 1 {
                self.followingShip = t[1]
                self.zoomOutOnRedirect = false
                
                changeCamera()
            }
            
        } else {
            self.followingShip = f
            changeCamera()
            
            
        }
        
        
        
        
    }
    
    func didTower(action:TowerPlayerActions){
        switch action {
        case .launchPaver:
            if towersRemaining() > 0 {
                if let t = followingShip as? DefenderTower,
                    let sandShip = t.sandToHome(scene: self){
                    self.towers.append(sandShip)
                    self.addChild(sandShip)
                    updateLabels()
                    adjust(traveler: sandShip, existing: towerTiles())
                } else {
                    launchSandShip()
                }
            }
        case .launchTerra:
            if towersRemaining() > 0 {
                if let t = followingShip as? DefenderTower,
                    let sandShip = t.splitShip(scene: self){
                    self.towers.append(sandShip)
                    self.addChild(sandShip)
                    updateLabels()
                    adjust(traveler: sandShip, existing: [])
                } else {
                    launchTeraShip()
                }
            }
        case .KillAllTowers:
            let removeme = towers
            for x in removeme {
                x.die(scene:self, isKill:true)
            }
        case .showNextShip:
            
            showNextTower()
        case .fasterBoats:
            level.victorySpeed = level.victorySpeed * 0.95
        case .strongerBoats:
            level.victoryShipLevel += 1
        case .exit:
            print("going to exit")
        case .save:
            
            self.level.write(name: GameLevel.defaultName() )
        }
        
    }
}


#if os(iOS) || os(tvOS)
    // Touch-based event handling
    extension GameScene {
        
        func handle(touches: Set<UITouch>){
            
            for t in touches {
                let loc = t.location(in: self)
                beginWith(point: loc)
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
        
        override func keyDown(with event: NSEvent) {
            let m = event.keyCode
            
            
            switch event.keyCode{
            case 0:
                didTower(action:.launchPaver)
            case 1:
                didTower(action:.launchTerra)
            case 2:
                didTower(action:.showNextShip)
                /*
                 let a = TowerAI()
                 a.towerAdd.adjust(interval: 0.3)
                 a.radius = 2
                 self.ai = a
                 */
            case 3:
                self.ai = nil
            default:
                print("code \(m)")
            }
        }
        
    }
#endif




