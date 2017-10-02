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
    
    var notification : Notification.Name  {
        return Notification.Name(rawValue: self.rawValue )
    }
}

struct GameInfo:Codable {
    
    var tileDelta:[MapPoint:Landscape] = [:]
    
    
    
    mutating func clear(){
        tileDelta.removeAll()
    }
}

class GameMessage:NSObject {
    let info:GameInfo
    
    init(info i:GameInfo) {
        
        self.info = i
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
