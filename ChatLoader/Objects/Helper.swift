//
//  Helper.swift
//  ChatLoader
//
//  Created by Paul Michael Whiten on 11/2/21.
//

/*
    ChatLoader v1.0 verified against WhatsApp v2.20.132.2
    *****************************************************
 
 
    Exported file notes
    *******************
 
        * The chat transcript is exported to file "_chat.txt" (UTF8 encoding); archived within exported file
            "WhatsApp Chat - [chatname].zip" (along with any attachments)
        
        * WhatsApp end of message sequence is: \r\n
        
        * Exported format for 'standard' (user sent) messages:
            
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
 
 
    Message types (taken from WhatsApp/Settings/Data and Storage Usage/Storage Usage/)
    *************
        
        Text
        Contacts
        Locations
        
        Photos
        GIFs
        Videos
        Voice Messages
        Documents
        Stickers
 
 
    General notes on user sent messages ('Text' or attachments)
    ***********************************************************
        
        * Message size limit = 65,534 characters
        * "Read more..." appended to message after 3,073 characters
        
        * Unicode (U+201E) 'Double Low-9 Quotation Mark' is treated as a special character in messages
            - (U+201E) on its own behaves like a new line character; but two (U+201E)s (such as in attachments) seem to keep the message contents to a single line (ie. (U+201E) is used to act like brackets)
            - (U+201E) prefixes the sender when it is a phone number
            --> The (U+201E) char is addressed by using String/Range<String.Index> for the bounds and the function:
                    .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines
        
        * Deleted message exported as:
            [DD/M/YY, HH:mm:ss] sender: This message was deleted
 
        * 'Text' message syntax:
            - bold = *bold*
            - italics = _italics_
            - strikethrough = ~strikethrough~
            - mentions (ie @name) = @phone_number
 
    
    Exported attachment syntax (2018+)
    **********************************
 
    **"Attach Media" - exported message syntax**
 
        (U+201E)[DD/M/YY, HH:mm:ss] sender: attachment_format
 
        NOTE:   Photos/GIFs/Videos/Voice Messages/Stickers use the below "attachment_format":
        (U+201E)[DD/M/YY, HH:mm:ss] sender: (U+201E)<attached: "filename">
            // Where filename syntax is:
            // eg. <attached: 00002609-PHOTO-2019-03-03-13-26-09.jpg>
            //      00002609 = messageID (8 digit number)
            //      PHOTO = media type 'code'
            //      2019-03-03-13-26-09 = timestamp (yyyy-MM-dd-HH-mm-ss)
            //      .jpg = filetype_extension

 
        Filetypes (NOTE: "attachment_format example" is what is after "sender: " in the message contents)
 
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
        (NOTE: .png is converted to .jpg; some cases may not have media type 'code' and instead use the filetype_extension format eg. forwarded as an attachment)
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
                (U+201E)[DD/M/YY, HH:mm:ss] sender: (U+201E)<attached: 00000001-AUDIO-yyyy-MM-dd-HH-mm-ss.mp4>
        
        Documents
            code                        = n/a
            message suffex              = .pdf>
            sample message  = "filename.pdf" • ‎n page(s) <attached: messageID-"filename.pdf">
                (NOTE: there is no preceding (U+201E) char to the attachment_format)
 
            message suffex              = .filetype_extension>
                (NOTE: filetyp_extensions include: doc; docx; txt; zip)
            attachment_format example   = "filename.filetype_extension" <attached: messageID-"filename.filetype_extension">
                (NOTE: there is no preceding (U+201E) char to the attachment_format)
 
        Stickers
            code            = STICKER
            message suffex  = .webp>
            sample message  =
                (U+201E)[DD/M/YY, HH:mm:ss] sender: (U+201E)<attached: 00000001-STICKER-yyyy-MM-dd-HH-mm-ss.mp4>

 
    **"Without Media" - exported message syntax**

        (U+201E)[DD/M/YY, HH:mm:ss] sender: attachment_omitted_message
        
        NOTE:   Contacts/Photos/GIFs/Videos/Voice Messages/Stickers use the below "attachment_omitted_message":
        (U+201E)[DD/M/YY, HH:mm:ss] sender: (U+201E)attachment_type omitted
        
        NOTE:   for "attachment_type omitted" there are extraneous prefixed characters ie. (U+201E), so use function:
                    String.hasSuffix("attachment_type omitted")
                eg. String attachment_omitted_message = "image omitted" (exported as "(U+201E)image omitted") will result in:
                        attachment_omitted_message.count = 14;
                        attachment_omitted_message.filter {$0.isASCII} = 13

 
        Filetypes (NOTE: "attachment_omitted_message" is what is after "sender: " in the message contents)
        
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
            .pdf sample message =
                ‎(U+201E)[DD/M/YY, HH:mm:ss] sender: "filename.pdf" • ‎n page(s) ‎document omitted
                    (NOTE: there is no preceding (U+201E) char to the attachment_omitted_message)
            
            .filetype_extension sample message =
                (U+201E)[DD/M/YY, HH:mm:ss] sender: "filename.filetype_extension" document omitted
                    (NOTE: there is no preceding (U+201E) char to the attachment_omitted_message)
        
        Stickers
            sample message =
                ‎(U+201E)[DD/M/YY, HH:mm:ss] sender: (U+201E)sticker omitted
 
 
    Limitations on exported message content/recreating chats
    ********************************************************

        Exporting limitations:
        * 'Replies' to messages are *NOT* exported
        * 'Captions' to attachments are *NOT* exported
        * Indicators for messages that are "Forwarded" or "Forwarded many times" are *NOT* exported
 
 
        Recreating chats limitations:
        * Group chat update messages (ie 'blue, centered' messages) from the WhatsApp platform are treated as a message from sender with name = 'group_name'
                (NOTE: if group_name has been changed multiple times, then the message sender would not match the exported chat filename)
        * 'Broadcast' messages (ie 'yellow, centered' messages; such as the encryted chat notice) are treated as a message from sender with name = chatname
        * 'Missed call' messages are treated as a message from the sender (as opposed to a 'blue, centered' message)

 
*/

import Foundation
