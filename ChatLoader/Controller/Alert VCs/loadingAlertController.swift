//
//  loadingAlertController.swift
//  ChatLoader
//
//  Created by Paul Whiten on 5/4/26.
//
//  Custom UIAlertController to show progress of loading a WhatsApp chat .zip file
//
//  Usage:
//      - initalise from a ViewController
//      - set the delegate: protocolDataChanged? as the ViewController
//      - set fileURL: URL? from the delegate ViewController
//      - present from the delegate ViewContoller
//      - this ViewController is dismissed by calling self.dismiss in either of protocolFileProcessor_complete() or protocolFileProcessor_error(errorMessage: String)
//

import UIKit


class loadingAlertController: UIAlertController, protocolFileProcessor {
    
    let alertHeight: CGFloat = 108   //default width of UIAlertController (style .alert) in iOS18 is 270 points (iOS26 is 320?); default height (with no buttons) is 64 points; default height with one button is 108.33 points (64 + 44)
    let spacer: CGFloat = 8          //spacer for progressViewLoading:UIProgressView
    
    var progressViewLoading = UIProgressView(progressViewStyle: .default)     //show progress of chat being processed
    
    var fp: fileProcessor?  //object to process the imported WhatsApp chat .zip (_chat.txt) file and save to Core Data
    var fileURL: URL?       //URL of the imported WhatsApp chat .zip (_chat.txt) file
    
    var delegate: protocolDataChanged? //notify presenting ViewController of changes, ie chat loaded
    
    
    //MARK: lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize)]
        let attributedTitle = NSMutableAttributedString(string: "Loading chat...", attributes: attributes)
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

         
        //setup progressViewLoading:UIProgressView
        progressViewLoading.tintColor = Helper.app.colorPrimary
        progressViewLoading.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(progressViewLoading)
        
        NSLayoutConstraint.activate([
            progressViewLoading.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 2*spacer),
            progressViewLoading.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -2*spacer),
            progressViewLoading.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -4*spacer),
        ])
        
        //setup the fileProcessor
        fp = fileProcessor(delegate: self, inputFile: self.fileURL!)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Helper.app.setIsLoading(isLoading: true)    //*only* place UserDefaults.standard.bool(forKey: Helper.app.keyIsLoading) can be set to true; set it before creating instance of fileProcessor
        fp?.processExportedFile()
    }
   
    
    //MARK: protocolFileProcessor
    func protocolFileProcessor_start() {}
    
    
    func protocolFileProcessor_update(percentComplete: Int) {
        DispatchQueue.main.async(execute: {
            self.progressViewLoading.progress = Float(percentComplete)/100
        })
    }
    
    
    func protocolFileProcessor_error(errorMessage: String) {
        //note: errorMessage comes from fileProcessor prefixed with "ERROR: "
        
        Helper.app.setIsLoading(isLoading: false)   //*only* 2 places UserDefaults.standard.bool(forKey: Helper.app.keyIsLoading) can be set to false (other than on app launch)
        
        self.dismiss(animated: true, completion: {
            self.delegate?.protocolDataChanged_error(errorMessage:  errorMessage)
        })
    }
    
    
    func protocolFileProcessor_saving() {}
    
    
    func protocolFileProcessor_complete() {
        
        Helper.app.setIsLoading(isLoading: false)   //*only* 2 places UserDefaults.standard.bool(forKey: Helper.app.keyIsLoading) can be set to false (other than on app launch)
        
        self.dismiss(animated: true, completion: {
            self.delegate?.protocolDataChanged_chatLoaded()
        })
    }
    
}
