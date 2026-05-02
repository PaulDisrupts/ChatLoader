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
    
    let player = AVPlayer(url: Bundle.main.url(forResource: "ChatLoader_export tutorial", withExtension:"mp4")!)
    var playerController = AVPlayerViewController()
    
    
    override func viewDidLoad() {

        super.viewDidLoad()
        
        playerController.player = player
        playerController.view.layer.masksToBounds = true
        self.addChild(playerController)
        self.view.addSubview(playerController.view)
        
        NSLayoutConstraint.activate([
            playerController.view.topAnchor.constraint(equalToSystemSpacingBelow: self.view.safeAreaLayoutGuide.topAnchor, multiplier: 1),
            playerController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            playerController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            playerController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        player.play()
    }
}
