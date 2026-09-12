//
//  chatTableViewCell.swift
//  ChatLoader
//
//  Created by Paul Whiten on 1/6/26.
//
//  Used for displaying the data in a Chat
//

import UIKit

class chatTableViewCell: UITableViewCell {
    
    //MARK: class variables
    var imageMessage: UIImageView?  //uses different SF Symbols dependig on Chat.senderCount
    var labelChatName: UILabel?
    var labelLoadDate: UILabel?
    var labelSenders: UILabel?
    var labelMessages: UILabel?
    var labelChatSize: UILabel?
    
    let spacer: CGFloat = 4         //standard spacing for between views
    let labelHeight: CGFloat = 21
    let imageMessageHeight: CGFloat = 48
    
    let fontLarge: UIFont = .systemFont(ofSize: 16, weight: .semibold)
    let fontNormal: UIFont = .systemFont(ofSize: 14, weight: .light)
    
    
    //MARK: lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
        
    
    required init?(coder: NSCoder) {
            fatalError("FATAL ERROR: init(coder:) has not been implemented")
        }

    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageMessage?.removeFromSuperview()
        labelChatName?.removeFromSuperview()
        labelLoadDate?.removeFromSuperview()
        labelSenders?.removeFromSuperview()
        labelMessages?.removeFromSuperview()
        labelChatSize?.removeFromSuperview()
        
