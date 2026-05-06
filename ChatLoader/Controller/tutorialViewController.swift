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
        
        //NOTE: When using sheetPresentationController and modalPresentationStyle = .pageSheet for a UIViewController, the self.view.safeAreaLayoutGuide.topAnchor does not account for the "prefersGrabberVisible", ie self.view extends to the top of the "presented area"
        //Optionally set the variable "spacer" to a value, however this then applies to landscape layout
        /*
         playerController.view.frame = self.view.frame
        let spacer:CGFloat = 20
        playerController.view.frame = CGRect(x: self.view.frame.origin.x, y: self.view.frame.origin.y + spacer, width: self.view.frame.width, height: self.view.frame.height - spacer)
         */
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        player.play()
    }
}
