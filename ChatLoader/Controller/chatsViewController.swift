//
//  chatsViewController.swift
//  VoiceXporter
//
//  Created by Paul Whiten on 24/5/26.
//

import UIKit
import CoreData

class chatsViewController: UIViewController, protocolFileProcessor, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, protocolselectSender {
    
    //MARK: Class variables
    var loadingProgress:loadingAlertController?       //UIAlertController subclass to update loading progress
    
    var tutorialShown:Bool = false          //used to show tutorial when # of Chats loaded == 0, only show once per instance of app
    
    var fp:fileProcessor?                   //object to process the imported .zip (_chat.txt) file and save to CoreData
    
    var tableChats = UITableView()
    let cellReuseIdentifier = "reuseIdentifier"
    let estimatedRowHeight:CGFloat = 58         //spacer + labelHeight + spacer + labelHeight + 2*spacer = 4 + 21 + 4 + 21 + 2*4 = 58
    
    let buttonLoadChatHeight: CGFloat = 44      //default iOS button height
    let labelTotalChats_MessagesHeight: CGFloat = 30
    
    //CoreData
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var fetchedResultsController:NSFetchedResultsController<Chat> = NSFetchedResultsController()
    var fetchedResultsControllerMessages:NSFetchedResultsController<Message>?   //used for func printAttachmentTypes(selectedChat: Chat) -> String?
    
    
    //MARK: VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setFetchedResultsController()
        setTableView()
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selectedCell = tableChats.indexPathForSelectedRow {
            tableChats.reloadRows(at: [tableChats.indexPathForSelectedRow!], with: .automatic)
            tableChats.deselectRow(at: selectedCell, animated: true)
        }
        
