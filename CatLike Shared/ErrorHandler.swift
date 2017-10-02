//
//  ErrorHandler.swift
//  CatLike
//
//  Created by Arthur  on 10/2/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import Foundation


enum GameErrors : Error {
    case wrongGameState
    case networkIssue
    case logic
}



class ErrorHandler {
    
    
    static  func handle(_ errorKind:GameErrors, _ context:String?) {
        
        let text = context ?? ""
        
        
        if let c = context {
            print(c)
        }
        switch errorKind {
        case .wrongGameState:
            print("oops \(text)")
        case .networkIssue:
            print("networkIssue \(text)")
        case .logic:
            print("something missing \(text)")
        }
    }
    
    
}
