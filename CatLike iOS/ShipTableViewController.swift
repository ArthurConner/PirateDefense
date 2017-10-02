//
//  ShipTableViewController.swift
//  CatLike
//
//  Created by Arthur  on 10/2/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import UIKit

class ShipTableViewController: UITableViewController {

    
    let boats:[ShipKind] = [.crusier,.galley,.motor,.destroyer,.battle]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
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
        return boats.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "boatLaunch", for: indexPath)

        // Configure the cell...
        
        let kind = boats[indexPath.row]
        
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
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let kind = boats[indexPath.row]
        let prox = ShipProxy(kind: kind, shipID: "", position: CGPoint.zero, angle: 0)
        let message = ShipLaunchMessage(ship: prox)
        PirateServiceManager.shared.send(message, kind: .launchShip)
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