        updateChatStats(fromDelete: false)
        setNavigationBar()
    }
    

    //MARK: Class functions
    func setTableView() {
        
        tableChats.dataSource = self
        tableChats.delegate = self
        tableChats.register(chatTableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        
        tableChats.backgroundColor = .white
        tableChats.rowHeight = UITableView.automaticDimension
        tableChats.estimatedRowHeight = self.estimatedRowHeight
        
        tableChats.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(tableChats)
        
        NSLayoutConstraint.activate([
            tableChats.topAnchor.constraint(equalTo: self.view.topAnchor), //self.view.safeAreaLayoutGuide.topAnchor causes issues with self.navigationController?.navigationBar.prefersLargeTitles animations
            tableChats.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            
            tableChats.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            tableChats.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
    }
    
    
    func loadFileFromURL(fileURL:URL) {
        
        if !Helper.app.isLoading() {
            Helper.app.setIsLoading(isLoading: true)    //this is the *only* place isLoading can be set to true
            
            //reset tableChats
            if self.tableChats.indexPathForSelectedRow != nil {
                self.tableChats.deselectRow(at: self.tableChats.indexPathForSelectedRow!, animated: true)
            }
            
            if getTotalChats() > 0 {
                self.tableChats.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
            
            //process the .zip file
            fp = fileProcessor(delegate: self, inputFile: fileURL)
        }
        else {
            //a file is currently being loaded, delete the new file
            
            let fileManager = FileManager()
            
            do {
                try fileManager.removeItem(at: fileURL)
            } catch let error as NSError {
                print("ERROR: chatsViewController.loadFileFromURL(fileURL:URL): try fileManager.removeItem(at: url)\n\t\(error)")
            }
        }
    }
    
    
    func updateChatStats(fromDelete: Bool) {

        //if no chats loaded, default to tutorialViewController()
        if fromDelete && Helper.app.showTutorial(numberOfChats: getTotalChats()) {
            //only show tutorial on deleting Chat (tutorial will trigger on launch if no Chats loaded)
            if let tabVC = self.getTabBarController() {
                tabVC.selectedIndex = 1
            }
        }
    }
    
    
    func setNavigationBar() {
        
    #if targetEnvironment(simulator)
        
        let loadChatButton = UIBarButtonItem(title: "Load chat", style: .plain, target: self, action: #selector(self.loadFileForSimulator))
        loadChatButton.tintColor = Helper.app.colorPrimary
        self.navigationItem.rightBarButtonItems = [loadChatButton]
    
    #endif
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
//        self.navigationController?.navigationBar.largeTitleTextAttributes = [.foregroundColor: Helper.app.colorPrimary]

        self.navigationItem.title = "Imported chats"
        
        if #available(iOS 26.0, *) {
            
            let numberChats = getTotalChats()
            
            if numberChats == 0 {
                self.navigationItem.subtitle = "Your loaded chats are stored here"
            } else if numberChats == 1 {
                self.navigationItem.subtitle = "\(String(numberChats)) loaded chat"
            } else {
                self.navigationItem.subtitle = "\(String(numberChats)) loaded chats"
            }
        }
    }
    
    
    func setSender(selectedChatIndex: IndexPath) {
        
        let vc = selectSenderViewController()
        vc.delegate = self
        
        let navVC = UINavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .pageSheet
        
        if #available(iOS 15.0, *) {
            if let sheet = navVC.sheetPresentationController {
                sheet.detents = [.medium()]
                sheet.selectedDetentIdentifier = .medium
                sheet.presentingViewController.isModalInPresentation = true
                sheet.prefersGrabberVisible = false
            }
        }
        
        if let senderList = fetchedResultsController.object(at: selectedChatIndex).senderList {
            vc.setPickerSenderList(senderList: senderList + "\n" + Helper.app.noOutgoingSenderSring)
        }
        
        self.present(navVC, animated: true)
        
        /*
        //this block is to use the UIAlertController format
        let vc = selectSenderAlertController()
        vc.delegate = self
        
        
        if let senderList = fetchedResultsController.object(at: selectedChatIndex).senderList {
         
            /*
             //this block is for Helper.app.noOutgoingSenderSring as the first option; but means it will be top option if user has not set any sender previously
            var finalSenderlist = ""
            
            if (senderList.components(separatedBy: "\n").count == 1 && shouldSetChatOutgoingSender(selectedChatIndex: selectedChatIndex)) ||  shouldSetChatOutgoingSender(selectedChatIndex: selectedChatIndex) {
                //single sender set to incoming
                finalSenderlist = Helper.app.noOutgoingSenderSring + "\n" + senderList
            } else {
                //outgoing sender has been set for chat with > 1 sender; or outgoing sender has been set for chat iwth single sender
                finalSenderlist = senderList + "\n" + Helper.app.noOutgoingSenderSring
            }

            vc.setPickerSenderList(senderList: finalSenderlist)
             */
            
            vc.setPickerSenderList(senderList: senderList + "\n" + Helper.app.noOutgoingSenderSring)
        }
        
        self.present(vc, animated: true)
         */
    }
    
    
    func segueToSelectedChat(selectedChatIndex: IndexPath) {
        
        let selectedChat = fetchedResultsController.object(at: selectedChatIndex)
        
        let firstDate = Helper.app.convertDateDashToLocalDate(inputDate: getFirstLastDate(selectedChat: selectedChat, firstDate: true))
        let lastDate = Helper.app.convertDateDashToLocalDate(inputDate: getFirstLastDate(selectedChat: selectedChat, firstDate: false))
        
        var outgoingSender = "Not set"
        
        if let outgoingSenderName = getOutgoingSender(selectedChatIndex: selectedChatIndex) {
            outgoingSender = outgoingSenderName
        }

        let alertController = UIAlertController(title: selectedChat.chatName!,
                                                message: "Chat ID: \(selectedChat.chatID)\nDate loaded: \(Helper.app.converNSDateToLocalDate(inputDate: selectedChat.dateLoad!))\nFirst message: \(firstDate)\nLast message: \(lastDate)\n# of senders: \(selectedChat.senderCount)\nOutgoing sender: \(outgoingSender)\n# of messages: \(Helper.app.formatNumber(number: getNumberOfMessagesInChat(selectedChat: selectedChat))!)\nIncoming messages: \(Helper.app.formatNumber(number: getNumberIncomingOutgoingMessags(selectedChat: selectedChat, outgoing: false))!)\nOutgoing messages: \(Helper.app.formatNumber(number: getNumberIncomingOutgoingMessags(selectedChat: selectedChat, outgoing: true))!)\n\(printAttachmentTypes(selectedChat: selectedChat)!)",
                                                preferredStyle: .alert)
        
        let actionOK = UIAlertAction(title: "OK", style: .default) { (action) in
            
//            self.tableChats.reloadRows(at: [selectedChatIndex], with: .fade)
            self.tableChats.deselectRow(at: selectedChatIndex, animated: true)
        }
        actionOK.setValue(Helper.app.colorPrimary, forKey: "titleTextColor")
        
        alertController.addAction(actionOK)
        
        self.present(alertController, animated: true, completion: {
            
            if let cell = self.tableChats.cellForRow(at: selectedChatIndex) as? chatTableViewCell {
                cell.updateDirSize(chat: selectedChat)
            }
        })
    }
    
    
    //iOS simulator - load file on the macOS file system (ie put .zip file in ../Library/ChatLoaderPrivateDocuments/) by assigning openWithURL
    @objc func loadFileForSimulator() {
        //check directory/ChatLoader for .zip files
        
        var chatFileFound:Bool = false
        var openWithURL: URL?
        
        let fileManager = FileManager()
            
        let chatLoaderURL = Helper.app.appDirectoryURL()
        
        do {
            let filenames = try fileManager.contentsOfDirectory(atPath: chatLoaderURL.path) as [String]?
            
            for fn in filenames! {
                
                if fn.range(of: ".zip") != nil {
                    
                    openWithURL = nil
                    openWithURL = chatLoaderURL.appendingPathComponent(fn)
                    chatFileFound = true
                    break
                }
            }
            
            
            if chatFileFound && openWithURL != nil {
                loadFileFromURL(fileURL: openWithURL!)
                
            } else {
                print("Place the exported whatsapp chat .zip file in directory:")
                print(chatLoaderURL)
                
                let alertController = UIAlertController(title: ".zip file not found", message: "Place the .zip file in:\n\(chatLoaderURL.path)", preferredStyle: .alert)
                
                let actionOK = UIAlertAction(title: "Copy directory path", style: .default) { (action) in
                    UIPasteboard.general.string = chatLoaderURL.path
                }
                
                actionOK.setValue(Helper.app.colorPrimary, forKey: "titleTextColor")
                alertController.addAction(actionOK)
                
                self.present(alertController, animated: true) {}
            }
            
        } catch let error as NSError {
            print("ERROR: chatsViewControllerloadFileForSimulator(): let filenames = try fileManager.contentsOfDirectory(atPath: chatLoaderURL.path) as [String]?\n\t\(error)")
        }
    }
    
    
    func startingVC() -> Int {
        
        if getTotalChats() > 0 {
            return 0    //chatsViewController
        } else {
            return 1    //tutorialViewController
        }
    }
    

    //MARK: UITableview delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections![section].numberOfObjects
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
     
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as? chatTableViewCell
        else { return UITableViewCell() }
        
        let selectedChat = fetchedResultsController.object(at: indexPath)
                
        cell.setupCellViews(chat: selectedChat, numberMessages: "\(Helper.app.formatNumber(number: getNumberOfMessagesInChat(selectedChat: selectedChat)) ?? "")", directorySize: "")
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
//        countOutgoingMessages(selectedChatIndex: indexPath)
//        countIncomingMessages(selectedChatIndex: indexPath)
        
        if shouldSetChatOutgoingSender(selectedChatIndex: indexPath) {
            setSender(selectedChatIndex: indexPath)
        } else {
            segueToSelectedChat(selectedChatIndex: indexPath)
        }
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            deleteChat(indexPath: indexPath)
        }
    }
    
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
                
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            
            let setOutgoingSenderAction = UIAction(title: "Set outgoing sender", image: UIImage(systemName: "arrow.left.arrow.right")) { action in
                
                self.tableChats.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                self.setSender(selectedChatIndex: indexPath)
            }
            
            let infoAction = UIAction(title: "Info", image: UIImage(systemName: "info.circle")) { action in
                
                self.tableChats.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                self.segueToSelectedChat(selectedChatIndex: indexPath)
            }

            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                self.deleteChat(indexPath: indexPath)
            }
            
            return UIMenu(title: "", children: [setOutgoingSenderAction, infoAction, deleteAction])
        }
    }
    
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
     
        let moreAction = UIContextualAction(style: .normal, title: nil) { (action, view, handler) in
            
            self.tableChats.setEditing(false, animated: true)
            self.showContextMenu(indexPath: indexPath)
        }
        moreAction.image = UIImage(systemName: "ellipsis.circle")
        
        
        let infoAction = UIContextualAction(style: .normal, title: nil) { (action, view, handler) in
            
            self.tableChats.setEditing(false, animated: true)
            self.tableChats.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            self.segueToSelectedChat(selectedChatIndex: indexPath)
        }
        infoAction.image = UIImage(systemName: "info.circle")
        infoAction.backgroundColor = Helper.app.colorPrimary
        
        
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { (action, view, handler) in
            self.deleteChat(indexPath: indexPath)
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        var configuration:UISwipeActionsConfiguration?
//        configuration = UISwipeActionsConfiguration(actions: [deleteAction, infoAction, moreAction])
        configuration = UISwipeActionsConfiguration(actions: [deleteAction, infoAction])
        configuration!.performsFirstActionWithFullSwipe = true
        
        return configuration
    }
    
    
    func showContextMenu(indexPath: IndexPath) {
        
        //documentation - cannot programatically trigger contextMenuConfigurationForRowAt?
        /*
        // 1. Get the cell for the specified row
        guard let cell = self.tableChats.cellForRow(at: indexPath) else { return }
            
            // 2. Find the context menu interaction attached to the cell
            let contextMenuInteraction = cell.interactions.compactMap { $0 as? UIContextMenuInteraction }.first
            
            // 3. Manually present the menu
            contextMenuInteraction?.
         */
    }
    
    
    func deleteChat(indexPath: IndexPath) {
        
        //1. delete the chat's directory first
        do {
            try FileManager().removeItem(at: Helper.app.getChatDirURL(chatID: fetchedResultsController.object(at: indexPath).chatID))
        } catch {
            print("ERROR: chatsViewController.tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath): try FileManager().removeItem(at: Helper.app.getChatDirURL(chatID: deletedChat.chatID))\n\t\(error)")
        }
        
        //2. delete the chat from the managedObjectContext
        self.context.delete(self.fetchedResultsController.object(at: indexPath))
        
        do {
            try context.save()  //3. trigger the NSFetchedResultsController
            
            setNavigationBar()
            updateChatStats(fromDelete: true)
            
        } catch {
            print("ERROR: chatsViewController.controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?): try context.save()\n\t\(error)")
        }
    }
    
    
    //MARK: NSFetchedResultsController
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        self.tableChats.beginUpdates()
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        self.tableChats.endUpdates()
    }

    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
            
        case .insert:
            //triggered when a loaded chat is saved to the managedObjectContext (from fileProcessor.saveContexts())
            tableChats.insertRows(at: [newIndexPath!], with: UITableView.RowAnimation.right)
            
            setNavigationBar()
            
            break
            
        case .delete:
            //3. trigger the NSFetchedResultsController: triggered when a chat is deleted from the managedObjectContext and then the managedObjectContext is saved (from chatsViewController.deleteChat(indexPath: IndexPath))
            tableChats.deleteRows(at: [indexPath!], with: UITableView.RowAnimation.left)
            
            break
            
        default: break
        }
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
            print("ERROR: chatsViewController.setFetchedResultsController(): try fetchedResultsController.performFetch()\n\t\(error)")
        }
    }
    
    
    func getTotalMessages() -> Int {
        
        let fetchRequest:NSFetchRequest = Message.fetchRequest()
        
        do {
            let messageResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]
            
            return messageResults.count
            
        } catch let error as NSError {
            print("ERROR: chatsViewController.getTotalMessages(): let messageResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]\n\t\(error)")
        }
        
        return 0
    }
    
    
    func getTotalChats() -> Int {
        
        let fetchRequest:NSFetchRequest = Chat.fetchRequest()
        
        do {
            let chatResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Chat]
            
            return chatResults.count
            
        } catch let error as NSError {
            print("ERROR: chatsViewController.getTotalChats(): let chatResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Chat]\n\t\(error)")
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
            print("ERROR: chatsViewController.getLastChatDate(): let chatResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Chat]\n\t\(error)")
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
            print("ERROR: chatsViewController.getLastChatName(): let chatResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Chat]\n\t\(error)")
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
            print("ERROR: chatsViewController.getNumberOfMessagesInChat(selectedChat: Chat): let messageResults = try context.fetch(fetchRequest2 as! NSFetchRequest<NSFetchRequestResult>) as! [Message]\n\t\(error)")
            
            return 0
        }
    }
    
    
    func getFirstLastDate(selectedChat: Chat, firstDate: Bool) -> String {
        
        //first message date
        let fetchRequest:NSFetchRequest = Message.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "fromChat == %@", selectedChat)
        fetchRequest.fetchLimit = 1
        
        if firstDate {
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "messageID", ascending: true)]
        } else {
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "messageID", ascending: false)]
        }
        
        var date = ""
        
        do {
            let messageResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]
            
            date = Helper.app.convertDateSlashToDash(inputDate: messageResults.first!.dateSend!)!
            
        } catch let error as NSError {
            print("ERROR func getFirstLastDate(selectedChat: Chat) -> (firstDate: String?, lastDate: String?) {: \(error.localizedDescription)")
        }
        
        return date
    }
    
    
    func getNumberIncomingOutgoingMessags(selectedChat: Chat, outgoing: Bool) -> Int {
        
        do {
            let fetchRequest2:NSFetchRequest = Message.fetchRequest()
            fetchRequest2.predicate = NSPredicate(format: "fromChat == %@ AND outgoing == %d", selectedChat, outgoing)
            
            let messageResults = try context.fetch(fetchRequest2 as! NSFetchRequest<NSFetchRequestResult>) as! [Message]
            
            return messageResults.count
            
        } catch let error as NSError {
            print("ERROR: chatsViewController.getNumberOfMessagesInChat(selectedChat: Chat): let messageResults = try context.fetch(fetchRequest2 as! NSFetchRequest<NSFetchRequestResult>) as! [Message]\n\t\(error)")
            
            return 0
        }
    }
    
    
    func printAttachmentTypes(selectedChat: Chat) -> String? {
        
        let fetchRequest:NSFetchRequest = Message.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "fromChat == %@", selectedChat)
        
        let sortDescriptor = NSSortDescriptor(key: "attachmentType", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsControllerMessages = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                      managedObjectContext: context,
                                                                      sectionNameKeyPath: "attachmentType",
                                                                      cacheName: nil)
        
        // do *not* set fetchedResultsControllerMessages.delegate = self; will cause issues with .delete
        
        var attachmentTypes:String?
        
        do {
            try fetchedResultsControllerMessages!.performFetch()
            
            if let sections = fetchedResultsControllerMessages!.sections {
                
                attachmentTypes = ""
                
                for (_, sectionInfo) in sections.enumerated() {
                    let sectionName = Helper.app.attachmentTypes[Int16(sectionInfo.name)!]!
                    print("Attachment type: \(sectionName): \(sectionInfo.numberOfObjects)")
                    
                    attachmentTypes = attachmentTypes! + "\(sectionName): \(sectionInfo.numberOfObjects)\n"
                }
            }
        } catch let error as NSError {
            print("ERROR: homeViewController.printAttachmentTypes(selectedChat: Chat): try fetchedResultsControllerMessages.performFetch()\n\t\(error)")
            
        }
        
        fetchedResultsControllerMessages = nil
        
        return attachmentTypes
    }
    
    
    func shouldSetChatOutgoingSender(selectedChatIndex: IndexPath) -> Bool {
        
        let chat = fetchedResultsController.object(at: selectedChatIndex)
        
        
        let fetchRequest:NSFetchRequest = Message.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "fromChat == %@ AND outgoing == 1", chat)
        
        do {
            let messageResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]
            
            if messageResults.count > 0 {
                //at least one message set as outgoing, ie. sender already set
                return false
            } else {
                return true
            }
            
        } catch let error as NSError {
            print("ERROR: chatsViewController.getTotalMessages(): let messageResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]\n\t\(error)")
            
            return true
        }
    }     
       
    
    
    func getOutgoingSender(selectedChatIndex: IndexPath) -> String? {
        
        let chat = fetchedResultsController.object(at: selectedChatIndex)
        
        let fetchRequest:NSFetchRequest = Message.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "fromChat == %@ AND outgoing == 1", chat)
        
        do {
            let messageResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]
            
            if messageResults.count > 0 {
                //at least one message set as outgoing, ie. sender already set
                if let outGoingSender = messageResults.first?.sender {
                    return outGoingSender
                }
            }
            
        } catch let error as NSError {
            print("ERROR: chatsViewController.getOutgoingSender(selectedChatIndex: IndexPath): let messageResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]\n\t\(error)")
            
            return nil
        }
        
        //no outgoing messages
        return nil
    }
    
    
    func countOutgoingMessages(selectedChatIndex: IndexPath) {
        
        let fetchRequest:NSFetchRequest = Message.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "fromChat == %@ AND outgoing == 1", fetchedResultsController.object(at: selectedChatIndex))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "messageID", ascending: true)]
        
        do {
            let messageResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]
            
            for message in messageResults {
                print("\t\(message.messageID)")
            }
            
        } catch let error as NSError {
            print("ERROR: chatsViewController.getTotalMessages(): let messageResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]\n\t\(error)")
        }
    }
    
    
    func countIncomingMessages(selectedChatIndex: IndexPath) {
        let fetchRequest:NSFetchRequest = Message.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "fromChat == %@ AND outgoing == 0", fetchedResultsController.object(at: selectedChatIndex))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "messageID", ascending: true)]
        
        
        do {
            let messageResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]
            
            print("****incoming messages: \(messageResults.count)")
            for message in messageResults {
                print("\t\(message.messageID)")
            }
            
        } catch let error as NSError {
            print("ERROR: chatsViewController.getTotalMessages(): let messageResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]\n\t\(error)")
        }
        
    }
    
         
    func updateSender(senderName: String) {
        
        guard let indexPath = tableChats.indexPathForSelectedRow else { return }
        
        let currentOutgoingSender = getOutgoingSender(selectedChatIndex: indexPath)
        
        if currentOutgoingSender != senderName || currentOutgoingSender == nil  {
            //outgoing sender to be changed
            
            let selectedChat = fetchedResultsController.object(at: indexPath)
            
            let fetchRequestOutgoingMessages:NSFetchRequest = Message.fetchRequest()
            fetchRequestOutgoingMessages.predicate = NSPredicate(format: "fromChat == %@ AND outgoing == 1", selectedChat)
            
            let fetchRequestSelectedSenderMessages:NSFetchRequest = Message.fetchRequest()
            fetchRequestSelectedSenderMessages.predicate = NSPredicate(format: "fromChat == %@ AND sender == %@", selectedChat, senderName)
            
            do {
                //reset outgoing messages to incoming/false
                let outgoingMessages = try context.fetch(fetchRequestOutgoingMessages)
                
                if outgoingMessages.count > 0 {
                    for msg in outgoingMessages {
                        msg.outgoing = false
                        print("updated message to incoming: \(msg.messageID)")
                    }
                }
                
                //set new sender messages to outgoing
                if senderName != Helper.app.noOutgoingSenderSring {
                    
                    let results = try context.fetch(fetchRequestSelectedSenderMessages)
                    
                    for msg in results {
                        msg.outgoing = true
                        print("updated message to outgoing: \(msg.messageID)")
                    }
                }
                
                //update the outgoing sender to the first item in the sender list
                var senderList: [String] = []
                senderList = selectedChat.senderList!.components(separatedBy: "\n")
                
                var count = 0
                for sender in senderList {
                    if sender == senderName {
                        senderList.move(fromOffsets: IndexSet(integer: count), toOffset: 0)
                        break
                    }
                    count = count + 1
                }
                
                selectedChat.senderList = senderList.joined(separator: "\n")
                
                try context.save()
            }
            catch {
                print("Failed to fetch or save: \(error.localizedDescription)")
            }
        } //if currentOutgoingSender != senderName || currentOutgoingSender == nil
    }
    
    
    //MARK: protocolFileProcessor
    func processingStarted() {
        
        //loadingAlertController to show progress of loading chat
        loadingProgress = loadingAlertController()
        self.present(loadingProgress!, animated: true)
    }
    
    
    func updateProgress(percentComplete:Int) {
        //update loadingProgress:loadingAlertController? with loading status
        if loadingProgress != nil {
            loadingProgress!.updateProgresss(progress: percentComplete)
        }
    }
    
    
    func processingError(errorMessage: String) {
        
        //dismiss the UIAlertController from loadingProgress:loadingAlertController?
        self.dismiss(animated: true, completion: {
            
            //reset variables
            Helper.app.setIsLoading(isLoading: false)
            self.loadingProgress = nil
            self.fp = nil
            
            
            //alert the user that there was an error loading the file
            let alertController = UIAlertController(title: "Apologies, I don't recognize the file", message: "Please make sure the region format of the chat history file matches the region settings of your phone (\(Helper.app.getLocale()));\nOr try another chat file\nError: \(errorMessage)", preferredStyle: .alert)
            
            let actionOK = UIAlertAction(title: "Ok", style: .cancel)
            actionOK.setValue(Helper.app.colorPrimary, forKey: "titleTextColor")
            
            alertController.addAction(actionOK)
            
            self.present(alertController, animated: true) {}
        })
    }
    
    
    func processingSaving() {}
    
    
    func processingComplete() {
        
        //dismiss the UIAlertController from loadingProgress:loadingAlertController?
        self.dismiss(animated: true, completion: {
            
            //reset variables
            Helper.app.setIsLoading(isLoading: false)
            self.loadingProgress = nil
            self.fp = nil
            
            self.updateChatStats(fromDelete: false)
            
            
            let firstIndexPath = IndexPath(row: 0, section: 0)
            
            self.tableChats.selectRow(at: firstIndexPath, animated: true, scrollPosition: .top)
            
            if self.shouldSetChatOutgoingSender(selectedChatIndex: firstIndexPath) {
                self.setSender(selectedChatIndex: firstIndexPath)
            } else {
                self.segueToSelectedChat(selectedChatIndex: firstIndexPath)
            }
        })
    }
 
    
    //MARK: protocolselectSender
    func selectedSender(senderName: String) {
            
        print("senderName: \(senderName)")
        
        //update context
        updateSender(senderName: senderName)
        
        //action once chat is selected and sender updated
        if let selectedRow = tableChats.indexPathForSelectedRow {
            segueToSelectedChat(selectedChatIndex: selectedRow)
        }
    }
    
    
    func noSelectedSender() {
        if let selectedRow = tableChats.indexPathForSelectedRow {
            tableChats.deselectRow(at: selectedRow, animated: true)
        }
    }
    
}

