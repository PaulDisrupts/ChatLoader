//
//  textFieldTableViewCell.swift
//  ChatLoader
//
//  Created by Paul Whiten on 7/9/26.
//

import UIKit

class textFieldTableViewCell: aboutTableViewCell {
 
    var textView: UITextView?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        labelTitle?.removeFromSuperview()
        labelValue?.removeFromSuperview()
        labelAction?.removeFromSuperview()
        textView?.removeFromSuperview( )
        
        labelTitle = nil
        labelValue = nil
        labelAction = nil
        textView = nil
    }
    
    
    //MARK: class functions
    override func setupCellViews(title: String?, value: String?, action: String?) {
        
        textView = UITextView()
        
        //title = hyperlink text
        //value = text
        //action = url
        if let textString = value, let hyperlink = title, let url = action, let textView {
            
            let attributedString = NSMutableAttributedString(string: textString)
            
            // Find the range of the text you want to hyperlink
            let linkRange = (textString as NSString).range(of: hyperlink)
            // Add the link attribute
            if let url = URL(string: url) {
                attributedString.addAttribute(.link, value: url, range: linkRange)
            }
            
            textView.attributedText = attributedString
            textView.font = fontNormal
            textView.isEditable = false
            textView.isSelectable = true
            textView.isScrollEnabled = false
            textView.dataDetectorTypes = .link
            
            textView.translatesAutoresizingMaskIntoConstraints = false
            
            self.contentView.addSubview(textView)
            
            NSLayoutConstraint.activate([
                //use same spacers as aboutTableViewCell
                textView.topAnchor.constraint(equalTo: self.contentView.safeAreaLayoutGuide.topAnchor, constant: 2*spacer),
                textView.bottomAnchor.constraint(equalTo: self.contentView.safeAreaLayoutGuide.bottomAnchor, constant: -2*spacer),
                
                textView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 2*spacer),
                textView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -2*spacer)
            ])
        }
    }
    
}
