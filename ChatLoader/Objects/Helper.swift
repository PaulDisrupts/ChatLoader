//
//  Helper.swift
//  ChatLoader
//
//  Created by Paul Michael Whiten on 11/2/21.
//

/*
    ChatLoader v1.0 verified against WhatsApp v2.21.110.15
    ******************************************************
 
 
    Exported file notes
    *******************
 
        * The chat transcript is exported to file "_chat.txt" (UTF8 encoding); archived within exported file
            "WhatsApp Chat - [chatname].zip" (along with any attachments)
        
        * WhatsApp end of message sequence is: \r\n
 
        * End of "_chat.txt" file is the character: " " //to be confirmed
        
        * Exported format for 'standard' messages (user sent messages or messages received from another user):
            
            [date, timestamp] sender: message
                
            NOTE:
                - exported message date format may vary based on localization
                - exported message timestamp format dependent on 12/24 clock settings
                - depending on localization settings there may not be a "," between the date and timestamp, ie:
                    [date timestamp] sender: message
                - this file "Helper.swift" uses the notation:
                    [DD/M/YY, HH:mm:ss] sender: message
            
        * Group chat update message format (ie 'blue, centered' messages):
 
            a) Triggered by a user action such as: group admin changes "subject", ie group name; group admin changes group icon; group admin changes group description; group admin adds/removes sender; or sender removes themself:
                [DD/M/YY, HH:mm:ss] (U+201E)message
                    (NOTE: message may contain a sender(s), where sender = sender/phone number or "You" if you are the admin/user action taker)
 
            b) From the WhatsApp platform *may* have the (U+201E) between the date/time and the group_name ie:
                [DD/M/YY, HH:mm:ss] (U+201E)group_name: message
                    otherwise it is in the format:
                [DD/M/YY, HH:mm:ss] group_name: message
                    (NOTE: messages of both these formats are currently treated as a message from sender with name = 'group_name')
 
        * 'Broadcast' messages (ie 'yellow, centered' messages; such as the encryted chat notice):
                [DD/M/YY, HH:mm:ss] (U+201E)chatname: message
                    (NOTE: messages of this format are currently treated as a message from sender with name = chatname)
                    
        * Voice/video calls
                - Missed calls (ie 'blue, centered' messages) in the format:
                    [DD/M/YY, HH:mm:ss] sender: (U+201E)message
                        (NOTE: Where messsage = "Missed voice call" or "Missed video call")
 
        * Deleted messages:
            - "Delete For Me" in group chats are not exported as they are completely deleted from the WhatsApp chat
            - "Delete For Everyone" in group chats are exported as:
                [DD/M/YY, HH:mm:ss] sender: This message was deleted
                    or
                [DD/M/YY, HH:mm:ss] sender: You deleted this message
            - Deleted received messages in a non-group chat are exported as:
                [DD/M/YY, HH:mm:ss] sender: This message was deleted
            - Deleted sent messages in a non-group chat are not exported as they are completely deleted from the WhatsApp chat
 
        * Automated message "Invitation to join my Whatsapp group" is exported as:
                [DD/M/YY, HH:mm:ss] sender:
 
        * To be confirmed: Unsent messages
 
 
    General notes on user sent messages/messaged received from another user ('Text' or attachments)
    ***********************************************************************************************
        
        * Message size limit = 65,534 characters
 
        * "Read more..." appended to message after 3,073 characters
        
         * 'Text' message syntax:
             - bold = *bold*
             - italics = _italics_
             - strikethrough = ~strikethrough~
             - mentions (ie @name) = @phone_number
 
        * Unicode (U+201E) 'Double Low-9 Quotation Mark' is treated as a special character in messages
            - (U+201E) on its own behaves like a new line character; but two (U+201E)s (such as in attachments) seem to keep the message contents to a single line (ie. (U+201E) is used to act like brackets)
            - (U+201E) prefixes the sender when it is a phone number
            --> The (U+201E) char is addressed by using String/Range<String.Index> for the bounds and the function:
                    .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines
        
 
    Message types (taken from WhatsApp/Settings/Data and Storage Usage/Storage Usage/)
    **********************************************************************************
     
         Text
         Contacts
         Locations
         
         Photos
         GIFs
         Videos
         Voice Messages
         Documents
         Stickers
 
 
    Exported attachment syntax (2018+)
    **********************************
 
    **"Attach Media" - exported message syntax**
 
        (U+201E)[DD/M/YY, HH:mm:ss] sender: attachment_format
 
        NOTE:   Photos/GIFs/Videos/Voice Messages/Stickers use the below "attachment_format":
        (U+201E)[DD/M/YY, HH:mm:ss] sender: (U+201E)<attached: "filename">
            // NOTE: the "attached:" may differ in a foreign language
            // Where filename syntax is:
            // eg. <attached: 00002609-PHOTO-2019-03-03-13-26-09.jpg>
            //      00002609 = messageID (8 digit number)
            //      PHOTO = media type 'code'
            //      2019-03-03-13-26-09 = timestamp (yyyy-MM-dd-HH-mm-ss)
            //      .jpg = filetype_extension

 
        *Filetypes (NOTE: "attachment_format example" is what is after "sender: " in the message contents)*
 
            Contacts
                code            = n/a
                message suffex  = .vcf>
                sample message  =
                    (U+201E)[DD/M/YY, HH:mm:ss] sender: (U+201E)<attached: 00000001-contact_name.vcf>
     
            Locations
                code            = n/a
                message suffex  = n/a
                sample message  =
                    (U+201E)[DD/M/YY, HH:mm:ss] sender:  (U+201E)Location: https://maps.google.com/?q=lattitude,longitude
                        (NOTE: Additional 'space' character before "(U+201E)Location")
     
            Photos
            (NOTE: .png is converted to .jpg; some cases may not have media type 'code' and instead use the filetype_extension format eg. forwarded as an attachment, sent by "Document")
                code            = PHOTO
                message suffex  = .jpg>
                sample message  =
                    (U+201E)[DD/M/YY, HH:mm:ss] sender: (U+201E)<attached: 00000001-PHOTO-yyyy-MM-dd-HH-mm-ss.jpg>

            GIFs
                code            = GIF
                message suffex  = .mp4>
                sample message  =
                    (U+201E)[DD/M/YY, HH:mm:ss] sender: (U+201E)<attached: 00000001-GIF-yyyy-MM-dd-HH-mm-ss.mp4>
     
            Videos
                code            = VIDEO
                message suffex  = .mp4>, .MOV>
                sample message  =
                    (U+201E)[DD/M/YY, HH:mm:ss] sender: (U+201E)<attached: 00000001-VIDEO-yyyy-MM-dd-HH-mm-ss.mp4>
     
            Voice Messages
                code            = AUDIO
                message suffex  = .opus>
                sample message  =
                    (U+201E)[DD/M/YY, HH:mm:ss] sender: (U+201E)<attached: 00000001-AUDIO-yyyy-MM-dd-HH-mm-ss.opus>
            
            Documents
                code                        = n/a
                message suffex              = .filetype_extension>
                    (NOTE: filetyp_extensions include: pdf; doc; docx; txt; zip; jpeg; jpg; png; mp4; MOV; opus?)
                
                sample message =
                    (U+201E)[DD/M/YY, HH:mm:ss] sender: "filename.filetype_extension" (U+201E)<attached: messageID-"filename.filetype_extension">
 
                (NOTE: 'document' type (pdf; docx etc) includes the number of pages in the message)
                sample message for 'document' type .pdf  =
                    (U+201E)[DD/M/YY, HH:mm:ss] sender: "filename.pdf" • ‎n page(s) (U+201E)<attached: messageID-"filename.pdf">
     
            Stickers
                code            = STICKER
                message suffex  = .webp>
                sample message  =
                    (U+201E)[DD/M/YY, HH:mm:ss] sender: (U+201E)<attached: 00000001-STICKER-yyyy-MM-dd-HH-mm-ss.mp4>

 
    **"Without Media" - exported message syntax**

        (U+201E)[DD/M/YY, HH:mm:ss] sender: attachment_omitted_message
        
        NOTE:   Contacts/Photos/GIFs/Videos/Voice Messages/Stickers use the below "attachment_omitted_message":
        (U+201E)[DD/M/YY, HH:mm:ss] sender: (U+201E)attachment_type omitted
 
        NOTE:   the "attachment_omitted_message" may differ in a foreign language
        
        NOTE:   for "attachment_type omitted" there are extraneous prefixed characters ie. (U+201E), so use function:
                    String.hasSuffix("attachment_type omitted")
                eg. String attachment_omitted_message = "image omitted" (exported as "(U+201E)image omitted") will result in:
                        attachment_omitted_message.count = 14;
                        attachment_omitted_message.filter {$0.isASCII} = 13

 
        *Filetypes (NOTE: "attachment_omitted_message" is what is after "sender: " in the message contents)*
        
            Contacts
                sample message =
                    ‎(U+201E)[DD/M/YY, HH:mm:ss] sender: (U+201E)Contact card omitted
     
            Locations
                sample message =
                ‎(U+201E)[DD/M/YY, HH:mm:ss] sender:  (U+201E)Location: https://maps.google.com/?q=lattitude,longitude
                    (NOTE: Additional 'space' character before "(U+201E)Location")
     
            Photos
                sample message =
                    (U+201E)[DD/M/YY, HH:mm:ss] sender: (U+201E)image omitted

            GIFs
                sample message =
                    ‎(U+201E)[DD/M/YY, HH:mm:ss] sender: (U+201E)GIF omitted
     
            Videos
                sample message =
                    ‎(U+201E)[DD/M/YY, HH:mm:ss] sender: (U+201E)video omitted
     
            Voice Messages
                sample message =
                    ‎(U+201E)[DD/M/YY, HH:mm:ss] sender: (U+201E)audio omitted
            
            Documents
                sample message =
                    (U+201E)[DD/M/YY, HH:mm:ss] sender: "filename.filetype_extension" (U+201E)document omitted
                
                (NOTE: 'document' type (pdf; docx etc) includes the number of pages in the message)
                sample message for 'document' type .pdf  =
                    ‎(U+201E)[DD/M/YY, HH:mm:ss] sender: "filename.pdf" • ‎n page(s) ‎(U+201E)document omitted
            
            Stickers
                sample message =
                    ‎(U+201E)[DD/M/YY, HH:mm:ss] sender: (U+201E)sticker omitted
 
 
    Limitations on exported message content/recreating chats
    ********************************************************

        Exporting limitations:
        * 'Replies' to messages are *NOT* exported
        * 'Captions' to attachments are *NOT* exported
        * 'Star' indicators on messages are *NOT* exported
        * File size information of 'Document' attachments are *NOT* exported
        * "Forwarded" or "Forwarded many times" indicators on messages are *NOT* exported
        * Embedded prompts from the WhatsApp platform about "This sender is not in your contacts" are *NOT* exported
        * Embedded prompts from the WhatsApp platform about "You were added by someone who's not in your contacts" are *NOT* exported
        * 'Unread' messages are exported; "X UNREAD MESSAGES" banners from the WhatsApp platform are *NOT* exported
        
            
        Recreating chats limitations:
        * Group chat update messages (ie 'blue, centered' messages) from the WhatsApp platform are treated as a message from sender with name = 'group_name'
                (NOTE: if group_name has been changed multiple times, then the message sender may not match the exported chat filename)
        
        * 'Broadcast' messages (ie 'yellow, centered' messages; such as the encryted chat notice) are treated as a message from sender with name = chatname
        
        * Deleted messages that have been exported are treated as a message from the sender (as opposed to an grey italics message)
        
        * 'Missed call' messages are treated as a message from the sender (as opposed to a 'blue, centered' message)
        
        * Automated message "Invitation to join my Whatsapp group" is treated as a status update message (ie 'blue, centered' messages) with the format:
            sender:

*/

