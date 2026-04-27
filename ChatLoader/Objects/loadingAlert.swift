//
//  loadingAlert.swift
//  ChatLoader
//
//  Custom UIAlertController that shows the progress of a task, eg. loading a chat
//
//  WIP - subclass of UIAlertController, issues with autolayout
//
//  Created by Paul Whiten on 5/4/26.
//

import UIKit


class loadingAlert: UIAlertController {
    
    let alertWidth:CGFloat = 270    //default width of UIAlertController (style .alert) in iOS is 270 points
    let alertHeight:CGFloat = 135
    
    var progressViewLoading: UIProgressView?     //show progress of chat being processed
    let progressViewWidth:Int = 250
    let progressViewHeight:Int = 2  //default height of UIProgressView in iOS is 2 points
    
    
    // preferredStyle is read-only, so you must override it to set the style
    override var preferredStyle: UIAlertController.Style {
        return .alert
    }

    // Custom initializer
    init() {
        // You must call the designated initializer of the superclass
        super.init(nibName: nil, bundle: nil)
        self.title = "Loading chat"
        
//        let screenBounds = UIScreen.main.bounds
//        let centerX = screenBounds.midX
//        let centerY = screenBounds.midY
//        let screenCenter = CGPoint(x: centerX, y: centerY)
/*
        //set size contraints of loadingAlert
        let constraintWidth = NSLayoutConstraint(
         item: self.view!,
         attribute: NSLayoutConstraint.Attribute.width,
         relatedBy: NSLayoutConstraint.Relation.equal,
         toItem: nil,
         attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: alertWidth)
        self.view.addConstraint(constraintWidth)

        let constraintHeight = NSLayoutConstraint(
         item: self.view!,
         attribute: NSLayoutConstraint.Attribute.height,
         relatedBy: NSLayoutConstraint.Relation.equal,
         toItem: nil,
         attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: alertHeight)
        self.view.addConstraint(constraintHeight)
*/
        
        //update UIAlertController size
        // Adding constraint for alert base view
        let widthConstraint = NSLayoutConstraint(
            item: self.view!,
            attribute: .width,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1,
            constant: CGFloat(alertWidth))
        self.view.addConstraint(widthConstraint)
        
        // Finding first child width constraint
        let firstContainer = self.view.subviews[0]
        let constraint = firstContainer.constraints.filter({ return $0.firstAttribute == .width && $0.secondItem == nil })
        firstContainer.removeConstraints(constraint)
        
        // And replacing with new constraint equal to alert.view width constraint that we setup earlier
        self.view.addConstraint(NSLayoutConstraint(
            item: firstContainer,
            attribute: .width,
            relatedBy: .equal,
            toItem: self.view,
            attribute: .width,
            multiplier: 1.0,
            constant: 0))
        
        // Same for the second child with width constraint with 998 priority
        let innerBackground = firstContainer.subviews[0]
        let innerConstraints = innerBackground.constraints.filter({ return $0.firstAttribute == .width && $0.secondItem == nil })
        innerBackground.removeConstraints(innerConstraints)
        
        firstContainer.addConstraint(NSLayoutConstraint(
            item: innerBackground,
            attribute: .width,
            relatedBy: .equal,
            toItem: firstContainer,
            attribute: .width,
            multiplier: 1.0,
            constant: 0))
        
        //update the height constraint
        let constraintHeight = NSLayoutConstraint(
            item: self.view!,
            attribute: NSLayoutConstraint.Attribute.height,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: nil,
            attribute: NSLayoutConstraint.Attribute.notAnAttribute,
            multiplier: 1,
            constant: CGFloat(alertHeight))
        self.view.addConstraint(constraintHeight)
        
        //add progress view
        progressViewLoading = UIProgressView(frame: CGRect(x: (Int(alertWidth)-progressViewWidth)/2, y: Int(alertHeight/3*2), width: progressViewWidth, height: progressViewHeight))
        progressViewLoading!.tintColor = Helper.app.colorPrimary
        self.view.addSubview(progressViewLoading!)
        
//        self.view.center = screenCenter
    }

    
    // Required for any UIViewController subclass
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    func updateProgresss (progress: Int) {
        DispatchQueue.main.async(execute: {
            self.progressViewLoading!.progress = Float(progress)/100
        })
    }
}
