//
//  homeViewController.swift
//  ChatLoader
//
//  Created by Paul Michael Whiten on 11/2/21.
//

import UIKit
import CoreData

class homeViewController: UIViewController, protocolFileProcessor, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    
    //MARK: Class variables
    var openWithURL:URL?                    //set by NSNotification .userInfo?["URLtoProcess"]
    var isLoading:Bool = false              //used to stop two files being loaded at once
    var loadingProgress:chatLoadingAlert?   //object (with UIAlertController) to update loading progress
    var fp:fileProcessor?                   //object to process the imported .zip (_chat.txt) file and save to CoreData
    
    let cellIdentifier = "cellLoadedChat"//
    
    let buttonLoadChatHeight: CGFloat = 40
    let labelTotalChats_MessagesHeight: CGFloat = 30
    
    //CoreData
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var fetchedResultsController:NSFetchedResultsController<Chat> = NSFetchedResultsController()
    
    
    
    //MARK: IBOutlets
    @IBOutlet weak var tableChats: UITableView!
    
    @IBOutlet weak var labelTotalChats: UILabel!
    
    @IBOutlet weak var labelTotalMessages: UILabel!
    
    @IBOutlet weak var buttonLoadChat: UIButton! {
        didSet {
            #if !targetEnvironment(simulator)
            buttonLoadChat.setTitle("How to load a chat file", for: .normal)
            #endif
        }
    }
    
    @IBAction func buttonLoadChatPressed(_ sender: UIButton) {
        
        #if !targetEnvironment(simulator)
            presentTutorial()
        #else
            loadFileForSimulator()
        #endif
    }

    
    //MARK: VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        tableChats.dataSource = self
        tableChats.delegate = self
        tableChats.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        
        addNotifications()
        setFetchedResultsController()
        setupAutolayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateChatStats()
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
                
                if !self.isLoading {
                    //if file is not currently being loaded, dismiss any modal VCs presented by self/pop to root view controller
                    self.dismiss(animated: true)
                    
                    self.loadFileFromURL(fileURL: url)
                    
                } else {
                    //file currenlty being loaded, remove the new URL
                    let fileManager = FileManager()
                    
                    do {
                        try fileManager.removeItem(at: url)
                    } catch let error as NSError {
                        print("ERROR: homeViewController.addNotifications(): try fileManager.removeItem(at: url)\n\t\(error)")
                    }
                }//} else {
            }//if let url = notification.userInfo?["URLtoProcess"] as? URL {
        }
    }
    
    
    func setupAutolayout() {
        
        tableChats.backgroundColor = .systemGray6
        tableChats.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(tableChats)
        
        buttonLoadChat.backgroundColor = .systemGray6
        buttonLoadChat.translatesAutoresizingMaskIntoConstraints = false
        self.view.bringSubviewToFront(buttonLoadChat)
        
        labelTotalChats.backgroundColor = .systemGray6
        labelTotalChats.translatesAutoresizingMaskIntoConstraints = false
        self.view.bringSubviewToFront(labelTotalChats)
        
        labelTotalMessages.backgroundColor = .systemGray6
        labelTotalMessages.translatesAutoresizingMaskIntoConstraints = false
        self.view.bringSubviewToFront(labelTotalMessages)
        
        NSLayoutConstraint.activate([
            
            buttonLoadChat.topAnchor.constraint(equalToSystemSpacingBelow: self.view.safeAreaLayoutGuide.topAnchor, multiplier: 1),
            buttonLoadChat.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            buttonLoadChat.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            buttonLoadChat.heightAnchor.constraint(equalToConstant: buttonLoadChatHeight),
                        
            labelTotalChats.topAnchor.constraint(equalToSystemSpacingBelow: buttonLoadChat.bottomAnchor, multiplier: 1),
            labelTotalChats.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            labelTotalChats.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            labelTotalChats.heightAnchor.constraint(equalToConstant: labelTotalChats_MessagesHeight),
            
            labelTotalMessages.topAnchor.constraint(equalToSystemSpacingBelow: labelTotalChats.bottomAnchor, multiplier: 1),
            labelTotalMessages.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
            labelTotalMessages.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
            labelTotalMessages.heightAnchor.constraint(equalToConstant: labelTotalChats_MessagesHeight),
            
            tableChats.topAnchor.constraint(equalToSystemSpacingBelow:labelTotalMessages.bottomAnchor, multiplier: 1),
            tableChats.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableChats.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableChats.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    
    func loadFileFromURL(fileURL:URL) {
        
        if !isLoading {
            isLoading = true
            
            if getTotalChats() > 0 {
                self.tableChats?.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
            
            //process the .zip file
            fp = fileProcessor(delegate: self, inputFile: fileURL)
            fp!.processExportedFile()
        }
    }
    
    
    func updateChatStats() {

        labelTotalChats.text = "Total chats: \(getTotalChats())"
        labelTotalMessages.text = "Total messages: \(Helper.app.formatNumber(number: getTotalMessages())!)"
    }
    
    
    //iOS simulator - load file on the macOS file system (ie put .zip file in ../Library/ChatLoaderPrivateDocuments/) by assigning openWithURL
    func loadFileForSimulator() {
        //check directory/ChatLoader for .zip files
        
        var chatFileFound:Bool = false
        
        let fileManager = FileManager()
            
        let chatLoaderURL = Helper.app.appDirectoryURL()
        
        do {
            let fileNames = try fileManager.contentsOfDirectory(atPath: chatLoaderURL.path) as [String]?
            
            for fn in fileNames! {
                
                if fn.range(of: ".zip") != nil {
                    
                    openWithURL = nil
                    openWithURL = chatLoaderURL.appendingPathComponent(fn)
                    chatFileFound = true
                    break
                }
            }
            
            
            if chatFileFound {
                loadFileFromURL(fileURL: openWithURL!)
                
            } else {
                print("Place the exported whatsapp chat .zip file in directory:")
                print(chatLoaderURL)
                
                let alertController = UIAlertController(title: ".zip file not found", message: "Place the .zip file in:\n\(chatLoaderURL.path)", preferredStyle: .alert)
                
                let actionOK = UIAlertAction(title: "Copy directory path", style: .default) { (action) in
                    UIPasteboard.general.string = chatLoaderURL.path
                }
                
                alertController.addAction(actionOK)
                
                self.present(alertController, animated: true) {}
            }
            
        } catch let error as NSError {
            print("ERROR: homeViewControllerloadFileForSimulator(): let fileNames = try fileManager.contentsOfDirectory(atPath: chatLoaderURL.path) as [String]?\n\t\(error)")
        }
    }
    
    
    func presentTutorial() {
        
        let vc = tutorialViewController()
//        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "homeViewController") as! homeViewController
        
        if #available(iOS 15.0, *) {
            if let sheet = vc.sheetPresentationController {
                sheet.detents = [.large()]
                
                sheet.prefersGrabberVisible = true
            }
        } else {
            // Fallback on earlier versions
            vc.modalPresentationStyle = .pageSheet
        }
        
        self.present(vc, animated: true, completion: nil)
    }
    
    
    //MARK: UITableview delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections![section].numberOfObjects
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
     
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        let chat = fetchedResultsController.object(at: indexPath)
        
        cell.textLabel?.text = "\(chat.chatID)_\(chat.chatName!)"
        cell.detailTextLabel?.text = "\(chat.chatID)"
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedChat = fetchedResultsController.object(at: indexPath)
        let title = selectedChat.chatName!
        let numberOfMessages = Helper.app.formatNumber(number: getNumberOfMessagesInChat(selectedChat: selectedChat))
        
        let message = "chatID: \(selectedChat.chatID)\ndateLoad: \(Helper.app.converNSDateToLocalDate(inputDate: selectedChat.dateLoad!))\n# of messages: \(numberOfMessages!)\nsenderList:\n\(selectedChat.senderList!)"
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let actionOK = UIAlertAction(title: "OK", style: .default) { (action) in
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        alertController.addAction(actionOK)
        
        self.present(alertController, animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        self.context.delete(self.fetchedResultsController.object(at: indexPath))
    }
    
    
    //MARK: NSFetchedResultsController
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
            
        case .insert:
            //triggered when a loaded chat is saved to the managedObjectContext (from an instance of fileProcessor)
            tableChats?.insertRows(at: [newIndexPath!], with: UITableView.RowAnimation.right)
            
            break
            
        case .delete:
            
            
            do {
                try context.save()
                
                tableChats?.deleteRows(at: [indexPath!], with: UITableView.RowAnimation.left)
                //delete directory!
                
            } catch {
                    print("Error with save: \(error)")
                }
            
            break
            
        default: break
        }
        
        self.updateChatStats()
    }
    
    
    //MARK: CoreData functions
    func setFetchedResultsController() {
        
        context.mergePolicy = NSErrorMergePolicy
        
        let fetchRequest:NSFetchRequest = Chat.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "chatID", ascending: false)]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("ERROR: homeViewController.setFetchedResultsController(): try fetchedResultsController.performFetch()\n\t\(error)")
        }
    }
    
    
    func getTotalMessages() -> Int {
        
        let fetchRequest:NSFetchRequest = Message.fetchRequest()
        
        do {
            let messageResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]
            
            return messageResults.count
            
        } catch let error as NSError {
            print("ERROR: homeViewController.getTotalMessages(): let messageResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]\n\t\(error)")
        }
        
        return 0
    }
    
    
    func getTotalChats() -> Int {
        
        let fetchRequest:NSFetchRequest = Chat.fetchRequest()
        
        do {
            let chatResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Chat]
            
            return chatResults.count
            
        } catch let error as NSError {
            print("ERROR: homeViewController.getTotalChats(): let chatResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Chat]\n\t\(error)")
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
            print("ERROR: homeViewController.getLastChatDate(): let chatResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Chat]\n\t\(error)")
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
            print("ERROR: homeViewController.getLastChatName(): let chatResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Chat]\n\t\(error)")
        }
        
        return ""
    }
    
    func getNumberOfMessagesInChat(selectedChat: Chat) -> Int {
        
        do {
            let fetchRequest2:NSFetchRequest = Message.fetchRequest()
            fetchRequest2.predicate = NSPredicate(format: "fromChat == %@", selectedChat)
            
            let messageResults = try context.fetch(fetchRequest2 as! NSFetchRequest<NSFetchRequestResult>) as! [Message]
            
            return messageResults.count
            
        } catch let error as NSError {
            print("ERROR: homeViewController.getNumberOfMessagesInChat(selectedChat: Chat): let messageResults = try context.fetch(fetchRequest2 as! NSFetchRequest<NSFetchRequestResult>) as! [Message]\n\t\(error)")
            
            return 0
        }
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
            
            self.updateChatStats()
        })
    }
 
}

