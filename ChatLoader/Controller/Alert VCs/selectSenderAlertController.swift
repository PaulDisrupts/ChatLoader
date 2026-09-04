//
//  selectSenderAlertController.swift
//  VoiceXporter
//
//  Created by Paul Whiten on 30/5/26.
//

import UIKit


class selectSenderAlertController: UIAlertController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let alertHeight:CGFloat = 324   //default width of UIAlertController (style .alert) in iOS18 is 270 points (iOS26 is 320?); default height (with no buttons) is 64 points; default height with one button is 108.33 points (64 + 44)
    let spacer:CGFloat = 8          //spacer for progressViewLoading:UIProgressView
    let headerHeight: CGFloat = 44  //default button height, used for the UIAlert header
    let pickerHeight: CGFloat = 216          //default UIPickerView height (pre iOS26)
    
    var delegate: protocolselectSender?
    
    var picker:UIPickerView?
    var pickerSenderList:[String]?
    var selectedSender:String?
    
    
    //MARK: view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize)]
        let attributedTitle = NSMutableAttributedString(string: "Set outgoing sender:", attributes: attributes)
        self.setValue(attributedTitle, forKey: "attributedTitle")
        
        //update height constraint
        let constraintHeight = NSLayoutConstraint(
            item: self.view!,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1,
            constant: alertHeight
        )
        self.view.addConstraint(constraintHeight)

         
        //add UIPickerView
        picker = UIPickerView()
        picker!.translatesAutoresizingMaskIntoConstraints = false
        picker!.dataSource = self
        picker!.delegate = self
        
        //update UIPicker to the correct size option
        picker!.selectRow(0, inComponent: 0, animated: false)
        
        self.view.addSubview(picker!)
        
        
        let actionOK = UIAlertAction(title: "OK", style: .cancel) { (action) in
            self.delegate?.selectedSender(senderName: self.pickerSenderList![self.picker!.selectedRow(inComponent: 0)])
        }
        actionOK.setValue(Helper.app.colorPrimary, forKey: "titleTextColor")
        self.addAction(actionOK)
        
        
        NSLayoutConstraint.activate([
            picker!.topAnchor.constraint(equalTo: self.view.topAnchor, constant: headerHeight),
            picker!.heightAnchor.constraint(equalToConstant: pickerHeight),
            
            picker!.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 2*spacer),
            picker!.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -2*spacer),
        ])
    }
    
    
    func setPickerSenderList(senderList: String) {
        
        let tempSenders = senderList.components(separatedBy: "\n")
        pickerSenderList = tempSenders
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
