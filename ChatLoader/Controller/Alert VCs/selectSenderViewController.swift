//
//  selectSenderViewController.swift
//  ChatLoader
//
//  Created by Paul Whiten on 5/9/26.
//

import UIKit

class selectSenderViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let alertHeight:CGFloat = 324   //default width of UIAlertController (style .alert) in iOS18 is 270 points (iOS26 is 320?); default height (with no buttons) is 64 points; default height with one button is 108.33 points (64 + 44)
    let spacer:CGFloat = 8          //spacer for progressViewLoading:UIProgressView
    let headerHeight: CGFloat = 44  //default button height, used for the UIAlert header
    let pickerHeight: CGFloat = 216          //default UIPickerView height (pre iOS26)
    
    var delegate: protocolselectSender?
    
    var picker:UIPickerView?
    var pickerSenderList:[String]?
    var selectedSender:String?
    
    var selectButton: UIBarButtonItem?
    
    var senderSelected: Bool = false
    
    
    //MARK: view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add UIPickerView
        picker = UIPickerView()
        picker!.translatesAutoresizingMaskIntoConstraints = false
        picker!.dataSource = self
        picker!.delegate = self
        
        //update UIPicker to the correct size option
        picker!.selectRow(0, inComponent: 0, animated: false)
        
        self.view.addSubview(picker!)
        
        
        //navigation bar
        selectButton = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(selectSender))
        selectButton!.tintColor = Helper.app.colorPrimary
        
        self.navigationItem.rightBarButtonItems = [selectButton!]
        self.navigationItem.title = "Set outgoing sender"
        self.navigationItem.largeTitleDisplayMode = .never
        
        
        NSLayoutConstraint.activate([
            picker!.topAnchor.constraint(equalTo: self.view.topAnchor, constant: headerHeight + spacer),
            picker!.heightAnchor.constraint(equalToConstant: pickerHeight),
            
            picker!.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 2*spacer),
            picker!.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -2*spacer),
        ])
    }
    

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !senderSelected {
            self.delegate?.noSelectedSender()
        }
    }

    
    //MARK: class functions
    func setPickerSenderList(senderList: String) {
        
        let tempSenders = senderList.components(separatedBy: "\n")
        pickerSenderList = tempSenders
    }
    
    
    @objc func selectSender() {
        
        senderSelected = true
        
        self.dismiss(animated: true, completion: {
            self.delegate?.selectedSender(senderName: self.pickerSenderList![self.picker!.selectedRow(inComponent: 0)]) //this has to execute after the dismiss animation completes to prevent "Attempt to present <UIAlertController: > on <ChatLoader.mainTabBarViewController: > (from <ChatLoader.chatsViewController: >) which is already presenting <UINavigationController: >"
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
}

