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
    let kinds:[String] = ["Play Ship", "Play Tower"]
    let towerAct:[TowerPlayerActions] = [.launchPaver, .KillAllTowers ]
    
    var gameState: GameTypeModes = .unknown {
        didSet {
            self.tableView.reloadData()
            switch gameState {
            case .tower:
                self.title = "Towers"
            case .ship:
                self.title = "Ships"
            case .unknown:
                self.title = "Get Started"
            }
        }
    }
    
     weak var pushGC:GameViewController?
    
    override func viewDidLoad() {
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
        
        switch gameState {
        case .tower:
            return 1
        case .ship:
            return 1
        case .unknown:
            return 1
            
        }
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        
        switch gameState {
        case .tower:
            return towerAct.count
        case .ship:
            return boats.count
        case .unknown:
            return kinds.count
            
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
        case .unknown:
            cell.imageView?.image = nil
            cell.textLabel?.text = kinds[indexPath.row]
            
        }
        
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch gameState {
        case .tower:
            //ErrorHandler.handle(.logic, "There aren't any cells for towers")
            let kind = towerAct[indexPath.row]
            if let gc = self.gameController() {
                gc.didTower(action:kind)
            }
        case .ship:
            let kind = boats[indexPath.row]
            let prox = ShipProxy(kind: kind, shipID: "", position: CGPoint.zero, angle: 0)
            let message = ShipLaunchMessage(ship: prox)
            PirateServiceManager.shared.send(message, kind: .launchShip)
        case .unknown:
            if indexPath.row == 0 {
                
                self.gameState = .ship
            } else {
                self.gameState = .tower
            }
            
            if let gc = pushGC {
                gc.didSet(game: self.gameState)
     
            } else  if let split = splitViewController {
                
                if let gc = gameController(){
                    gc.didSet(game: self.gameState)
                }
              
                split.toggleMasterView()
            }
            
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
        } else {
            print(segue.identifier)
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