//
//  tutorialViewController.swift
//  ChatLoader
//
//  Created by Paul Whiten on 29/4/26.
//

import Foundation

import UIKit
import AVKit
import AVFoundation

class tutorialViewController: UIViewController {
    
    
    let playerController = AVPlayerViewController()
    let playerItem = AVPlayerItem(url: Bundle.main.url(forResource: "ChatLoader_export tutorial", withExtension:"mp4")!)
    
    var playerQueue: AVQueuePlayer?
    var playerLoop: AVPlayerLooper?
    
    
    //MARK: view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title  = "How to export chats from WhatsApp"
        
        playerQueue = AVQueuePlayer(playerItem: playerItem)
        playerLoop = AVPlayerLooper(player: playerQueue!, templateItem: playerItem)
        
        playerController.player = playerQueue
        playerController.view.layer.masksToBounds = true
        playerController.view.translatesAutoresizingMaskIntoConstraints = false
                
        self.addChild(playerController)
        self.view.addSubview(playerController.view)
                
        NSLayoutConstraint.activate([
            playerController.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),       //pin to bottom of navigation bar title view
            playerController.view.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor), //pin to top tab bar
            playerController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            playerController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        playerQueue!.play()
    }
}
