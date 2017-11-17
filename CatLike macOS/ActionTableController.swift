//
//  ActionTableController.swift
//  CatLike macOS
//
//  Created by Arthur  on 10/13/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import Cocoa



class ActionTableController: NSViewController  {
    
    @IBOutlet weak var tableView: NSTableView!
    
    let isEditor = true
    
    let cellID:NSUserInterfaceItemIdentifier = NSUserInterfaceItemIdentifier(rawValue:"boatLaunch")
    
    func reloadList(){

        existing.removeAll()
        
        do {
            let levels = try FileManager.default.contentsOfDirectory(atPath: GameLevel.rootDir()).filter({$0.hasSuffix("txt")})
            existing.append(contentsOf: levels)
        } catch {
            print("no levels found")
        }
       
    }
    
    override func viewDidLoad() {
        reloadList()
        super.viewDidLoad()
        gameState = .unknown
        // Do view setup here.
    }
    
    
    let boats:[ShipKind] = [.crusier,.galley,.motor,.destroyer,.battle]
    let kinds:[String] = ["Play Random Level","Create new level"]
    let edititems:[EditorSceneActions] = [.clear, .island , .water , .start, .finish, .ships, .run , .save]
    
    var existing:[String] = []
    
    let towerAct:[TowerPlayerActions] = [.launchPaver,.launchTerra, .KillAllTowers, .fasterBoats, .strongerBoats ,.showNextShip, .save, .exit]
    
    var gameState: GameTypeModes = .unknown {
        didSet {
            reloadList()
            self.tableView.reloadData()
            switch gameState {
            case .tower:
                self.title = "Towers"
            case .ship:
                self.title = "Ships"
            case .editor:
                reloadList()
                self.title = "Editing"
            case .unknown:
                self.title = "Get Started"
            }
            
            if let gc = self.gameController() {
                gc.didSet(game:gameState)
            }
            
        }
        
        
    }
    
    
    func gameController()->GameViewController?{
        
        guard let p = self.parent as? NSSplitViewController else { return nil}
        
        for x in p.splitViewItems {
            
            if let ret = x.viewController as? GameViewController {
                return ret
            }
        }
        return nil
        
    }
    
}


extension ActionTableController : NSTableViewDelegate {
    
    
    func configure(cell:NSTableCellView, toBoat kind:ShipKind){
        let text:String
        switch kind {
            
        case .galley:
            text =  "Galley"
        case .row:
            text =  "Row"
        case .crusier:
            text = "Crusier"
        case .destroyer:
            text =  "Destroyer"
        case .motor:
            text =  "Motor"
        case .bomber:
            text = "Bomber"
        case .battle:
            text = "Battleship"
        }
        
        
        cell.imageView?.image = NSImage(named:NSImage.Name(rawValue: text))
        cell.textField?.stringValue = text
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard let cell = tableView.makeView(withIdentifier: self.cellID, owner: nil) as? NSTableCellView else { return nil }

        switch gameState {
        case .tower:
            let kind = towerAct[row]
            cell.imageView?.image = nil
            cell.textField?.stringValue = kind.rawValue
        case .ship:
            let kind = boats[row]
            configure(cell: cell, toBoat: kind)
        case .editor:
            let m = edititems[row]
            cell.imageView?.image = nil
            cell.textField?.stringValue = m.rawValue
        case .unknown:
            cell.imageView?.image = nil
            
            if row < 2 {
            cell.textField?.stringValue = kinds[row]
            } else {
                cell.textField?.stringValue = existing[row-2]
                
            }
        }
        
        
        return cell
        
        
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        guard let row = tableView.selectedRowIndexes.first else { return }
        
        
        switch gameState {
        case .tower:
            let kind = towerAct[row ]
            if kind == .exit {
                self.gameState = .unknown
            } else {
            if let gc = gameController() {
                gc.didTower(action: kind)
            }
        
            }
        case .ship:
            let kind = boats[row]
            let prox = ShipProxy(kind: kind, shipID: "", position: CGPoint.zero, angle: 0)
            let message = ShipLaunchMessage(ship: prox)
            PirateServiceManager.shared.send(message, kind: .launchShip)
        
        case .editor:
            print("picked something")
            if let gc = self.gameController(), let e = gc.myScene as? EditorScene {
                
                let act = edititems[row]
                
                if act != .run, act != .save {
                    e.gameState = act
                } else {
                    if let name = e.didSave() {
                        if act == .run {
                            self.gameState = .tower
                            
                            if  let gc = self.gameController()  {
                                gc.load(levelName:  name)
                            }
                        } else {
                            self.gameState = .unknown
                        }
                        
                        
                    }
                    
                }

          
            }
            
        case .unknown:
            if row == 0 {
                
                self.gameState = .tower
            } else if row == 1 {
                self.gameState = .editor
            } else {
                if isEditor {
                    self.gameState = .editor
                    if let gc = self.gameController(), let e = gc.myScene as? EditorScene {
                        e.load(levelName:  existing[row-2])
                    }
                } else {
                    self.gameState = .tower
                    if  let gc = self.gameController()  {
                    gc.load(levelName:  existing[row-2])
                }
                }
                
            }
        }
        
        
        tableView.deselectAll(nil)

        
    }
}



extension ActionTableController : NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        switch gameState {
        case .tower:
            return  towerAct.count
        case .ship:
            return boats.count
        case .editor:
            return edititems.count
            
        case .unknown:
            return kinds.count + existing.count
            
        }
    }
}
