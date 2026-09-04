//
//  chatTableViewCell.swift
//  VoiceXporter
//
//  Created by Paul Whiten on 1/6/26.
//

import UIKit

class chatTableViewCell: UITableViewCell {
    
    var imageMessage: UIImageView?
    var labelChatName: UILabel?
    var labelLoadDate: UILabel?
    var labelSenders: UILabel?
    var labelMessages: UILabel?
    var labelChatSize: UILabel?
    
    let spacer: CGFloat = 4
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
            fatalError("init(coder:) has not been implemented")
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
     
        let selectedView = UIView()
        selectedView.frame = self.contentView.frame
        selectedView.backgroundColor = Helper.app.colorPrimaryCellSelected
        self.selectedBackgroundView = selectedView
        
        let labelWidth1: CGFloat = (UIScreen.main.bounds.width - 8*spacer - imageMessageHeight) * 0.7   //spacers: edge to imageMessage; imageMessage to label; label to label; label to edge; +2 extra
        let labelWidth2: CGFloat = (UIScreen.main.bounds.width - 8*spacer - imageMessageHeight) * 0.3
        
        
        if chat.senderCount < 2 {
            imageMessage = UIImageView(image: UIImage(systemName: "bubble.left"))
        } else {
            imageMessage = UIImageView(image: UIImage(systemName: "bubble.left.and.text.bubble.right"))
        }
        
        imageMessage?.tintColor = Helper.app.colorPrimary
        imageMessage?.contentMode = .scaleAspectFit
        imageMessage?.backgroundColor = .clear
        
        labelChatName = UILabel()
        labelChatName?.backgroundColor = .clear
        labelChatName?.font = fontLarge
        labelChatName?.text = chat.chatName
        
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
        
        labelMessages = UILabel()
        labelMessages?.backgroundColor = .clear
        labelMessages?.font = fontNormal
        labelMessages?.text = "Messages: \(numberMessages)"
        
        labelChatSize = UILabel()
        labelChatSize?.backgroundColor = .clear
        labelChatSize?.font = fontNormal
        
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
            imageMessage!.heightAnchor.constraint(equalToConstant: imageMessageHeight),
            imageMessage!.widthAnchor.constraint(equalToConstant: imageMessageHeight),
            
            labelChatName!.topAnchor.constraint(equalTo: contentView.topAnchor, constant: spacer),
            labelChatName!.leadingAnchor.constraint(equalTo: imageMessage!.trailingAnchor, constant: 2*spacer),
            labelChatName!.widthAnchor.constraint(equalToConstant: labelWidth1),
            labelChatName!.heightAnchor.constraint(equalToConstant: labelHeight),
            
            labelLoadDate!.topAnchor.constraint(equalTo: contentView.topAnchor, constant: spacer),
            labelLoadDate!.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -3*spacer),
            labelLoadDate!.widthAnchor.constraint(equalToConstant: labelWidth2),
            labelLoadDate!.heightAnchor.constraint(equalToConstant: labelHeight),
            
            labelSenders!.leadingAnchor.constraint(equalTo: imageMessage!.trailingAnchor, constant: 2*spacer),
            labelSenders!.trailingAnchor.constraint(equalTo: labelMessages!.leadingAnchor, constant: -1*spacer),
            labelSenders!.heightAnchor.constraint(equalToConstant: labelHeight),
            labelSenders!.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2*spacer),
            
            labelMessages!.topAnchor.constraint(equalTo: labelChatName!.bottomAnchor, constant: spacer),
            labelMessages!.leadingAnchor.constraint(equalTo: labelSenders!.trailingAnchor),
            labelMessages!.widthAnchor.constraint(equalToConstant: labelWidth2+10*spacer),
            labelMessages!.heightAnchor.constraint(equalToConstant: labelHeight),
            labelMessages!.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2*spacer),
            
            labelChatSize!.topAnchor.constraint(equalTo: labelChatName!.bottomAnchor, constant: spacer),
            labelChatSize!.leadingAnchor.constraint(equalTo: labelMessages!.trailingAnchor, constant: spacer),
            labelChatSize!.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -3*spacer),
            labelChatSize!.heightAnchor.constraint(equalToConstant: labelHeight),
            labelChatSize!.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2*spacer),
        ])
    }
    
    
    func updateDirSize(chat: Chat) {
        let dir = Helper.app.getChatDirURL(chatID: chat.chatID)
        let dirSize = Helper.app.sizeOfDirectory(at: dir)!
        labelChatSize?.text = "Size: \(dirSize)"
    }
    
}
