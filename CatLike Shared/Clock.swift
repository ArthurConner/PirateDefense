//
//  Clock.swift
//  CatLike iOS
//
//  Created by Arthur  on 9/27/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import Foundation


class PirateClock{
    
    
    private var time:Date = Date(timeIntervalSinceNow: 0)
    private var interval:TimeInterval = 5
    var enabled = true
    var floor:TimeInterval = 0
    
    func tickNext(){
        time = Date(timeIntervalSinceNow:0)
    }
  
    
    func update(){
        time = Date(timeIntervalSinceNow:interval)
    }
    
    func needsUpdate()->Bool{
        return enabled && time < Date(timeIntervalSinceNow: 0)
        
    }
    
    func length()->TimeInterval{
        return interval
    }
    
    init(_ interval:TimeInterval) {
        self.interval = interval
        //self.expireTime = Date(timeIntervalSinceNow:expireInterval)
        update()
    }
    
    func adjust(interval aI:TimeInterval){
        self.interval = aI
        update()
    }
    
    func reduce(factor:TimeInterval){
        let nextI = self.interval * factor
        if nextI > floor {
            self.interval = nextI
           // print("reducing to \(nextI)")
        }
        update()
    }
    
}

class PirateGun{
    
    let clock:PirateClock
    var flightDuration:Double
    var radius:Int
    var landscapes:Set<Landscape>
    
    init(interval:TimeInterval, flightDuration aRate:Double, radius aRadius:Int) {
        self.clock = PirateClock(interval)
        self.flightDuration = aRate
        self.radius = aRadius
        self.landscapes = []
    }
    
    
}
