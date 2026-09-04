//
//  Helper.swift
//  ChatLoader
//
//  Created by Paul Michael Whiten on 11/2/21.
//

import Foundation
import UIKit
import StoreKit

class Helper {
    
    static var app: Helper = {
        return Helper()
    }()
    
    
    //MARK: variables
    let animationTime: Double = 0.25
    var printToggle: Bool = false
    
    let colorPrimary = UIColor(red: 165.0/255, green: 42.0/255, blue: 213.0/255, alpha: 1) // hex: #a52ad5
    let colorPrimaryCellSelected = UIColor(red: 213.0/255, green: 42.0/255, blue: 176.0/255, alpha: 0.8) // hex: #d52ab0
    
    let colorSecondary = UIColor(red: 90.0/255, green: 213.0/255, blue: 42.0/255, alpha: 1) // hex: #5ad52a
    let colorTertiary = UIColor(red: 213.0/255, green: 139.0/255, blue: 42.0/255, alpha: 1) //hex: #d58b2a
    
    let notificationRawValue = "copyToAppFile"  //used for notification when ChatLoader launched/opened from background via
    let copytoAppURL: String = "copytoAppURL"   //identifier for the URL of imported .zip filesUIActivityViewController/'share'/"Copy to app" from an exported WhatsApp chat .zip file
    let whatsappZipFilePrefix = "WhatsApp Chat - "
    let chatStatusUpdate = "chat_status_update"  //used when cannot distinguish if a message is from a sender or from 'WhatsApp system'; assume that it is a 'WhatsApp system' status update
    
    //directories
    let appDirectory: String = "ChatLoaderPrivateDocuments" //../Library/ChatLoaderPrivateDocuments/
    let importedChatsDirectory: String = "importedChats"    //../Library/ChatLoaderPrivateDocuments/importedChats/
    let tempDirectory: String = "tempDir"     //../Library/ChatLoaderPrivateDocuments/importedChats/tempDir/
    
    //UserDefaults.standard keys
    let keyHasBeenLaunched: String = "hasBeenLaunched"      //first time launch to set initial persistent variables, set in AppDelegate
    let keyVersionNumber: String = "versionNumber"          //incremented on version updates, set in AppDelegate
    let keyTotalChatsLoaded: String = "totalChatsLoaded"    //counter for all-time number of chats loaded; cannot use current number of chats in case of deleted chats, set in AppDelegate, incremented in fileProcessor
    
    let keyInAppPurchase: String = "inAppPurchase"          //"Paid" or "Free"
    let keyHasRated: String = "hasRated"
    
