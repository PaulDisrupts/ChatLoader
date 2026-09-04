//
//  aboutTableViewCell.swift
//  VoiceXporter
//
//  Created by Paul Whiten on 3/6/26.
//

import UIKit

class aboutTableViewCell: UITableViewCell {
    
    var labelTitle: UILabel?
    var labelValue: UILabel?
    var labelAction: UILabel?
    
    let spacer: CGFloat = 4
    var labelHeight: CGFloat = 21
    
    let fontLarge: UIFont = .systemFont(ofSize: 16, weight: .semibold)
    let fontNormal: UIFont = .systemFont(ofSize: 14, weight: .light)
    let fontAction: UIFont = .systemFont(ofSize: 17)
    
    
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
        
        labelTitle?.removeFromSuperview()
        labelValue?.removeFromSuperview()
        labelAction?.removeFromSuperview()
        
        labelTitle = nil
        labelValue = nil
        labelAction = nil
    }
    
    
    //MARK: class functions
    func setupCellViews(title: String?, value: String?, action: String?) {
     
        let selectedView = UIView()
        selectedView.frame = self.contentView.frame
        selectedView.backgroundColor = Helper.app.colorPrimaryCellSelected
        self.selectedBackgroundView = selectedView
        
        let labelWidth: CGFloat = (UIScreen.main.bounds.width) * 0.6   //spacers: edge to imageMessage; imageMessage to label; label to label; label to edge; +2 extra
        
        if title != nil && value != nil && action == nil {
            //App info
            
            selectedView.backgroundColor = .clear
            
            labelTitle = UILabel()
            labelTitle?.backgroundColor = .clear
            labelTitle?.font = fontLarge
            labelTitle?.text = title
            labelAction?.textAlignment = .left
            
            labelValue = UILabel()
            labelValue?.backgroundColor = .clear
            labelValue?.font = fontNormal
            labelValue?.text = value
            labelValue?.textAlignment = .right
            
            self.contentView.addSubview(labelTitle!)
            self.contentView.addSubview(labelValue!)
            
            //autolayout
            labelTitle!.translatesAutoresizingMaskIntoConstraints = false
            labelValue!.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                labelTitle!.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                labelTitle!.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 3*spacer),
                labelTitle!.widthAnchor.constraint(equalToConstant: labelWidth),
                labelTitle!.heightAnchor.constraint(equalToConstant: labelHeight),
                
                labelValue!.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                labelValue!.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -3*spacer),
                labelValue!.widthAnchor.constraint(equalToConstant: labelWidth),
                labelValue!.heightAnchor.constraint(equalToConstant: labelHeight),
            ])
        } //if title != nil and value != nil
        else if action != nil {
            //Get in touch; Pricvacy; Acknowledgements
            
            labelAction = UILabel()
            labelAction?.backgroundColor = .clear
            labelAction?.font = fontAction
            labelAction?.text = action
            
            if title != nil {
                //Privacy; Acknowledgements
                labelAction?.textAlignment = .left
                labelAction?.numberOfLines = 0
                labelAction?.lineBreakMode = .byWordWrapping
                labelHeight = labelHeight * 3
            }
            else {
                //Get in touch
                labelAction?.textColor = Helper.app.colorPrimary
                labelAction?.textAlignment = .center
            }
            
            
            self.contentView.addSubview(labelAction!)
            
            //autolayout
            labelAction!.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                labelAction!.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                labelAction!.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 3*spacer),
                labelAction!.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -3*spacer),
                labelAction!.heightAnchor.constraint(equalToConstant: labelHeight),
            ])
        }
    }
    
}