        imageMessage = nil
        labelChatName = nil
        labelLoadDate = nil
        labelSenders = nil
        labelMessages = nil
        labelChatSize = nil
    }
    
    
    //MARK: class functions
    func setupCellViews(chat: Chat, numberMessages: String, directorySize: String) {
     
        self.backgroundColor = UIColor.secondarySystemGroupedBackground
        
        let selectedView = UIView()
        selectedView.frame = self.contentView.frame
        selectedView.backgroundColor = Helper.app.colorPrimaryCellSelected
        self.selectedBackgroundView = selectedView
        
        /*
         Spacers:
         edge to imageMessage = 2
         imageMessage to labelChatName = 2
         labelLoadDate to edge = 3
         */
        let labelWidthChatName: CGFloat = (UIScreen.main.bounds.width - 7*spacer - imageMessageHeight) * 0.7
        let labelWidthLoadDate: CGFloat = (UIScreen.main.bounds.width - 7*spacer - imageMessageHeight) * 0.3
        
        /*
         Spacers:
         edge to imageMessage = 2
         imageMessage to labelSenders = 2
         labelChatSize to edge = 3
         */
        let labelWidthMessages: CGFloat = (UIScreen.main.bounds.width - 7*spacer - imageMessageHeight) * 0.45
        let labelWidthSenders_ChatSize: CGFloat = (UIScreen.main.bounds.width - 7*spacer - imageMessageHeight) * 0.275
        
        if chat.senderCount < 2 {
            imageMessage = UIImageView(image: UIImage(systemName: "bubble.left"))
        }
        else {
            imageMessage = UIImageView(image: UIImage(systemName: "bubble.left.and.text.bubble.right"))
        }
        
        imageMessage?.tintColor = Helper.app.colorPrimary
        imageMessage?.contentMode = .scaleAspectFit
        imageMessage?.backgroundColor = .clear
        
        labelChatName = UILabel()
        labelChatName?.backgroundColor = .clear
        labelChatName?.font = fontLarge
        labelChatName?.text = chat.chatName
        labelChatName?.adjustsFontSizeToFitWidth = true
        labelChatName?.minimumScaleFactor = 0.5
        
        labelLoadDate = UILabel()
        labelLoadDate?.backgroundColor = .clear
        labelLoadDate?.font = UIFont.systemFont(ofSize: 12, weight: .light)
        labelLoadDate?.textAlignment = .right
        labelLoadDate?.textColor = .gray
        labelLoadDate?.text = Helper.app.converNSDateToLocalDate(inputDate: chat.dateLoad!)
        
        labelSenders = UILabel()
        labelSenders?.backgroundColor = .clear
        labelSenders?.font = fontNormal
        labelSenders?.text = "Senders: \(String(chat.senderCount))"
        labelSenders?.adjustsFontSizeToFitWidth = true
        labelSenders?.minimumScaleFactor = 0.5
        
        labelMessages = UILabel()
        labelMessages?.backgroundColor = .clear
        labelMessages?.font = fontNormal
        labelMessages?.text = "Messages: \(numberMessages)"
        labelMessages?.adjustsFontSizeToFitWidth = true
        labelMessages?.minimumScaleFactor = 0.5
        
        labelChatSize = UILabel()
        labelChatSize?.backgroundColor = .clear
        labelChatSize?.font = fontNormal
        labelChatSize?.textAlignment = .right
        labelChatSize?.adjustsFontSizeToFitWidth = true
        labelChatSize?.minimumScaleFactor = 0.5
        
        let dir = Helper.app.getChatDirURL(chatID: chat.chatID)
        let dirSize = Helper.app.sizeOfDirectory(at: dir)!
        labelChatSize?.text = "Size: \(dirSize)"
        
        self.contentView.addSubview(imageMessage!)
        self.contentView.addSubview(labelChatName!)
        self.contentView.addSubview(labelLoadDate!)
        self.contentView.addSubview(labelSenders!)
        self.contentView.addSubview(labelMessages!)
        self.contentView.addSubview(labelChatSize!)
        
        
        //autolayout
        imageMessage!.translatesAutoresizingMaskIntoConstraints = false
        labelChatName!.translatesAutoresizingMaskIntoConstraints = false
        labelLoadDate!.translatesAutoresizingMaskIntoConstraints = false
        labelSenders!.translatesAutoresizingMaskIntoConstraints = false
        labelMessages!.translatesAutoresizingMaskIntoConstraints = false
        labelChatSize!.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            imageMessage!.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            imageMessage!.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2*spacer),
            imageMessage!.widthAnchor.constraint(equalToConstant: imageMessageHeight),
            imageMessage!.heightAnchor.constraint(equalToConstant: imageMessageHeight),
            
            labelChatName!.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2*spacer),
            labelChatName!.leadingAnchor.constraint(equalTo: imageMessage!.trailingAnchor, constant: 2*spacer),
            labelChatName!.widthAnchor.constraint(equalToConstant: labelWidthChatName),
            labelChatName!.heightAnchor.constraint(equalToConstant: labelHeight),
            
            labelLoadDate!.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2*spacer),
            labelLoadDate!.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -3*spacer),
            labelLoadDate!.widthAnchor.constraint(equalToConstant: labelWidthLoadDate),
            labelLoadDate!.heightAnchor.constraint(equalToConstant: labelHeight),
            
            labelSenders!.topAnchor.constraint(equalTo: labelChatName!.bottomAnchor, constant: spacer),
            labelSenders!.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2*spacer),
            labelSenders!.leadingAnchor.constraint(equalTo: imageMessage!.trailingAnchor, constant: 2*spacer),
            labelSenders!.widthAnchor.constraint(equalToConstant: labelWidthSenders_ChatSize),
            labelSenders!.heightAnchor.constraint(equalToConstant: labelHeight),
            
            labelMessages!.topAnchor.constraint(equalTo: labelChatName!.bottomAnchor, constant: spacer),
            labelMessages!.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2*spacer),
            labelMessages!.leadingAnchor.constraint(equalTo: labelSenders!.trailingAnchor),
            labelMessages!.trailingAnchor.constraint(equalTo: labelChatSize!.leadingAnchor),
            labelMessages!.widthAnchor.constraint(equalToConstant: labelWidthMessages),
            labelMessages!.heightAnchor.constraint(equalToConstant: labelHeight),

            labelChatSize!.topAnchor.constraint(equalTo: labelChatName!.bottomAnchor, constant: spacer),
            labelChatSize!.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2*spacer),
            labelChatSize!.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -3*spacer),
            labelChatSize!.widthAnchor.constraint(equalToConstant: labelWidthSenders_ChatSize),
            labelChatSize!.heightAnchor.constraint(equalToConstant: labelHeight),
        ])
    }
    
    
    func updateDirSize(chat: Chat) {
        let dir = Helper.app.getChatDirURL(chatID: chat.chatID)
        let dirSize = Helper.app.sizeOfDirectory(at: dir)!
        labelChatSize?.text = "Size: \(dirSize)"
    }
    
}