    let keyTutorialShown: String = "tutorialShown"          //tutorial shown once per app instance
    let keyIsLoading: String = "isLoading"                  //global variable to track if WhatsApp chat is being processed
    
    
    //fixed variables, my be changed in subsequent versions
    let freeMessagesToMerge: Int = 4
    let contactEmail: String = "app@gmail.com"
    let upgradeProductIdentifier: String = "paid01"
    let noOutgoingSenderSring: String = "_no outgoing sender_"
    
    
    //attachment types dictionary
    var attachmentTypes: [Int16: String] = [0:"Text message",
                                            1:"Contact",
                                            2:"Location",   //note "Location" messages are not explicitly categorised in fileProcessor
                                            3:"Image",
                                            4:"GIF",
                                            5:"Video",
                                            6:"Voice message",
                                            7:"Document",
                                            8:"Sticker",
                                            
                                            101:"Contact card omitted",
                                            102:"Location", //note "Location" message format the same whether attachmnents are included or not
                                            103:"image omitted",
                                            104:"GIF omitted",
                                            105:"video omitted",
                                            106:"audio omitted",
                                            107:"document omitted",
                                            108:"sticker omitted"]
    
    
    //MARK: date and formatting functions
    func getLocale() -> String {
        return "\((Locale.current as NSLocale).object(forKey: NSLocale.Key.identifier)!)"
    }
    
    
    func getTodayYYYYMMDD() -> String {
        
        let date = Date()
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy-MM-dd"
        
        return formatter.string(from: date)
    }
    
    
    func converNSDateToYYYYMMDD(inputDate: NSDate) -> String {
        
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy-MM-dd"
        
        return formatter.string(from: inputDate as Date)
    }
    
    
    func convertDateSlashToDash(inputDate: String) -> String? {
        
        if inputDate.count == 10 {
            return inputDate.replacingOccurrences(of: "/", with: "-")
        } else {
            return nil
        }
    }
    
    
    func convertDateAsString(_ inputDate:String) -> String {
        
        let inputDateFormatter = DateFormatter()
        inputDateFormatter.dateFormat = "yyyy/MM/dd"
        
        let localeFormatter = DateFormatter()
        localeFormatter.locale = Locale.current
        localeFormatter.dateStyle = .medium
        
        return localeFormatter.string(from: inputDateFormatter.date(from: inputDate)!)
    }
    
    
    func convertDateDashToLocalDate(inputDate: String) -> String {
        
        let inputDateFormatter = DateFormatter()
        inputDateFormatter.dateFormat = "yyyy-MM-dd"
        
        let localeFormatter = DateFormatter()
        localeFormatter.locale = Locale.current
        localeFormatter.dateStyle = .medium
        
        return localeFormatter.string(from: inputDateFormatter.date(from: inputDate)!)
    }
    
    
    func converNSDateToLocalDate(inputDate: NSDate) -> String {
        
        let localeFormatter = DateFormatter()
        localeFormatter.locale = Locale.current
        localeFormatter.dateStyle = .medium
        
        return localeFormatter.string(from: (inputDate as Date))
    }
    
    
    func componentsYYYYMMDD(yyyymmdd:String) -> (yyyy:Int?, mm:Int?, dd:Int?) {
        
        if yyyymmdd.count == 10 {
            
            let yyyy = yyyymmdd.prefix(4)
            let dd = yyyymmdd.suffix(2)
            
            let startmm = yyyymmdd.index(yyyymmdd.startIndex, offsetBy: 5)
            let endmm = yyyymmdd.index(yyyymmdd.endIndex, offsetBy: -3)
            let range4 = startmm..<endmm
            
            let mm = yyyymmdd[range4]
            
            return (Int(yyyy), Int(mm), Int(dd))
        }
        
        return (nil, nil, nil)
    }
    
    
    func formatNumber(number: Int) -> String? {
        
        let numberFormatter = NumberFormatter()
        
        numberFormatter.groupingSeparator = ","
        numberFormatter.groupingSize = 3
        numberFormatter.usesGroupingSeparator = true
        
        return numberFormatter.string(from: NSNumber(value: number))
    }
    
    
    //MARK: directory functions
    func testPrintURLs() {
        
        printToggle = true
        
        var tempURL = documentsDirectoryURL()
        tempURL = libraryDirectoryURL()
        tempURL = defaultTemporaryDirectoryURL()
        tempURL = inboxDirectoryURL()
        tempURL = appDirectoryURL()
        tempURL = importedChatsURL()
        tempURL = tempDirURL()
                
        printToggle = false
        
        if printToggle {
            print("\(tempURL)")
        }
    }
    
    
    func documentsDirectoryURL() -> URL {
        
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        if printToggle {
            print("func documentsDirectoryURL() -> URL {\n\t\(url.path)")
        }
        
        return url
    }
    
    
    func libraryDirectoryURL() -> URL {
/*
        if let docsDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first as URL? {
           print("library private dir: \(docsDir.path)")
        }
*/
        let url = FileManager.default.urls(for: FileManager.SearchPathDirectory.libraryDirectory, in: .userDomainMask).first!
        
        if printToggle {
            print("func libraryDirectoryURL() -> URL {\n\t\(url.path)")
        }
        
        return url
    }
    
    
    func defaultTemporaryDirectoryURL() -> URL {
        
        let url = FileManager.default.temporaryDirectory
        
        if printToggle {
            print("func defaultTemporaryDirectoryURL() -> URL {\n\t\(url.path)")
        }
        
        return url
    }
    
    
    func inboxDirectoryURL() -> URL {
        
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Inbox")// (AppDirectories.Inbox.rawValue) // "Inbox")
        
        if printToggle {
            print("func inboxDirectoryURL() -> URL {\n\t\(url.path)")
        }
        
        return url
    }
    
    
    func appDirectoryURL() -> URL {
        
        //../Library/ChatLoaderPrivateDocuments/
        let url = libraryDirectoryURL().appendingPathComponent(appDirectory)
        
        
        if printToggle {
            print("func appDirectoryURL() -> URL {\n\t\(url.path)")
        }
        
        return url
    }
    
    
    func importedChatsURL() -> URL {
        
        //../Library/ChatLoaderPrivateDocuments/importedChats/
        let url = appDirectoryURL().appendingPathComponent(importedChatsDirectory)
        
        if printToggle {
            print("func importedChatsURL() -> URL {\n\t\(url.path)")
        }
        
        return url
    }
    
    
    func tempDirURL() -> URL {
        
        //../Library/ChatLoaderPrivateDocuments/importedChats/tempDir/
        let url = importedChatsURL().appendingPathComponent(tempDirectory)
        
        if printToggle {
            print("func tempDirURL() -> URL {\n\t\(url.path)")
        }
        
        return url
    }
    
    
    func getChatDirURL(chatID: Int16) -> URL {
        
        return importedChatsURL().appendingPathComponent(formatChatIDToDirectoryName(chatID: Int(chatID)))
    }
    
    
    func getImportedFileURLFromInbox() -> URL? {
        
        var url:URL?
        
        let fileManager = FileManager()
        
        do {
            let fileNames = try fileManager.contentsOfDirectory(atPath: inboxDirectoryURL().path) as [String]?
            
            for fn in fileNames! {
                
                print("filename: \(fn)")
                
                if fn.range(of: ".zip") != nil {
                    print(".zip file found!")
                    url = inboxDirectoryURL().appendingPathComponent(fn)
                }
            }
            
        } catch let error as NSError {
            print("ERROR: Helper.getImportedFileURLFromInbox(): let fileNames = try fileManager.contentsOfDirectory(atPath: inboxDirectoryURL().path) as [String]?\n\t\(error)")
        }
        
        return url
    }
    
    
    func printFilesInbox() {
        
        let fileManager = FileManager()
        
        do {
            let fileNames = try fileManager.contentsOfDirectory(atPath: inboxDirectoryURL().path) as [String]?
            
            for fn in fileNames! {
                
                print("filename: \(fn)")
                
                if fn.range(of: ".zip") != nil {
                    print("found!")
                }
            }
            
        } catch let error as NSError {
            print("ERROR: Helper.printFilesInbox(): let fileNames = try fileManager.contentsOfDirectory(atPath: inboxDirectoryURL().path) as [String]?\n\t\(error)")
        }
    }
    
    
    func formatChatIDToDirectoryName(chatID:Int) -> String {
        //create a 4 digit fileID name
        
        let tempStr = String(String("000" + String(chatID)).suffix(4))
        
        print("Helper:formatChatIDToDirectoryName(chatID:Int) -> \(tempStr)")
        
        return tempStr
    }
    
    
    func sizeOfDirectory(at url: URL) -> String? {
        
        // Prefetch .fileSizeKey to cache values during deep enumeration
        let keys: [URLResourceKey] = [.fileSizeKey, .totalFileAllocatedSizeKey]
        
        // Skip hidden files to match standard OS space calculations
        let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]
        let fileManager = FileManager()
    
