//
//  modalTableViewViewController.swift
//  ChatLoader
//
//  Created by Paul Whiten on 7/9/26.
//

import UIKit
import CoreData

class modalTableViewViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    
    
    //MARK: Class variables
    var tableData = UITableView()
    let cellReuseIdentifierAbout = "reuseIdentifier"
    
    var rowTitles: [String] = ["Chat ID:",
                               "Date loaded:",
                               "First message:",
                               "Last message",
                               "# of senders:",
                               "Outgoing sender:",
                               "# of messages:",
                               "Incoming messages:",
                               "Outgoing messages:"]
    
    var rowValues: [String] = []
    
    var selectedChat: Chat?
    
    var delegate: protocolDataSelected?
    
    //CoreData
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    
    //MARK: VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //navigation bar
        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissSelf))
        closeButton.tintColor = Helper.app.colorPrimary
        
        if #available(iOS 26.0, *) {
            closeButton.style = .prominent
        }
        
        self.navigationItem.leftBarButtonItems = [closeButton]
        self.navigationItem.largeTitleDisplayMode = .never
        
        if let selectedChat {
            self.navigationItem.title = selectedChat.chatName
            
            let firstDate = Helper.app.convertDateDashToLocalDate(inputDate: getFirstLastDate(selectedChat: selectedChat, firstDate: true))
            let lastDate = Helper.app.convertDateDashToLocalDate(inputDate: getFirstLastDate(selectedChat: selectedChat, firstDate: false))
            
            var outgoingSender = "Not set"
            
            if let outgoingSenderName = getOutgoingSender(selectedChat: selectedChat) {
                outgoingSender = outgoingSenderName
            }
            
            rowValues += [String(selectedChat.chatID),
                          Helper.app.converNSDateToLocalDate(inputDate: selectedChat.dateLoad!),
                          firstDate,
                          lastDate,
                          String(selectedChat.senderCount),
                          outgoingSender,
                          Helper.app.formatNumber(number: getNumberOfMessagesInChat(selectedChat: selectedChat))!,
                          Helper.app.formatNumber(number: getNumberIncomingOutgoingMessages(selectedChat: selectedChat, outgoing: false))!,
                          Helper.app.formatNumber(number: getNumberIncomingOutgoingMessages(selectedChat: selectedChat, outgoing: true))!
                          ]
            
            
            addAttachmentTypes(selectedChat: selectedChat)
        }
        
        tableData.dataSource = self
        tableData.delegate = self
        tableData.register(aboutTableViewCell.self, forCellReuseIdentifier: cellReuseIdentifierAbout)
        
        tableData.isScrollEnabled = true
        
        tableData.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(tableData)
        
        
        NSLayoutConstraint.activate([
            tableData.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            tableData.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            
            tableData.leadingAnchor.constraint(equalTo: self.view.readableContentGuide.leadingAnchor),
            tableData.trailingAnchor.constraint(equalTo: self.view.readableContentGuide.trailingAnchor),
        ])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.delegate?.dismissNoChanges()
    }
    
    @objc func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: UITableview delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowTitles.count
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
     
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifierAbout, for: indexPath) as? aboutTableViewCell
        else { return UITableViewCell() }
        
        cell.isUserInteractionEnabled = true
                
        cell.setupCellViews(title: rowTitles[indexPath.row], value: rowValues[indexPath.row], action: nil)
        
        return cell
    }
    
    
    
    //MARK: Core Data
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
            
        }
        catch let error as NSError {
            print("ERROR modalTableViewViewController.getFirstLastDate(selectedChat: Chat, firstDate: Bool): \(error)")
        }
        
        return date
    }
    
    
    func getOutgoingSender(selectedChat: Chat) -> String? {
        
        let fetchRequest:NSFetchRequest = Message.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "fromChat == %@ AND outgoing == 1", selectedChat)
        
        do {
            let messageResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]
            
            if messageResults.count > 0 {
                //at least one message set as outgoing, ie. sender already set
                if let outGoingSender = messageResults.first?.sender {
                    return outGoingSender
                }
            }
            
        }
        catch let error as NSError {
            print("ERROR: modalTableViewViewController.getOutgoingSender(selectedChat: Chat): let messageResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]\n\t\(error)")
            
            return nil
        }
        
        //no outgoing messages
        return nil
    }
  
    
    func getNumberOfMessagesInChat(selectedChat: Chat) -> Int {
        
        do {
            let fetchRequest:NSFetchRequest = Message.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "fromChat == %@", selectedChat)
            
            let messageResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]
            
            return messageResults.count
            
        }
        catch let error as NSError {
            print("ERROR: modalTableViewViewController.getNumberOfMessagesInChat(selectedChat: Chat): let messageResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]\n\t\(error)")
            
            return 0
        }
    }
    
    
    func getNumberIncomingOutgoingMessages(selectedChat: Chat, outgoing: Bool) -> Int {
        
        do {
            let fetchRequest:NSFetchRequest = Message.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "fromChat == %@ AND outgoing == %d", selectedChat, outgoing)
            
            let messageResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]
            
            return messageResults.count
            
        }
        catch let error as NSError {
            print("ERROR: modalTableViewViewController.getNumberIncomingOutgoingMessages(selectedChat: Chat, outgoing: Bool): let messageResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]\n\t\(error)")
            
            return 0
        }
    }
    
    func addAttachmentTypes(selectedChat: Chat) {
        
        let fetchRequest:NSFetchRequest = Message.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "fromChat == %@", selectedChat)
        
        let sortDescriptor = NSSortDescriptor(key: "attachmentType", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let fetchedResultsControllerMessages = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                      managedObjectContext: context,
                                                                      sectionNameKeyPath: "attachmentType",
                                                                      cacheName: nil)
        
        //no need to set fetchedResultsControllerMessages.delegate = self
        
        do {
            try fetchedResultsControllerMessages.performFetch()
            
            if let sections = fetchedResultsControllerMessages.sections {
                
                for (_, sectionInfo) in sections.enumerated() {
                    let sectionName = Helper.app.attachmentTypes[Int16(sectionInfo.name)!]!
                    
                    rowTitles += [sectionName+":"]
                    rowValues += [String(sectionInfo.numberOfObjects)]
                }
            }
        }
        catch let error as NSError {
            print("ERROR: modalTableViewViewController.printAttachmentTypes(selectedChat: Chat): try fetchedResultsControllerMessages.performFetch()\n\t\(error)")
            
        }
    }
    
}