import Foundation
import UIKit

class Helper {
    
    static var app: Helper = {
        return Helper()
    }()
    
    let animationTime: Double = 0.3
    let alphaDimBG: CGFloat = 0.75
    
    
    //MARK: date functions
    func getTodayYYYYMMDD() -> String {
        
        let date = Date()
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy-MM-dd"
        
        return formatter.string(from: date)
    }
    
    
    func converNSDateToYYYYMMDD(inputDate: NSDate) -> String {
        
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy-MM-dd"
        
        return formatter.string(from: inputDate as Date)
    }
    
    
    func convertDateSlashToDash(inputDate: String) -> String? {
        
        if inputDate.count == 10 {
            return inputDate.replacingOccurrences(of: "/", with: "-")
        } else {
            return nil
        }
    }
    
    func getLocale() -> String {
        return "\((Locale.current as NSLocale).object(forKey: NSLocale.Key.identifier)!)"
    }
    
    
    func convertDateAsString(_ inputDate:String) -> String {
        
        let inputDateFormatter = DateFormatter()
        inputDateFormatter.dateFormat = "yyyy/MM/dd"
        
        let localeFormatter = DateFormatter()
        localeFormatter.locale = Locale.current
        localeFormatter.dateStyle = .medium
        
        return localeFormatter.string(from: inputDateFormatter.date(from: inputDate)!)
    }
    
    
    func converNSDateToLocalDate(inputDate: NSDate) -> String {
        
        let localeFormatter = DateFormatter()
        localeFormatter.locale = Locale.current
        localeFormatter.dateStyle = .medium
        
        return localeFormatter.string(from: (inputDate as Date))
    }
    
    
    func componentsYYYYMMDD(yyyymmdd:String) -> (yyyy:Int?, mm:Int?, dd:Int?) {
        
        if yyyymmdd.count == 10 {
            
            let yyyy = yyyymmdd.prefix(4)
            let dd = yyyymmdd.suffix(2)
            
            let startmm = yyyymmdd.index(yyyymmdd.startIndex, offsetBy: 5)
            let endmm = yyyymmdd.index(yyyymmdd.endIndex, offsetBy: -3)
            let range4 = startmm..<endmm
            
            let mm = yyyymmdd[range4]
            
            return (Int(yyyy), Int(mm), Int(dd))
        }
        
        return (nil, nil, nil)
    }
    
    
    func formatNumber(number: Int) -> String? {
        
        let numberFormatter = NumberFormatter()
        
        numberFormatter.groupingSeparator = ","
        numberFormatter.groupingSize = 3
        numberFormatter.usesGroupingSeparator = true
        
        return numberFormatter.string(from: NSNumber(value: number))
    }
    