        guard let enumerator = fileManager.enumerator(at: url,
                                               includingPropertiesForKeys: keys,
                                               options: options,
                                               errorHandler: nil)
        else {
            return nil
        }
            
        var totalSize: Int64 = 0
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(keys))
                
                // Prefer allocated size on disk; fall back to literal file size
                if let allocatedSize = resourceValues.totalFileAllocatedSize {
                    totalSize += Int64(allocatedSize)
                } else if let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
            } catch {
                // Continue calculating size even if one file fails to read
                continue
            }
        } //for case let fileURL as URL in enumerator
        
        return ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file)
    }
    
    
    //MARK: misc functions
    func isLoading() -> Bool {
        return UserDefaults.standard.bool(forKey: self.keyIsLoading)
    }
    
    
    func setIsLoading(isLoading: Bool) {
        UserDefaults.standard.set(isLoading, forKey: self.keyIsLoading)
        UserDefaults.standard.synchronize()
    }
    
    
    func getNextChatID() -> Int {
        return UserDefaults.standard.integer(forKey: self.keyTotalChatsLoaded) + 1
    }
    
    func incrementChatID() {
        UserDefaults.standard.set(self.getNextChatID(), forKey: self.keyTotalChatsLoaded)
        UserDefaults.standard.synchronize()
    }
    
    func showTutorial(numberOfChats: Int) -> Bool {
        
        if numberOfChats == 0 && UserDefaults.standard.bool(forKey: self.keyTutorialShown) == false {
            UserDefaults.standard.set(true, forKey: self.keyTutorialShown)
            UserDefaults.standard.synchronize()
            
            return true
        }
        
        return false
    }
    
    
    func getAppVersion() -> String {
        
        let version = UserDefaults.standard.string(forKey: self.keyVersionNumber) ?? "0.0"
        let inApp = UserDefaults.standard.string(forKey: self.keyInAppPurchase) ?? "0.0"
        return version + " (\(inApp))"
//        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
    }
    
    
    func canRequestRating() -> Bool {
        return !UserDefaults.standard.bool(forKey: self.keyHasRated)
    }
    
    
    func setHasRated(rated: Bool) {
        UserDefaults.standard.set(rated, forKey: self.keyHasRated)
        UserDefaults.standard.synchronize()
    }
    
}


