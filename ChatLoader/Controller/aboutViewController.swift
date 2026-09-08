//
//  aboutViewController.swift
//  VoiceXporter
//
//  Created by Paul Whiten on 25/5/26.
//

import CoreData
import UIKit
import AVFoundation
import MessageUI

class aboutViewController: UIViewController, MFMailComposeViewControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var tableAbout = UITableView(frame: .zero, style: .insetGrouped)
    let cellReuseIdentifierAbout = "reuseIdentifier"                //aboutTableViewCell
    let cellReuseIdentifierPrivacy = "privacyCellReuseIdnetifier"   //privacyStatementCell
    
    let spacer: CGFloat = 4
    let privacyRowHeight: CGFloat = 70  //default UILabel height = 21, so 3 and 1/3 times
    
    let sectionHeaders: [String] = ["Get in touch", "App info", "Privacy", "Acknowledgements"]
    
    let tableContent: [[String]] = [
        ["Feedback", "Report a bug", "Tell a friend about ChatLoader"],
        ["ChatLoader version:", "Chats loaded:", "Total messages loaded:"],
        ["Privacy statement --> use textFieldTableViewCell"],
        ["WPZipArchive"]
        ]
    
    let tableEnabledRows: [[Bool]] = [
        [true, true, true],
        [false, false, false, false],
        [true],
        [true],
        ]
    
    let urlLinks: [String] = ["https://github.com/WPMedia/WPZipArchive"]
    
    
    //core data
    var childContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        
    
    //MARK: view contorller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setContext()
        setTableView()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableAbout.reloadData()
        setnavigationBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableAbout.flashScrollIndicators()
    }
    
    
    func setTableView() {
        
        tableAbout.dataSource = self
        tableAbout.delegate = self
        tableAbout.register(aboutTableViewCell.self, forCellReuseIdentifier: cellReuseIdentifierAbout)
        tableAbout.register(textFieldTableViewCell.self, forCellReuseIdentifier: cellReuseIdentifierPrivacy)
        
        tableAbout.isScrollEnabled = true
        
        tableAbout.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(tableAbout)
        
        
        NSLayoutConstraint.activate([
            tableAbout.topAnchor.constraint(equalTo: self.view.topAnchor),
            tableAbout.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            
            tableAbout.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            tableAbout.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
    }
    
    
    func setnavigationBar() {
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.title = "About ChatLoader"
//        self.navigationItem.largeTitleDisplayMode = .always
    }
    
    
    func sendMail(mailTitle: String) {
        
        var productTier = "p"
        if UserDefaults.standard.string(forKey: Helper.app.keyInAppPurchase)! == "Free" {
            productTier = "f"
        }
        
        let versionNumber = Helper.app.getAppVersion()
        let x = UserDefaults.standard.integer(forKey: Helper.app.keyTotalChatsLoaded)
        
        let mailBody:String = "</br></br></br>" + "v\(versionNumber)"
            + "\(productTier).\(x)"
            + "</br>\(Helper.app.getLocale())"
            + "</br>iOS " + UIDevice.current.systemVersion
        
        
        if MFMailComposeViewController.canSendMail() {
            
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([Helper.app.contactEmail])
            mail.setSubject(mailTitle)
            mail.setMessageBody(mailBody, isHTML: true)
            
            present(mail, animated: true, completion: {
                if let selectedRow = self.tableAbout.indexPathForSelectedRow {
                    self.tableAbout.deselectRow(at: selectedRow, animated: true)
                }
            })
        } //if MFMailComposeViewController.canSendMail()
    }
    
    
    //MARK: MFMailComposeViewControllerDelegate
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: (any Error)?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableContent.count
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableContent[section].count
    }
    

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionHeaders[section]
    }

    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifierAbout, for: indexPath) as? aboutTableViewCell
        else { return UITableViewCell() }
        
        cell.isUserInteractionEnabled = tableEnabledRows[indexPath.section][indexPath.row]
        
        
        if indexPath.section == 0 {
            //Get in touch
            
            cell.setupCellViews(title: nil, value: nil, action: tableContent[indexPath.section][indexPath.row])
        }
        else if indexPath.section == 1 {
            //App info
            
            if indexPath.row == 0 {
                cell.setupCellViews(title: tableContent[indexPath.section][indexPath.row], value: Helper.app.getAppVersion(), action: nil)
            } else if indexPath.row == 1 {
                cell.setupCellViews(title: tableContent[indexPath.section][indexPath.row], value: "\(getTotalChats())", action: nil)
            } else if indexPath.row == 2 {
                cell.setupCellViews(title: tableContent[indexPath.section][indexPath.row], value: Helper.app.formatNumber(number: getTotalMessages())!, action: nil)
            }
        }
        else if indexPath.section == 2 {
            //Privacy
            
            guard let privacyStatementCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifierPrivacy, for: indexPath) as? textFieldTableViewCell
            else { return UITableViewCell() }
            
            privacyStatementCell.setupCellViews(title: "ChatLoader's privacy statement",
                                                value: "All chat data used by ChatLoader is stored locally on your device. You can confirm this by using the app offline.\n\nThe app *collects NO data* from your chats – no message content and no personally identifiable information either.\n\nThe exported WhatsApp chat is deleted after it is processed; and only the message content and relevant attachments are saved to the app. This data is stored within the app's private directories as dictated by Apple's app design guidelines.\n\nWhen you delete an imported chat or any other artefact from within the app, it is completely removed from your iPhone.\n\nYou can find out more in ChatLoader's privacy statement.",
                                                action: "https//www.apple.com")
            
            privacyStatementCell.isUserInteractionEnabled = true
            
            return privacyStatementCell
        }
        else {
            //Acknowledgements
            cell.setupCellViews(title: tableContent[indexPath.section][indexPath.row], value: nil, action: tableContent[indexPath.section][indexPath.row])
        }
            
        return cell
    }
    
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableEnabledRows[indexPath.section][indexPath.row] {
            tableAbout.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            
            if indexPath.section == 0 {
                //Get in touch
                
                if indexPath.row == 0 {
                    self.sendMail(mailTitle: "Feedback on VoiceMerge")
                }
                else if indexPath.row == 1 {
                    self.sendMail(mailTitle: "Report a bug with VoiceMerge")
                }
                else if indexPath.row == 2 {
                    //tell a friend
                    
                    let url:URL = URL(string: "https://github.com/PaulDisrupts/ChatLoader.git")!
                    
                    let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    
                    activityViewController.excludedActivityTypes =  [UIActivity.ActivityType.airDrop,
                                                                     UIActivity.ActivityType.postToWeibo,
                                                                     UIActivity.ActivityType.assignToContact,
                                                                     UIActivity.ActivityType.addToReadingList,
                                                                     UIActivity.ActivityType.postToFlickr,
                                                                     UIActivity.ActivityType.postToVimeo,
                                                                     UIActivity.ActivityType.postToTencentWeibo]
                    
                    activityViewController.completionWithItemsHandler = { activity, success, items, error in
                    }
                    
                    present(activityViewController, animated: true, completion: {
                        self.tableAbout.deselectRow(at: indexPath, animated: true)
                    })
                }
                
            } //if indexPath.section == 0
            else if indexPath.section == 3 {
                //Acknowledgements
                
                let urlString = urlLinks[indexPath.row]
                    if let url = URL(string: urlString) {
                        UIApplication.shared.open(url, options: [:], completionHandler: {_ in 
                            self.tableAbout.deselectRow(at: indexPath, animated: true)
                        })
                    }
            } //else if indexPath.section == 3
        } //if tableEnabledRows[indexPath.section][indexPath.row]
    }
    
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) { }
    
    
    //MARK: CoreData
    func setContext() {
        
        childContext.parent = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        childContext.automaticallyMergesChangesFromParent = true
        childContext.mergePolicy = NSErrorMergePolicy
    }
    
    
    func getTotalChats() -> Int {
        
        let fetchRequest:NSFetchRequest = Chat.fetchRequest()
        
        do {
            let results = try childContext.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Chat]
            
            return results.count
            
        }
        catch let error as NSError {
            print("ERROR: aboutViewController.getTotalChats(): let results = try childContext.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Chat]\n\t\(error)")
        }
        
        return 0
    }
    
    
    func getTotalMessages() -> Int {
        
        let fetchRequest:NSFetchRequest = Message.fetchRequest()
        
        do {
            let results = try childContext.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]
            
            return results.count
            
        }
        catch let error as NSError {
            print("ERROR: aboutViewController.getTotalMessages(): let results = try childContext.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]\n\t\(error)")
        }
        
        return 0
    }
    
}
    
