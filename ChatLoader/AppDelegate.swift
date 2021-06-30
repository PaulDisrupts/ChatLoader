//
//  AppDelegate.swift
//  ChatLoader
//
//  Created by Paul Michael Whiten on 11/2/21.
//

import UIKit
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var openWithURL:URL?
    
    //ChatLoader is open in background, lauched via 'share' of exported WhatsApp chat
    func application(_ application: UIApplication, open: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        NSLog("func application(_ application: UIApplication, open: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {")
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "processFile"), object: self, userInfo:["URLtoProcess":open])
        
        return true
    }


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        //ChatLoader lauched via 'share' of exported WhatsApp chat
        if let url = launchOptions?[.url] as? URL {
            self.openWithURL = url
        }
        
        
        if !UserDefaults.standard.bool(forKey: "hasBeenLaunched") {
            //first time ChatLoader has been opened, setup user defaults
            
            UserDefaults.standard.set(true, forKey: "hasBeenLaunched")
            
            UserDefaults.standard.set("0.1", forKey: "versionNumber")
                        
            //directories and files
            UserDefaults.standard.set("ChatLoaderPrivateDocuments", forKey: "appDirectory")
            UserDefaults.standard.set("importedChats", forKey: "importedChatsDirectory")
        }
        
        //create directory structure
        if let docsDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first as URL? {
            print("library private dir: \(docsDir.path)")
            
            //create directory structure
            let fileManager = FileManager()
            
            //"importedChats" directory: each chat has a sub-folder named as chat ID
            let newDir =  docsDir.appendingPathComponent("ChatLoaderPrivateDocuments/importedChats")
            
            if !fileManager.fileExists(atPath: (newDir.path)) {
                
                do {
                    try fileManager.createDirectory(atPath: (newDir.path), withIntermediateDirectories: true, attributes: nil)
                } catch let error as NSError {
                    print("ERROR: try fileManager.createDirectoryAtPath(newDir.path!, withIntermediateDirectories: true, attributes: nil): Failed to create dir at \(String(describing: newDir.path)); error: \(error.localizedDescription)")
                }
            }
        }
        
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "ChatLoader")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

