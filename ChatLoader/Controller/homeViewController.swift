//
//  ViewController.swift
//  ChatLoader
//
//  Created by Paul Michael Whiten on 11/2/21.
//

import UIKit
import CoreData

class homeViewController: UIViewController, protocolFileProcessor {
    
    //MARK: Class variables
    var openWithURL:URL?                    //set by NSNotification .userInfo?["URLtoProcess"]
    var isLoading:Bool = false              //used to stop two files being loaded at once
    var loadingProgress:chatLoadingAlert?   //object (with UIAlertController) to update loading progress
    var fp:fileProcessor?
    
    //CoreData
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    
    //MARK: IBOutlets
    @IBOutlet weak var labelTotalChats: UILabel!
    
    @IBOutlet weak var labelTotalMessages: UILabel!
    
    @IBOutlet weak var labelLastChatLoadDate: UILabel!
    
    @IBOutlet weak var labelLastChatName: UILabel!
    
    @IBOutlet weak var labelLastChatMessages: UILabel!
    
    @IBOutlet weak var buttonLoadChat: UIButton! {
        didSet {
            #if !targetEnvironment(simulator)
                buttonLoadChat.isHidden = true
            #endif
        }
    }
    
    @IBAction func buttonLoadChatPressed(_ sender: UIButton) {
        if loadFileForSimulator() {
            loadFileFromURL(fileURL: openWithURL!)
        }
    }

    
    //MARK: VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        addNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateChatStats(recentChat: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if openWithURL != nil {
            //ChatLoader launched via UIActivityViewController/'share'/"Copy to app" from an exported Whatsapp chat .zip file
            //openWithURL set in SceneDelegate func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
            