//MARK: extensions
extension URL {
    /* usage:
        let fileUrl: URL
        print("file size = \(fileUrl.fileSize), \(fileUrl.fileSizeString)")
     */
    
    var attributes: [FileAttributeKey : Any]? {
        do {
            return try FileManager.default.attributesOfItem(atPath: path)
        } catch let error as NSError {
            print("ERROR: Helper.swift: extension URL: var attributes: [FileAttributeKey : Any]?: return try FileManager.default.attributesOfItem(atPath: path)\n\t\(error)")
        }
        return nil
    }
    
    var fileSize: UInt64 {
        return attributes?[.size] as? UInt64 ?? UInt64(0)
    }
    
    var fileSizeString: String {
        return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
    }
    
    var creationDate: Date? {
        return attributes?[.creationDate] as? Date
    }
    
}


extension UIViewController {
    
    func topMostViewController() -> UIViewController {
        
        // If it's a navigation controller, look at the visible one
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController() ?? navigation
        }
        
        // If it's a tab bar controller, look at the selected one
        if let tab = self as? UITabBarController {
            if let selectedTab = tab.selectedViewController {
                return selectedTab.topMostViewController()
            }
            return tab.topMostViewController()
        }
        
        // If it's presenting another view controller, go deeper
        if let presented = self.presentedViewController {
            return presented.topMostViewController()
        }
        
        // Base case: this is the top-most controller
        return self
    }
    
    
    func getTabBarController() -> UITabBarController? {
        //return the top most controller, ie UITabBarController
        
        if let navVC = self.parent as? UINavigationController {
            if let tabVC = navVC.parent as? UITabBarController {
                return tabVC
            }
        }
        
        if let tabVC = self.parent as? UITabBarController {
            return tabVC
        }
        
        return nil
    }
    
    
    func requestRating() {
        
        if !UserDefaults.standard.bool(forKey: Helper.app.keyHasRated) {
            
            // Find a suitable UIWindowScene
            let sceneFromView = self.view.window?.windowScene
            let activeScene = sceneFromView ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
            
            guard let windowScene = activeScene else {
                // If we cannot find a scene, just return silently
                return
            }
            
            if #available(iOS 18.0, *) {
                // StoreKit 2 preferred API on iOS 18+
                AppStore.requestReview(in: windowScene)
            } else {
                // Scene-based legacy StoreKit 1 API on iOS 14–17
                SKStoreReviewController.requestReview(in: windowScene)
            }
            
            Helper.app.setHasRated(rated: true)
        }
    }
    
}


//MARK: protocols
    protocol protocolFileProcessor {
        func processingStarted()
        func updateProgress(percentComplete:Int)
        func processingError(errorMessage: String)
        func processingSaving()
        func processingComplete()
    }


    protocol protocolselectSender {
        func selectedSender(senderName: String)
        func noSelectedSender()
    }
