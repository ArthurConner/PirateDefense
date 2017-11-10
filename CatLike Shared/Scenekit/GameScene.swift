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
    
    //  var intervalTime:TimeInterval = 5
    //  var lastLaunch:Date = Date.distantPast
    
    var launchClock = PirateClock(5)
    var playableRect = CGRect.zero
    var boatLevel  = 3
    
    let tapClock = PirateClock(0.5)
    
    let counterShipClock = PirateClock(1)
    fileprivate let shipsKilledLabel = SKLabelNode(fontNamed: "Chalkduster")
    fileprivate let towersRemainingLabel = SKLabelNode(fontNamed: "Chalkduster")
    
    fileprivate var towers:[TowerNode] = []
    fileprivate var ships:[PirateNode] = []
    let maxTowers = 7
    
    fileprivate var routeDebug:[String:[MapPoint]] = [:]
    
    
    weak var followingShip:TowerNode?
    
    let playSound = true
    
    var points:Int = 0
    var zoomOutOnRedirect = false
    var ai:TowerAI? = TowerAI()
    var victorySpeed:Double = 1
    var gameState: GameState = .initial {
        didSet {
            hud.updateGameState(from: oldValue, to: gameState)
            
            playSea()
            
            
            
            
            
        }
    }
    
    
    func victoryShipStartingLevel()->Int{
        return boatLevel + points/10
    }
    
    func towerStartingLevel()->Int{
        return 4 + points/10
    }
    
    func playSea() {
        stopSea()
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
        
        if playSound {
            let me = SKAudioNode(fileNamed:"SeaStorm.caf")
            me.name = "backgroundStorm"
            me.autoplayLooped = true
            me.isPositional = true
            me.position = p
            
            me.run(SKAction.changeVolume(to: 0.1, duration: 0.3))
            
            
            self.addChild(me)
            
            
        }
    }
    
    func stopSea(){
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
    
    func navigatableBoats(at point:MapPoint)->[Navigatable]{
        let p1 = self.children.filter({self.tileOf(node: $0) == point})
        return p1.flatMap{$0 as? Navigatable}
        
    }
    
    
    class func newGameScene(numTiles:Int) -> GameScene {
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        
        scene.scaleMode = .aspectFit
        scene.backgroundColor = .orange
        
        #if os(iOS) || os(tvOS)
            
            scene.backgroundColor = UIColor(red: 0, green: 0.33, blue: 0.44, alpha: 1)
            
        #else
            scene.backgroundColor = NSColor(calibratedRed: 0, green: 0.33, blue: 0.44, alpha: 1)
        #endif
        
        
        return scene
    }
    
    
    func clear(){
        for ship in ships {
            ship.removeFromParent()
        }
        for ( tower) in towers {
            tower.removeFromParent()
        }
        
        points = 0
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
        launchClock.floor = 1
        boatLevel = 3
        victorySpeed  = 1
        counterShipClock.adjust(interval:5)
        
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
    
    
    
    
    func setupWorldPhysics() {
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        physicsWorld.contactDelegate = self
    }
    
    func setUpScene() {
        guard let tile  = self.childNode(withName: "//MapTiles") as? SKTileMapNode else { return }
        mapTiles.load(map:tile)
        
        launchClock.floor = 1
        mapTiles.refreshMap()
        gameState = .start
        points = 0
        
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
        
        let dest = SKShapeNode(circleOfRadius:20)
        dest.fillColor = .clear
        dest.position = pos
        self.listener = dest
        self.addChild(dest)
    }
    
    func updateLabels() {
        towersRemainingLabel.text = "Towers Remaining: \(towersRemaining()) Str:\(victoryShipStartingLevel())"
        if towersRemaining() > 0 {
            towersRemainingLabel.fontColor = .white
        } else {
            towersRemainingLabel.text = "No towers left"
            towersRemainingLabel.fontColor = .red
        }
        
        shipsKilledLabel.text = "Ships: \(hud.kills) Points:\(points)"
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
            let ship =  PirateNode.makeShip(kind: shipInfo.ship.kind, modfier:launchClock.length()/8, route:trip)
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
            launchClock.reduce(factor: 0.99)
            launchAttack(timeOverTile:max(2.5,launchClock.length())/8)
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
            tower.hitsRemain = towerStartingLevel()
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
        return  maxTowers - towers.count
    }
    
    
    
}


extension GameScene {
    
    func isDeepIntoGame()->Bool{
        
        return  launchClock.length() < launchClock.floor + 2.1
    }
    
    func adjust(traveler:Navigatable ){
        
        
        guard let ship = traveler as? SKNode else {return}
        
        if let followLine = traveler.sailAction(usingTiles:mapTiles, orient: true) {
            ship.run(followLine,withKey:"move")
            ship.removeAction(forKey: "wake")
            if !isDeepIntoGame() {
                ship.run(traveler.wakeAction(), withKey:"wake")
            } else if let x = ship.childNode(withName: "seasound") {
                x.removeFromParent()
            }
            
        } else {
            ship.removeAction(forKey:"move")
            ship.removeAction(forKey: "wake")
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
        adjust(traveler: ship)
        
        if !playSound,
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
        
        switch ship.kind {
        case .battle:
            points += 6
        case .crusier:
            points += 1
        case .destroyer:
            points += 5
        case .galley:
            points += 2
        case .motor:
            points += 3
        case .row:
            points += 0
            
       
        }
        
    }
    
    func launchAttack(timeOverTile:Double) {
        
        if let trip = mapTiles.randomRoute(),  let shipPosition =  mapTiles.convert(mappoint:trip.start) {
            
            let ship =  randomShip( modfier:timeOverTile, route: trip)
            ship.position = shipPosition
            add(ship: ship)
            
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
            
            
            let victoryShip = DefenderTower(timeOverTile: victorySpeed, route: Voyage(start: trip.finish, finish: trip.start))
            
            victoryShip.position = startingPostion
            
            #if os(iOS) || os(tvOS)
                
                victoryShip.fillColor = .purple
                
            #else
                victoryShip.fillColor = NSColor(calibratedRed: 152/255.0, green: 104/255.0, blue: 31/255.0, alpha: 1)
            #endif
            victoryShip.hitsRemain = victoryShipStartingLevel()
            boatLevel += 2
            
            self.towers.append(victoryShip)
            self.addChild(victoryShip)
            updateLabels()
            
            adjust(traveler: victoryShip)
            
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
            
            adjust(traveler: sandShip)

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
            
            adjust(traveler: sandShip)
            
            
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
        if let r = curShip.sailAction(usingTiles:mapTiles, orient:false){
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
            
            if let nav = x as? Navigatable, let rAction = nav.sailAction(usingTiles:mapTiles, orient:false) {
                
                func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
                    let xDist = a.x - b.x
                    let yDist = a.y - b.y
                    return CGFloat(sqrt((xDist * xDist) + (yDist * yDist)))
                }
                
                if hadCam {
                    
                    if distance(cam.position, x.position) < 10 {
                        cam.run(rAction)
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
        
        for x in children {
            
            if let boat = x as? Navigatable {
                adjust(traveler: boat)
            }
        }
        
        changeCamera()
        
    }
    
    
    func possibleToSand(at point:MapPoint)->Bool{
        
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
        
        
        if let p1 = contact.bodyA.node as? PirateNode,
            let p2 = contact.bodyB.node as? PirateNode {
            //print("\(p1) ship colided with ship \(p2)")
            return
        }
        
        if let p1 = contact.bodyA.node as? TowerNode,
            let p2 = contact.bodyB.node as? TowerNode {
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
                if let n = p2 {
                    self.adjust(traveler: n)
                }
                if let n = p1 as? Navigatable {
                    self.adjust(traveler: n)
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
                if let n = p1 {
                    self.adjust(traveler: n)
                }
                if let n = p2 as? Navigatable {
                    self.adjust(traveler: n)
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
                        adjust(traveler: sandShip)
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
                    adjust(traveler: sandShip)
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
            victorySpeed = victorySpeed * 0.95
        case .strongerBoats:
            boatLevel += 1
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




