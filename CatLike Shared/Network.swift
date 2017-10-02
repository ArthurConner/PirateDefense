//
//  Network.swift
//  CatLike
//
//  Created by Arthur  on 10/2/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import Foundation


enum GameNotif:String {
   
    case NeedMap = "GameMessage.needMap"
    case SendingDelta = "GameMessage.SendingDelta"
    case launchShip = "GameMessage.launchShip"
    var notification : Notification.Name  {
        return Notification.Name(rawValue: self.rawValue )
    }
    
    
    var asInt : Int64  {
        switch self {
        case .NeedMap:
            return 1
        case .SendingDelta:
            return 2
        case .launchShip:
            return 3
        }
    }
    
}

func redirectNotification(data:Data) {
    
    
    let myInt:Int64 = 0
    
   // let splitPoint =  data.startIndex.advanced(by: MemoryLayout.size(ofValue: myInt))
    
    guard !(data.isEmpty) else {return }
    
    let splitPoint =  data.startIndex.advanced(by: MemoryLayout.size(ofValue: myInt))
    
    let bdata = data.subdata(in: data.startIndex..<splitPoint)
    let value = bdata.withUnsafeBytes { (ptr: UnsafePointer<Int>) -> Int in
        return ptr.pointee
    }
    
    let ret:GameNotif
    
    switch value {
    case 1:
        ret = .NeedMap
    case 2:
        ret = .SendingDelta
    case 3:
        ret = .launchShip
    default:
        return
    }
    
    
    let edata = data.subdata(in:splitPoint..<data.endIndex)
    print("got a command of size \(edata.count) with code \(ret)")
    
    var obj:NSObject?
    
    switch ret {
    case .NeedMap:
        obj = nil
    case .SendingDelta:
        do {
            let x =  try JSONDecoder().decode(GameMessage.self, from: edata)
                obj = x
        } catch {
            ErrorHandler.handle(.networkIssue, "Did not decode game message")
        }
    case .launchShip:
        
        do {
            let x =  try JSONDecoder().decode(ShipLaunchMessage.self, from: edata)
            obj = x
        } catch {
            ErrorHandler.handle(.networkIssue, "Did not decode game message")
        }
            
        
    }
    
    OperationQueue.main.addOperation {
        NotificationCenter.default.post(name: ret.notification, object: obj)
    }
    
    
    
}
struct GameInfo:Codable {
    
    var tileDelta:[MapPoint:Landscape] = [:]
    var ships:[String:ShipProxy] = [:]
    var towers:[String:TowerProxy] = [:]
    
    var interval = 0.5
    
    mutating func clear(){
        tileDelta.removeAll()
        ships.removeAll()
    }
}

class GameMessage:NSObject, Codable {
    let info:GameInfo
    
    init(info i:GameInfo) {
        
        self.info = i
        super.init()
    }
}

class ShipLaunchMessage:NSObject, Codable {
    let ship:ShipProxy
    
    init(ship i:ShipProxy) {
        
        self.ship = i
        super.init()
    }
    
}


extension MapHandler {
    func load(deltas d:GameInfo){
        for (k, v ) in d.tileDelta {
            self.changeTile(at: k, to: v)
        }
        
    }
}
