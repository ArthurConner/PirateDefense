//
//  ShipTableViewController.swift
//  CatLike
//
//  Created by Arthur  on 10/2/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import UIKit




extension UISplitViewController {
    func toggleMasterView() {
        let barButtonItem = self.displayModeButtonItem
        if let action  = barButtonItem.action {
            UIApplication.shared.sendAction(action, to: barButtonItem.target, from: nil, for: nil)
        }
    }
}

class ActionTableViewController: UITableViewController {
    
    
    let boats:[ShipKind] = [.crusier,.galley,.motor,.destroyer,.battle]
    let kinds:[String] = ["Play Game", "Edit Blank"]
    let towerAct:[TowerPlayerActions] = [.launchPaver, .KillAllTowers, .save, .exit ]
    let edititems:[EditorSceneActions] = [.clear, .island , .water , .start, .finish,  .prob, .run , .save, .exit]
    var existing:[String] = []
    
    var isEditor = true
    
    var gameState: GameTypeModes = .unknown {
        didSet {
            reloadList()
            self.tableView.reloadData()
            switch gameState {
            case .tower:
                self.title = "Towers"
            case .ship:
                self.title = "Ships"
            case .unknown:
                self.title = "Get Started"
            case .editor:
                self.title = "Editor"
            }
            if let gc = pushGC {
                gc.didSet(game: self.gameState)
                
            } else  if let split = splitViewController {
                
                if let gc = gameController(){
                    gc.didSet(game: self.gameState)
                }
                
                split.toggleMasterView()
            }        }
    }
    
    weak var pushGC:GameViewController?
    
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
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonIte/Users/arthurc/code/CatLike/CatLike iOS/ShipTableViewController.swiftm = self.editButtonItem
    }
    
    
    func gameController()->GameViewController?{
        
        if let gc = pushGC {return  gc }
        
        if let split = splitViewController {
            let controllers = split.viewControllers
            
            
            if let nav = controllers[controllers.count-1] as? UINavigationController,
                let detailViewController = nav.topViewController as?  GameViewController {
                return detailViewController
            }
            // split.toggleMasterView()
        }
        
        return nil
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        
        return 1
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        
        switch gameState {
        case .tower:
            return towerAct.count
        case .ship:
            return boats.count
        case .unknown:
            return kinds.count + existing.count
        case .editor:
            return edititems.count
        }
    }
    
    
    func configure(cell:UITableViewCell, toBoat kind:ShipKind){
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
            
        case .battle:
            text = "Battleship"
        case .bomber:
            text = "bomber"
        }
        
        
        cell.imageView?.image = UIImage(named:text)
        cell.textLabel?.text = text
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "boatLaunch", for: indexPath)
        
        // Configure the cell...
        
        
        
        switch gameState {
        case .tower:
            let kind = towerAct[indexPath.row]
            cell.imageView?.image = nil
            cell.textLabel?.text = kind.rawValue
        case .ship:
            let kind = boats[indexPath.row]
            configure(cell: cell, toBoat: kind)
        case .editor:
            let ed = edititems[indexPath.row]
            cell.imageView?.image = nil
            cell.textLabel?.text = ed.rawValue
        case .unknown:
            cell.imageView?.image = nil
            if indexPath.row < kinds.count {
                cell.textLabel?.text = kinds[indexPath.row]
            } else {
                cell.textLabel?.text = existing[indexPath.row - kinds.count]
            }
            
        }
        
        
        return cell
    }
    
    func runLevel(name:String){
        self.gameState = .tower
        
        if  let gc = self.gameController()?.myScene as? GameScene  {
            gc.level.nextLevelName = name
            gc.restart()
            //  gc.load(levelName:  name)
        }
        
    }
    func handleUnknownSelect(row:Int){
        
        if row == 0{
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
                runLevel(name: existing[row-2])
            }
            
        }
        
    }
    func handleEditorSelect(row:Int){
        print("picked something")
        if let gc = self.gameController(), let e = gc.myScene as? EditorScene {
            
            let act = edititems[row]
            
            switch act{
                
            case .island, .water, .start, .finish, .clear, .ships, .prob:
                e.gameState = act
            case .run:
                if let name = e.didSave() {
                    runLevel(name: name)
                    
                }
            case .save:
                if let _ = e.didSave() {
                    self.gameState = .unknown
                }
            case .exit:
                self.gameState = .unknown
            }
            
            
        }    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch gameState {
        case .tower:
            //ErrorHandler.handle(.logic, "There aren't any cells for towers")
            let kind = towerAct[indexPath.row]
            if kind == .exit {
                self.gameState = .unknown
            }  else if let gc = self.gameController() {
                gc.didTower(action:kind)
            }
        case .ship:
            let kind = boats[indexPath.row]
            let prox = ShipProxy(kind: kind, shipID: "", position: CGPoint.zero, angle: 0)
            let message = ShipLaunchMessage(ship: prox)
            PirateServiceManager.shared.send(message, kind: .launchShip)
            
        case .unknown:
            handleUnknownSelect(row: indexPath.row)
            
            
        case .editor:
            handleEditorSelect(row: indexPath.row)
            
        }
        
        
        if let _ = pushGC {
            
            if let n = self.navigationController {
                n.popViewController(animated: true)
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let   controller = (segue.destination as! UINavigationController).topViewController as? GameViewController{
                
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