            loadFileFromURL(fileURL: openWithURL!)
        }
        
        Helper.app.testPrintURLs()
    }
    
    
    //MARK: Class functions
    func addNotifications() {
        //ChatLoader opened from background via UIActivityViewController/'share'/"Copy to app" from an exported Whatsapp chat .zip file
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Helper.app.notificationRawValue), object: self.view.window?.windowScene?.delegate, queue: OperationQueue.main) { notification in

            // get the URL from the NSNotification
            if let url = notification.userInfo?["URLtoProcess"] as? URL {
                self.loadFileFromURL(fileURL: url)
                
                //Remove any modal VCs presented by self/pop to root view controller
            }
        }
    }
    
    
    func loadFileFromURL(fileURL:URL) {
        
        if !isLoading {
            isLoading = true
            
            //process the .zip file
            fp = fileProcessor(delegate: self, inputFile: fileURL)
            fp!.processExportedFile()
        }
    }
    
    
    func updateChatStats(recentChat: Bool) {
        
        if recentChat {
            labelLastChatLoadDate.text = "Last chat load date: \(getLastChatDate())"
            labelLastChatName.text = "Last chat name: \(getLastChatName())"
            labelLastChatMessages.text = "Last chat # of messages: \(Helper.app.formatNumber(number: getLastChatMessages())!)"
        }
        
        labelTotalChats.text = "Total chats: \(getTotalChats())"
        labelTotalMessages.text = "Total messages: \(Helper.app.formatNumber(number: getTotalMessages())!)"
    }
    
    
    //iOS simulator - load file manually put on the macOS file system by setting openWithURL
    func loadFileForSimulator() -> Bool {
        //check directory /ChatLoader for .zip files
        
        var chatFileFound:Bool = false
        
        let fileManager = FileManager()
        
        if let libraryDir = FileManager().urls(for: .libraryDirectory, in: .userDomainMask).first as URL? {
            
            let privateDir = UserDefaults.standard.string(forKey: "appDirectory")!
            let chatLoaderURL = libraryDir.appendingPathComponent("\(privateDir)")
            
            do {
                let fileNames = try fileManager.contentsOfDirectory(atPath: chatLoaderURL.path) as [String]?
                
                for fn in fileNames! {
                    
                    if fn.range(of: ".zip") != nil {
                        
                        openWithURL = chatLoaderURL.appendingPathComponent(fn)
                        chatFileFound = true
                        break
                    }
                }
                
                if !chatFileFound {
                    print("Place the exported whatsapp chat .zip file in directory:")
                    print(chatLoaderURL)
                }
                
            } catch let error as NSError {
                print("WARNING: func loadFileForSimulator() { no files found! \(error)")
            }
        }
        
        return chatFileFound
    }
    
    
    //MARK: CoreData functions
    func getTotalMessages() -> Int {
        
        let fetchRequest:NSFetchRequest = Message.fetchRequest()
        
        do {
            let messageResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]
            
            return messageResults.count
            
        } catch let error as NSError {
            print("func getTotalMessages() -> Int { \(error.localizedDescription)")
        }
        
        return 0
    }
    
    
    func getTotalChats() -> Int {
        
        let fetchRequest:NSFetchRequest = Chat.fetchRequest()
        
        do {
            let chatResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Chat]
            
            return chatResults.count
            
        } catch let error as NSError {
            print("func getTotalChats() -> Int { \(error.localizedDescription)")
        }
        
        return 0
    }
    
    
    func getLastChatDate() -> String {
        
        let fetchRequest:NSFetchRequest = Chat.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "chatID", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let chatResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Chat]
            
            if chatResults.count == 1 {
                return Helper.app.converNSDateToLocalDate(inputDate: chatResults.first!.dateLoad!)
            }
            
        } catch let error as NSError {
            print("func getLastChatDate() -> String { \(error.localizedDescription)")
        }
        
        return ""
    }
    
    
    func getLastChatName() -> String {
        
        let fetchRequest:NSFetchRequest = Chat.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "chatID", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let chatResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Chat]
            
            if chatResults.count == 1 {
                let chat = chatResults.first
                
                return chat!.chatName!
            }
            
        } catch let error as NSError {
            print("func getLastChatName() -> String { \(error.localizedDescription)")
        }
        
        return ""
    }
    
    
    func getLastChatMessages() -> Int {
        
        if let lastChat = getLastChat() {
            
            lastChat.printChat()
            
            let fetchRequest:NSFetchRequest = Message.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "fromChat == %@", lastChat)
            
            do {
                let messageResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]
                
//                let tempMessage = messageResults.first
//                let msgID = tempMessage!.messageID
//                print("last msgID: \(msgID)")
                
                return messageResults.count
                
            } catch let error as NSError {
                print("func getLastChatMessages() -> Int { \(error.localizedDescription)")
            }
        }
        
        return 0
    }
    
    
    func getLastChat() -> Chat? {
        
        let fetchRequest:NSFetchRequest = Chat.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "chatID", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let chatResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Chat]
            
            if chatResults.count == 1 {
                return chatResults.first
            }
            
        } catch let error as NSError {
            print("func getLastChat() -> Chat? { \(error.localizedDescription)")
        }
        
        return nil
    }
    
    
    func printAttachmentTypes() {
        let fetchRequest:NSFetchRequest = Message.fetchRequest()
        
        
    }
    
    
    //MARK: protocolFileProcessor
    func processingStarted() {
        //loadingProgress:chatLoadingAlert? to show progress of loading chat
        loadingProgress = chatLoadingAlert()
        
        //UIAlertController (from loadingProgress:chatLoadingAlert?) to show progress of loading chat
        let alert = loadingProgress!.setup()
        self.present(alert, animated: true)
    }
    
    
    func updateProgress(percentComplete:Int) {
        //update loadingProgress:chatLoadingAlert? with loading status
        if loadingProgress != nil {
            loadingProgress!.updateProgresss(progress: percentComplete)
        }
    }
    
    
    func processingError() {
        
        //dismiss the UIAlertController from loadingProgress:chatLoadingAlert?
        self.dismiss(animated: true, completion: {
            
            //reset variables
            self.openWithURL = nil
            self.isLoading = false
            self.loadingProgress = nil
            self.fp = nil
            
            
            //alert the user that there was an error loading the file
            let alertController = UIAlertController(title: "Apologies, I don't recognize the file", message: "Please make sure the region format of the chat history file matches the region settings of your phone (\(Helper.app.getLocale()));\nOr try another chat file", preferredStyle: .alert)
            
            let actionOk = UIAlertAction(title: "Ok", style: .cancel)
            alertController.addAction(actionOk)
            
            self.present(alertController, animated: true) {}
        })
    }
    
    
    func processingSaving() {}
    
    
    func processingComplete() {
        
        //dismiss the UIAlertController from loadingProgress:chatLoadingAlert?
        self.dismiss(animated: true, completion: {
            
            //reset variables
            self.openWithURL = nil
            self.isLoading = false
            self.loadingProgress = nil
            self.fp = nil
            
            self.updateChatStats(recentChat: true)
        })
    }
 
}

