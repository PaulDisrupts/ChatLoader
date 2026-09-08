//
//  selectSenderViewController.swift
//  ChatLoader
//
//  Created by Paul Whiten on 5/9/26.
//

import UIKit
import CoreData

class selectSenderViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let alertHeight:CGFloat = 324   //default width of UIAlertController (style .alert) in iOS18 is 270 points (iOS26 is 320?); default height (with no buttons) is 64 points; default height with one button is 108.33 points (64 + 44)
    let spacer:CGFloat = 8          //spacer for progressViewLoading:UIProgressView
    let headerHeight: CGFloat = 44  //default button height, used for the UIAlert header
    let pickerHeight: CGFloat = 216          //default UIPickerView height (pre iOS26)
    
    var delegate: protocolDataSelected?
    
    var picker:UIPickerView?
    var pickerSenderList:[String]?
    var selectedSender:String?
    
    var selectButton: UIBarButtonItem?
    
    var senderSelected: Bool = false
    
    //CoreData
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    var selectedChat: Chat?
    
    
    //MARK: view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setup UIPickerView data frist
        if let senderList = selectedChat!.senderList {
            self.setPickerSenderList(senderList: senderList + "\n" + Helper.app.noOutgoingSenderSring)
        }
        
        //add UIPickerView
        picker = UIPickerView()
        picker!.translatesAutoresizingMaskIntoConstraints = false
        picker!.dataSource = self
        picker!.delegate = self
        picker!.selectRow(0, inComponent: 0, animated: false)
        
        self.view.addSubview(picker!)
        
        
        //navigation bar
        selectButton = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(selectSender))
        selectButton!.tintColor = Helper.app.colorPrimary
        
        if #available(iOS 26.0, *) {
            selectButton!.style = .prominent
        }
        
        self.navigationItem.rightBarButtonItems = [selectButton!]
        self.navigationItem.title = "Set outgoing sender"
        self.navigationItem.largeTitleDisplayMode = .never
        
        
        NSLayoutConstraint.activate([
            picker!.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 0),
            picker!.heightAnchor.constraint(equalToConstant: pickerHeight),
            
            picker!.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 2*spacer),
            picker!.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -2*spacer),
        ])
    }
    

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !senderSelected {
            self.delegate?.dismissNoChanges()
        }
    }

    
    //MARK: class functions
    func setPickerSenderList(senderList: String) {
        
        let tempSenders = senderList.components(separatedBy: "\n")
        pickerSenderList = tempSenders
    }
    
    
    @objc func selectSender() {
        
        updateSender(senderName: self.pickerSenderList![self.picker!.selectedRow(inComponent: 0)])
        
        self.dismiss(animated: true, completion: {
            self.delegate?.dismissWithChanges()//this has to execute after the dismiss animation completes to prevent "Attempt to present <UIAlertController: > on <ChatLoader.mainTabBarViewController: > (from <ChatLoader.chatsViewController: >) which is already presenting <UINavigationController: >"
        })
    }
    
    
    //MARK: UIPickerView
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if pickerSenderList != nil {
            
            if selectedSender == nil {
                //send the first value in the picker view to the delegate for saving
                selectedSender = pickerSenderList!.first!
            }
            
            return pickerSenderList!.count
            
        } else {
            return 1
        }
    }
    
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerSenderList![row]
    }
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {}
    
    
    //MARK: core data
    func updateSender(senderName: String) {
        
        let currentOutgoingSender = getOutgoingSender()
        
        senderSelected = true //set here as currentOutgoing sender may be selected
        
        if currentOutgoingSender != senderName || currentOutgoingSender == nil  {
            //outgoing sender to be changed
            
            let fetchRequestOutgoingMessages:NSFetchRequest = Message.fetchRequest()
            fetchRequestOutgoingMessages.predicate = NSPredicate(format: "fromChat == %@ AND outgoing == 1", selectedChat!)
            
            let fetchRequestSelectedSenderMessages:NSFetchRequest = Message.fetchRequest()
            fetchRequestSelectedSenderMessages.predicate = NSPredicate(format: "fromChat == %@ AND sender == %@", selectedChat!, senderName)
            
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
                senderList = selectedChat!.senderList!.components(separatedBy: "\n")
                
                var count = 0
                for sender in senderList {
                    if sender == senderName {
                        senderList.move(fromOffsets: IndexSet(integer: count), toOffset: 0)
                        break
                    }
                    count = count + 1
                }
                
                selectedChat!.senderList = senderList.joined(separator: "\n")
                
                try context.save()
            }
            catch let error as NSError {
                print("selectSenderViewController.updateSender(senderName: String): let results = try context.fetch(fetchRequestSelectedSenderMessages)_let results = try context.fetch(fetchRequestSelectedSenderMessages))_try context.save(): \(error)")
                
                senderSelected = false  //save failed; trigger self.delegate?.dismissNoChanges() in viewWillDisappear(_ animated: Bool)
            }
        } //if currentOutgoingSender != senderName || currentOutgoingSender == nil
    }
    
    
    func getOutgoingSender() -> String? {
        
        let fetchRequest:NSFetchRequest = Message.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "fromChat == %@ AND outgoing == 1", selectedChat!)
        
        do {
            let messageResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]
            
            if messageResults.count > 0 {
                //at least one message set as outgoing, ie. sender already set
                if let outGoingSender = messageResults.first?.sender {
                    return outGoingSender
                }
            }
            
        } catch let error as NSError {
            print("ERROR: selectSenderViewController.getOutgoingSender(): let messageResults = try context.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [Message]\n\t\(error)")
            
            return nil
        }
        
        //no outgoing messages
        return nil
    }
    
}

