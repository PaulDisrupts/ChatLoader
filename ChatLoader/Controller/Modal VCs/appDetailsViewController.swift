//
//  appDetailsViewController.swift
//  ChatLoader
//
//  Created by Paul Whiten on 24/9/26.
//  Copyright © 2026 Paul Michael Whiten. All rights reserved.
//
//  Used to show details of other "ChatTools" apps; intended to be used as pages in a UIPageViewController, ie. modalPageViewController
//
//  Usage:
//      - default viewController for modalPageViewController
//      - update "pageIndex" variables (ie. appLogoFilenames; appNames; appURLs; appDescriptions; appImageFilenames) with relevant data, ensure the array.counts are the same
//

import Foundation
import UIKit

class appDetailsViewController: UIViewController {
    
    //MARK: class variables
    var pageIndex: Int = 0
    
    let spacer: CGFloat = 8
    let textViewHeight: CGFloat = 37   //UILabel = 21; UITextView has top/bottom padding of 8
    
    let appLogoSize: CGFloat = 72
    
    var appLogoFilenames: [String] = ["ChatLoader_logo_1024.png",
                                      "ChatShots 180x180_Icon.png",
                                      "ChatPDF logo 180x180.png",
                                      "VoiceMerge logo 180.png"]
    
    var appNames: [String] = ["ChatLoader",
                              "ChatShots",
                              "ChatPDF",
                              "ChatMerge"]
    
    var appURLs: [String] = ["https://github.com/PaulDisrupts/ChatLoader.git",
                             "https://apps.apple.com/sg/app/chatshots-screenshot-messages/id1018833033",
                             "https://apps.apple.com/sg/app/chatpdf-chat-to-pdf-converter/id1499421936",
                             "https://itunes.apple.com/app/id1499421936"]
    
    var appDescriptions: [String] = ["Proof of concept that takes exported chats from WhatsApp and stores the data in a MySQL database",
                                     "ChatShots",
                                     "ChatPDF",
                                     "ChatMerge"]
    
    var appImageFilenames: [[String]] = [["ChatLoader_logo_1024.png", "ChatLoader_logo_1024.png", "ChatLoader_logo_1024.png"],
                                         ["ChatLoader_logo_1024.png", "ChatLoader_logo_1024.png", "ChatLoader_logo_1024.png"],
                                         ["ChatLoader_logo_1024.png", "ChatLoader_logo_1024.png", "ChatLoader_logo_1024.png"],
                                         ["ChatLoader_logo_1024.png", "ChatLoader_logo_1024.png", "ChatLoader_logo_1024.png"]]
    
    let imageDuration = 3   //seconds to show each appImageFilenames image
    
    
    //MARK: lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    
        //app icon
        let appLogoImageView = UIImageView(image: UIImage(named: appLogoFilenames[pageIndex]))
        let imageWidth: CGFloat = (UIScreen.main.bounds.width - 3*spacer) * 0.2
        appLogoImageView.contentMode = .scaleAspectFit
        appLogoImageView.translatesAutoresizingMaskIntoConstraints = false
        appLogoImageView.layer.cornerRadius = spacer * 2
        appLogoImageView.layer.shadowColor = UIColor.black.cgColor
        appLogoImageView.layer.shadowOffset = CGSize(width: 1, height: 2)
        appLogoImageView.layer.shadowOpacity = 0.7
        appLogoImageView.layer.shadowRadius = spacer/3
        appLogoImageView.layer.masksToBounds = true
        
        //app name and link to App Store
        let appNameTextView = UITextView()
        
        var urlText = "view in the App Store"
        
        if appNames[pageIndex] == "ChatLoader" {
            urlText = "view on GitHub"
        }
            
        let string = appNames[pageIndex] + "  " + urlText
        let attributedString = NSMutableAttributedString(string: string)
        
        let linkRange = (string as NSString).range(of: urlText)
        let appNameRange = (string as NSString).range(of: appNames[pageIndex])
        
        if let url = URL(string: appURLs[pageIndex]) {
            
            let boldFont = UIFont.boldSystemFont(ofSize: 18)
            attributedString.addAttribute(.font, value: boldFont, range: appNameRange)
            
            let fontNormal = UIFont.systemFont(ofSize: 14)
            attributedString.addAttribute(.link, value: url, range: linkRange)
            attributedString.addAttribute(.font, value: fontNormal, range: linkRange)
        }
        appNameTextView.linkTextAttributes = [
            .foregroundColor: Helper.app.colorPrimary,
            .underlineStyle: NSUnderlineStyle.single.rawValue // Optional: keeps the underline
        ]
        
        appNameTextView.attributedText = attributedString
        appNameTextView.isEditable = false
        appNameTextView.isSelectable = true
        appNameTextView.isScrollEnabled = false
        appNameTextView.dataDetectorTypes = .link
        appNameTextView.backgroundColor = .clear
        appNameTextView.textContainer.lineFragmentPadding = 0
        
        appNameTextView.translatesAutoresizingMaskIntoConstraints = false
        
        //app description
        let appDescriptionUILabelView = UILabel()
        appDescriptionUILabelView.text = appDescriptions[pageIndex]
        appDescriptionUILabelView.font = UIFont.italicSystemFont(ofSize: 16)
        appDescriptionUILabelView.textColor = .darkGray
        appDescriptionUILabelView.numberOfLines = 0
        appDescriptionUILabelView.adjustsFontSizeToFitWidth = true
        appDescriptionUILabelView.minimumScaleFactor = 0.5
        appDescriptionUILabelView.backgroundColor = .clear
        appDescriptionUILabelView.translatesAutoresizingMaskIntoConstraints = false
        
        //app images
        var imagesArray:[UIImage] = []
        let tempArray = appImageFilenames[pageIndex]
        for imageName in tempArray {
            imagesArray.append(UIImage(named: imageName)!)
        }
        
        let appImagesImageView = UIImageView(image: UIImage.animatedImage(with: imagesArray, duration: Double(appImageFilenames[pageIndex].count*imageDuration)))
        appImagesImageView.contentMode = .scaleAspectFit
        appImagesImageView.translatesAutoresizingMaskIntoConstraints = false
        
        
        self.view.addSubview(appLogoImageView)
        self.view.addSubview(appNameTextView)
        self.view.addSubview(appDescriptionUILabelView)
        self.view.addSubview(appImagesImageView)
        

        NSLayoutConstraint.activate([
            
            appLogoImageView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            appLogoImageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: spacer),
            appLogoImageView.widthAnchor.constraint(equalToConstant: imageWidth),
            appLogoImageView.heightAnchor.constraint(equalToConstant:imageWidth),
            
            appNameTextView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            appNameTextView.leadingAnchor.constraint(equalTo: appLogoImageView.trailingAnchor, constant: spacer),
            appNameTextView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -1*spacer),
            appNameTextView.heightAnchor.constraint(equalToConstant: textViewHeight),
            
            appDescriptionUILabelView.topAnchor.constraint(equalTo: appNameTextView.bottomAnchor),
            appDescriptionUILabelView.bottomAnchor.constraint(equalTo: appLogoImageView.topAnchor, constant: 1.5*imageWidth),
            appDescriptionUILabelView.leadingAnchor.constraint(equalTo: appLogoImageView.trailingAnchor, constant: spacer),
            appDescriptionUILabelView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -1*spacer),
            
            appImagesImageView.topAnchor.constraint(equalTo: appDescriptionUILabelView.bottomAnchor, constant: spacer),
            appImagesImageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: spacer),
            appImagesImageView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -1*spacer),
            appImagesImageView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
        ])
        

    }
    
}
