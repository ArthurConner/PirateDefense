//
//  HUD.swift
//  CatLike
//
//  Created by Arthur  on 9/25/17.
//  Copyright © 2017 Arthur . All rights reserved.
//

import Foundation
import SpriteKit

enum HUDSettings {
    static let font = "Noteworthy-Bold"
    static let fontSize: CGFloat = 50
}

enum HUDMessages {
    static let tapToStart = "Tap to Start"
    static let win = "You Win!"
    static let lose = "Alas someone made it to the harbor!"
    static let nextLevel = "Tap for Next Level"
    static let playAgain = "Tap to Play Again"
    static let reload = "Continue Previous Game?"
    static let yes = "Yes"
    static let no = "No"
}

class HUD: SKNode {
    
    var timerLabel: SKLabelNode?
    var kills = 0
    var lossString = ""
    
    override init() {
        super.init()
        name = "HUD"
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        timerLabel = childNode(withName: "Timer") as? SKLabelNode
    }
    
    func add(message: String, position: CGPoint,
             fontSize: CGFloat = HUDSettings.fontSize) {
        let label: SKLabelNode
        label = SKLabelNode(fontNamed: HUDSettings.font)
        label.text = message
        label.name = message
        label.zPosition = 100
        addChild(label)
        label.fontSize = fontSize
        label.position = position
    }
    
    func updateTimer(time: Int) {
        let minutes = (time/60) % 60
        let seconds = time % 60
        let timeText = String(format: "%02d:%02d", minutes, seconds)
        timerLabel?.text = timeText
    }
    
    func addTimer(time: Int) {
        guard let scene = scene else { return }
        // 1
        let position = CGPoint(x: 0,
                               y: scene.frame.height/2 - 10)
        add(message: "Timer", position: position, fontSize: 24)
        // 2
        timerLabel = childNode(withName: "Timer") as? SKLabelNode
        timerLabel?.verticalAlignmentMode = .top
        timerLabel?.fontName = "Menlo"
        updateTimer(time: time)
    }
    
    func updateGameState(from: GameState, to: GameState) {
        clearUI(gameState: from)
        updateUI(gameState: to)
    }
    
    private func updateUI(gameState: GameState) {
        // add messages for the new state
        switch gameState {
        case .win:
            add(message: HUDMessages.win, position: .zero)
            add(message: HUDMessages.nextLevel,
                position: CGPoint(x: 0, y: -100))
        case .lose:
            lossString = "\(kills) boats sunk."
            add(message: lossString, position: .zero)
            add(message: HUDMessages.playAgain,
                position: CGPoint(x: 0, y: -100))
        case .start:
            add(message: HUDMessages.tapToStart, position: .zero)
            
            
        case .reload:
            add(message: HUDMessages.reload, position: .zero,
                fontSize: 40)
            add(message: HUDMessages.yes,
                position: CGPoint(x: -140, y: -100))
            add(message: HUDMessages.no,
                position: CGPoint(x: 130, y: -100))
        default:
            break
        }
    }
    
    private func clearUI(gameState: GameState) {
        // clear previous state messages
        switch gameState {
        case .win:
            remove(message: HUDMessages.win)
            remove(message: HUDMessages.nextLevel)
        case .lose:
            remove(message: lossString)
            remove(message: HUDMessages.playAgain)
        case .start:
            remove(message: HUDMessages.tapToStart)
        case .reload:
            remove(message: HUDMessages.reload)
            remove(message: HUDMessages.yes)
            remove(message: HUDMessages.no)
        default:
            break
        }
    }
    
    private func remove(message: String) {
        childNode(withName: message)?.removeFromParent()
    }
}