    //MARK: directory functions
    func documentsDirectoryURL() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        //return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func libraryDirectoryURL() -> URL {
        return FileManager.default.urls(for: FileManager.SearchPathDirectory.libraryDirectory, in: .userDomainMask).first!
    }
    
    func tempDirectoryURL() -> URL {
        return FileManager.default.temporaryDirectory
        //urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(AppDirectories.Temp.rawValue) //"tmp")
    }
    
    func inboxDirectoryURL() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Inbox")// (AppDirectories.Inbox.rawValue) // "Inbox")
    }
    
    
    func formatChatIDToDirectoryName(chatID:Int) -> String {
        //create a 4 digit fileID name
        
        let tempStr = String(String("000" + String(chatID)).suffix(4))
        
        print("func formatChatIDToDirectoryName(chatID:Int) -> \(tempStr)")
        
        return tempStr
    }
    
    
    func printFilesInbox() {
        
        let fileManager = FileManager()
        
        do {
            let fileNames = try fileManager.contentsOfDirectory(atPath: inboxDirectoryURL().path) as [String]?
            
            for fn in fileNames! {
                
                print("filename: \(fn)")
                
                if fn.range(of: ".zip") != nil {
                    print("found!")
                }
            }
            
        } catch let error as NSError {
            print("WARNING: func printFilesInbox() { no files found! \(error)")
        }
    }
    
    
    func getImportedFileURLFromInbox() -> URL? {
        
        var url:URL?
        
        let fileManager = FileManager()
        
        do {
            let fileNames = try fileManager.contentsOfDirectory(atPath: inboxDirectoryURL().path) as [String]?
            
            for fn in fileNames! {
                
                print("filename: \(fn)")
                
                if fn.range(of: ".zip") != nil {
                    print("found!")
                    url = inboxDirectoryURL().appendingPathComponent(fn)
                }
            }
            
        } catch let error as NSError {
            print("WARNING: getImportedFileURLFromInbox() { no files found! \(error)")
        }
        
        return url
    }
}


extension URL {
    /* usage:
        let fileUrl: URL
        print("file size = \(fileUrl.fileSize), \(fileUrl.fileSizeString)")
     */
    
    var attributes: [FileAttributeKey : Any]? {
        do {
            return try FileManager.default.attributesOfItem(atPath: path)
        } catch let error as NSError {
            print("FileAttribute error: \(error)")
        }
        return nil
    }
    
    var fileSize: UInt64 {
        return attributes?[.size] as? UInt64 ?? UInt64(0)
    }
    
    var fileSizeString: String {
        return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
    }
    
    var creationDate: Date? {
        return attributes?[.creationDate] as? Date
    }
}
