//
//  mainTabBarViewController.swift
//  VoiceXporter
//
//  Created by Paul Whiten on 19/7/26.
//

import UIKit
import CoreData

class mainTabBarViewController: UITabBarController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let chatsVC = chatsViewController()
        chatsVC.loadViewIfNeeded()
        let chatsVCNavVC = UINavigationController(rootViewController: chatsVC)  //force load of VC
        chatsVCNavVC.tabBarItem = UITabBarItem(title: "Chats", image: UIImage(systemName: "bubble.left.and.text.bubble.right"), tag: 0)
        
        let helpVC = tutorialViewController()
        let helpVCNavVC = UINavigationController(rootViewController: helpVC)
        helpVCNavVC.tabBarItem = UITabBarItem(title: "Help", image: UIImage(systemName: "questionmark.circle"), tag: 1)
        
        let aboutVC = aboutViewController()
        let aboutVCNavVC = UINavigationController(rootViewController: aboutVC)
        aboutVCNavVC.tabBarItem = UITabBarItem(title: "About", image: UIImage(systemName: "info.circle"), tag: 2)
        
        self.tabBar.tintColor = Helper.app.colorPrimary
        self.viewControllers = [chatsVCNavVC, helpVCNavVC, aboutVCNavVC]
        
        //set starting VC
        self.selectedIndex = chatsVC.startingVC()
        
        //add notification
        setNotifications()
    }
    
    
    func setNotifications() {
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Helper.app.notificationRawValue), object: self.view.window?.windowScene?.delegate, queue: OperationQueue.main) { notification in

            // get the URL from the NSNotification
            if let url = notification.userInfo?[Helper.app.copytoAppURL] as? URL {
                
                if !Helper.app.isLoading() {
                    //if a previous file is *not* currently being loaded
                        
                    //get current view controller and dismiss any presented view controllers
                    if let selectedVC = self.selectedViewController {
                        print("mainTabBarViewController.selectedVC: \(type(of: selectedVC))")
                        
                        if let navVC = selectedVC as? UINavigationController {
                            
                            let visibleVC = navVC.visibleViewController
                            print("mainTabBarViewController.visibleVC: \(type(of: visibleVC!))")
                            
                            visibleVC?.dismiss(animated: false)
                            navVC.popToRootViewController(animated: false)
                            
                        } //if let navigationVC = selectedVC as? UINavigationController
                        else {
                            selectedVC.dismiss(animated: false)
                        }
                    }

                    //move to chatsViewController
                    self.selectedIndex = 0
                    
                    //get the chatsViewController, which is top of the VC navigation stack
                    if let chatsVCNavVC = self.selectedViewController as? UINavigationController {
                        if let chatsVC = chatsVCNavVC.viewControllers.first as? chatsViewController {
                            
                            //allow any VC transition animations to complete
                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Helper.app.animationTime) {
                                chatsVC.loadFileFromURL(fileURL: url)   //this is the *only* place to trigger chatsViewController.loadFileFromURL(fileURL:URL)
                            }
                        } //if let chatsVC = navVC.viewControllers.first as? chatsViewController
                    } //if let navVC = self.selectedViewController as? UINavigationController

                } //if !Helper.app.isLoading()
                else {
                    //a file is currently being loaded, delete the new file
                    
                    let fileManager = FileManager()
                    
                    do {
                        try fileManager.removeItem(at: url)
                        print("mainTabBarViewController.setNotifications()_NotificationCenter.default.addObserver: Helper.app.isLoading() == true: file deleted")
                        
                    } catch let error as NSError {
                        print("ERROR: mainTabBarViewController.setNotifications()_NotificationCenter.default.addObserver: try fileManager.removeItem(at: url)\n\t\(error)")
                    }
                }
                
            } //if let url = notification.userInfo?[Helper.app.copytoAppURL] as? URL
        } //NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Helper.app.notificationRawValue), object: self.view.window?.windowScene?.delegate, queue: OperationQueue.main)
    }
}
