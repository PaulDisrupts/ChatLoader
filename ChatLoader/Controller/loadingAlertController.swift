//
//  loadingAlertController.swift
//  ChatLoader
//
//  Custom UIAlertController that shows the progress of a task, eg. loading a chat
//
//  Created by Paul Whiten on 5/4/26.
//

import UIKit


class loadingAlert: UIAlertController {
    
    let alertHeight:CGFloat = 108   //default width of UIAlertController (style .alert) in iOS18 is 270 points (iOS26 is 320?); default height (with no buttons) is 64 points; default height with one button is 108.33 points (64 + 44)
    let spacer:CGFloat = 8          //spacer for progressViewLoading:UIProgressView
    
    var progressViewLoading = UIProgressView(progressViewStyle: .default)     //show progress of chat being processed
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Loading chat..."
        
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
    }
    
    
    func updateProgresss (progress: Int) {
        DispatchQueue.main.async(execute: {
            self.progressViewLoading.progress = Float(progress)/100
        })
    }
}
