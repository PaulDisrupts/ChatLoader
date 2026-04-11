//
//  chatLoadingAlert.swift
//  ChatLoader
//
//  Created by Paul Whiten on 11/4/26.
//
//  Note: subclassing UIAlertController causes issues with Auto Layout
//

import UIKit

class chatLoadingAlert {
    
    let alertWidth:CGFloat = 270    //default width of UIAlertController (style .alert) in iOS is 270 points; default height (with no buttons) is 64 points; default height with one button is 108.33 points
    let alertHeight:CGFloat = 108   //64 + 44
    
    var progressViewLoading: UIProgressView?     //show progress of chat being processed
    let progressViewWidth:Int = 250
    let progressViewHeight:Int = 2              //default height of UIProgressView in iOS is 2 points
    let progressViewY:Int = 85                  //64+(44/2)+(2/2)
    
    var alertController:UIAlertController?
    
    func setup() -> UIAlertController {
        
        alertController = UIAlertController(title: "Loading chat...", message: "", preferredStyle: .alert)
        
        //set size contraints of loadingAlert
        // Adding constraint for alert base view
        let widthConstraint = NSLayoutConstraint(
            item: alertController!.view!,
            attribute: .width,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1,
            constant: CGFloat(alertWidth))
        alertController!.view.addConstraint(widthConstraint)
        
        // Finding first child width constraint
        let firstContainer = alertController!.view.subviews[0]
        let constraint = firstContainer.constraints.filter({ return $0.firstAttribute == .width && $0.secondItem == nil })
        firstContainer.removeConstraints(constraint)
        
        // And replacing with new constraint equal to alert.view width constraint that we setup earlier
        alertController!.view.addConstraint(NSLayoutConstraint(
            item: firstContainer,
            attribute: .width,
            relatedBy: .equal,
            toItem: alertController!.view,
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
            item: alertController!.view!,
            attribute: NSLayoutConstraint.Attribute.height,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: nil,
            attribute: NSLayoutConstraint.Attribute.notAnAttribute,
            multiplier: 1,
            constant: CGFloat(alertHeight))
        alertController!.view.addConstraint(constraintHeight)
        
        //add progress view
        progressViewLoading = UIProgressView(frame: CGRect(x: (Int(alertWidth)-progressViewWidth)/2, y: Int((alertHeight/3)*2), width: progressViewWidth, height: progressViewHeight))
        progressViewLoading!.tintColor = Helper.app.colorPrimary
        alertController!.view.addSubview(progressViewLoading!)
        
        return alertController!
    }
    
    
    func updateProgresss (progress: Int) {
        DispatchQueue.main.async(execute: {
            self.progressViewLoading!.progress = Float(progress)/100
        })
    }
}


