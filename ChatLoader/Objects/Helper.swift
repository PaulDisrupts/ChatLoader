//
//  Helper.swift
//  ChatLoader
//
//  Created by Paul Michael Whiten on 11/2/21.
//

/*
    ChatLoader v1.0 verified against WhatsApp v2.21.90.14
    
 Exported file notes
 *******************

     * The chat transcript is exported to file "_chat.txt" (UTF8 encoding); archived within exported .zip file:
         "WhatsApp Chat - [chat_name].zip" (along with any attachments)
     
     * WhatsApp end of message sequence is: \r\n
         \r\n = "carriage return, line feed" and is treated as a single character

     * Some localisations may use (U+200E) in place of (U+201E) when exporting messages
     
     * Exported format for 'normal' messages (user sent messages or messages received from another user):
         
         [date, timestamp] sender: message
             
         NOTE:
             - exported message date format may vary based on localization
             - exported message timestamp format dependent on 12/24 clock settings
             - depending on localization settings there may not be a ", " between the date and timestamp, i.e.:
                 [date timestamp] sender: message
             - this file "Helper.swift" assumes the exported message format of:
                 [DD/M/YY, HH:mm:ss] sender: message
         
     * "System" message format (i.e. 'blue, centered' messages; or 'off-white, centered' messages from WhatsApp v2.22.19.78):

         a) Triggered by a user action such as: admin creates the group chat; group admin changes "subject", i.e. group name; group admin changes group icon; group admin changes group description; group admin adds/removes sender; sender removes themself; sender changes number; Turning on/off disappearing messages; user pins a message etc:
             [DD/M/YY, HH:mm:ss] (U+201E)message
                 or
             [DD/M/YY, HH:mm:ss] (U+201E)sender: message
                 (NOTE: from at least Whatsapp v2.26.10.74, the "system" messages are of the format "[DD/M/YY, HH:mm:ss] (U+201E)sender: message";
                        Therefore unable to distinguish between the group name and a sender.
                        For 1-to-1 chats, the outgoing message receipient (ie. left hand side) appears as the sender of the "system" messages)
                 (NOTE: message is exported as a message from that user (ie. the user who triggered the action is the sender))
                 (NOTE: In a group chat, an admin adding/removing a user to the group chat is exported as a message from the user that was added/removed (ie. the user is the sender))
                 (NOTE: message *may not* have the (U+201E) between the date/time and the sender; or between the date/time and the message)
                 

         b) From the WhatsApp platform *may* have the (U+201E) between the date/time and the chat_name i.e.:
             [DD/M/YY, HH:mm:ss] (U+201E)chat_name: message
                 otherwise it is in the format:
             [DD/M/YY, HH:mm:ss] chat_name: message
                 (NOTE: messages of both these formats are currently treated as a message from sender with name = chat_name, note that for 1-to-1 chats the chat_name = other_senders_name))

     * 'Broadcast' messages (i.e. 'yellow, centered' messages; such as the encrypted chat notice):
             [DD/M/YY, HH:mm:ss] (U+201E)chat_name: message
                 (NOTE: messages of this format are currently treated as a message from sender with name = chat_name, note that for 1-to-1 chats the chat_name = other_senders_name)

     * Voice/video calls
             - Calls made/received (i.e icon message with text "Voice/Video call /n_duration_") in the format:
                 [DD/M/YY, HH:mm:ss] sender: (U+201E)message
                     (NOTE: Where messsage = "Voice/Video call, _duration_")

             - Group calls in progress (i.e icon message) in the format:
                  [DD/M/YY, HH:mm:ss] sender: (U+201E)message
                      (NOTE: Where messsage = "Voice/Video call, N joined • Tap to Join")


             - Missed calls (i.e. 'blue, centered' messages; or icon message with text "Missed voice/video call /nTap to call back"; or for group chats, "Missed call _duration_ • N joined") in the format:
                 [DD/M/YY, HH:mm:ss] sender: (U+201E)message
                     (NOTE: Where messsage = "Missed voice call"/"Missed voice call, Tap to call back" or "Missed video call"/"Missed video call, Tap to call back"/"Missed call, _duration_ • N joined")

     * Deleted messages:
         - Messages that were deleted using "Delete For Me" in group chats are not exported as they are completely deleted from the WhatsApp chat
         
         - Messages that were deleted using "Delete For Everyone" in group chats are exported as:
             [DD/M/YY, HH:mm:ss] sender: This message was deleted
                 or
             [DD/M/YY, HH:mm:ss] sender: You deleted this message
                 or
             [DD/M/YY, HH:mm:ss] sender: This message was deleted by admin admin_name.
         
         - Received messages deleted in a non-group chat are exported as:
             [DD/M/YY, HH:mm:ss] sender: This message was deleted
         
         - Sent messages deleted in a non-group chat are not exported as they are completely deleted from the WhatsApp chat

     * Generated message "Invitation to join my Whatsapp group" is exported as:
             [DD/M/YY, HH:mm:ss] sender:

     * Note that sometimes the last message in a chat may have the (U+201E) char appended to it, unable to determine the specific circumstances for this


 General notes on user sent messages/messages received from another user ('Text' or attachments)
 ***********************************************************************************************
     
     * Message size limit = 65,534 characters

     * "Read more..." appended to message after 3,073 characters
     
      * Formatted text in messages syntax:
         - italics = _italics_
         - bold = *bold*
         - strikethrough = ~strikethrough~
         - monospace = ```monospace```
         - bulleted list = * list_item_1
                     or  = - list_item_1
         - numbered list = 1. text
         - quote = > quoted_text
         - inline code = `inline_code`
         - mentions (i.e. @name) = @phone_number

     * Unicode (U+201E) 'Double Low-9 Quotation Mark' is treated as a special character in messages
         - (U+201E) on its own behaves like a new line character; but two (U+201E)s (such as in attachments) seem to keep the message contents to a single line (i.e. (U+201E) is used to act like brackets)
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
     
     NOTE:   for "attachment_type omitted" there are extraneous prefixed characters i.e. (U+201E), so use function:
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

     **Exporting chat messages from WhatsApp limitations/notes**

     * 'Reply' indicators to messages are *NOT* exported

     * 'Captions' to attachments are *NOT* exported
         (NOTE: 'Captions' to videos from the official WhatsApp chat account *are* exported with the format:
             (U+201E)[DD/M/YY, HH:mm:ss] sender: (U+201E)_caption message_/n<attached: 00000001-VIDEO-yyyy-MM-dd-HH-mm-ss.mp4>
         )

     * 'Star' indicators on messages (i.e. favourites) are *NOT* exported

     * 'Reactions' (i.e. emoji responses to a message) are *NOT* exported

     * File size information of 'Document' attachments are *NOT* exported

     * "Forwarded" or "Forwarded many times" indicators on messages are *NOT* exported

     * "Forward" icon buttons next to messages are *NOT* exported

     * 'Info' indicators on 'disappearing messages' are *NOT* exported, ie.: When pressed the alert message "This message will not disappear from the chat. The sender may be on an old version of WhatsApp"

     * Embedded prompts from the WhatsApp platform about "sender changed their phone number to a new number. Tap to message or add the new number" are *NOT* exported
     
     * Embedded prompts from the WhatsApp platform about "This sender is not in your contacts" are *NOT* exported
     
     * Embedded prompts from the WhatsApp platform about "You were added by someone who's not in your contacts" are *NOT* exported
     
     * The "Invite to Group via link" message (i.e message text "Invitation to jon my WhatsApp group") and associated 'group chat attachment' are *NOT* exported; instead a 'blank' message from the sender is exported, ie.:
         sender:

     * An "Invite to Group via link" message (with: icon, "Join Group" button; forward button; and user message) is exported as a 'normal' message with only the 'user message text' (including the chat URL)
     
     * 'Unread' messages *are* exported; "X UNREAD MESSAGES" banners from the WhatsApp platform are *NOT* exported
     
     * Attachment messages (image/video/audio/document etc) that have not been downloaded to the users devices are *NOT* exported

     * Messages with prompts/action buttons are exported as 'normal' messages without the prompts/action buttons

     * A group chat's 'description' is *NOT* exported
     
     * A group chat's 'icon' is *NOT* exported

     * The number of current senders in a group chat is not exported; all senders's/(non-deleted) messages are exported
     
     * 'Polls' are exported as text in the format of a 'regular' message; the exported format only contains the number of votes per option (not which sender voted for each option)

     * 'Event' details are *NOT* exported; only the timestamp/sender of the event is exported with a 'blank' message, ie.
         [DD/M/YY, HH:mm:ss] sender:

     * ''View once' images/videos/voice messages are *NOT* exported; replaced with the "attachment_omitted_message" ie.:
             (U+201E)[DD/M/YY, HH:mm:ss] sender: attachment_omitted_message

     * 'Disappearing' messages are exported as 'normal' messages while they have not 'disappeared'

     * Any icons associated with voice/video calls (missed/in progress/completed) are *NOT* exported

     * "Like/dislike" icons are *NOT* exported

     * 'Pinned messages' are not exported, however:
         a) the original message is exported per the standard format for that message;
         b) and the 'Broadcast' message of the "pinned message" (i.e. 'yellow, centered' message) is exported as a 'normal' message with the message text "[person] pinned a message"

     * 'Bullets' (i.e •; entered as "- ") in messages are exported as "- "

     * 'UIAlertController-like' popover messages with a prompt (Example popover message: "You were added by someone who's not in your contacts"; "Phone number from X - Not a contact - No common groups"; "This sender is not in your contacts."; "You are receiving mesages from this business.". Example prompt: "Add Contact"/"Block"; "Report"/"Block"/"Continue") are *NOT* exported

     * Chats in a 'Community' are treated as 'regular' chats, no 'Community' information is exported
     

     **Generating PDF from chat messages limitations**

     * Formatted 'text' in messages (i.e. italics, bold, strikethrough, bulleted list, numbered list, quote, inline code) is not generated to PDF; only the raw text of the message, i.e the syntax is included in the generated message

     * Mentions (i.e. @name) is not generated to PDF; only the raw text of the message, i.e @phone_number is used in the generated message

     * PDFs generated from chats exported in non-english languages may not generate attachment messages (image/video/voice etc) with placeholder images when the chat export was done "Without Media"; instead the attachment message will be generated as a 'normal' text message

     * "System" messages (i.e. 'blue, centered'/'off-white, centered' messages) from the WhatsApp platform are treated as a 'normal' message from either:
         a) sender = chat_name; or
         b) sender = sender_name
         (NOTE: if chat_name (or group name/"subject") has been changed multiple times, then the message sender may not match the exported chat filename)
         (NOTE: In a group chat, an admin adding/removing a user to the group chat is treated as a 'normal' message from the user that was added/removed (ie. the user is the sender))

     * 'Broadcast' messages (i.e. 'yellow, centered' messages; such as the encryted chat notice) are treated as a 'normal' message from sender with name = chat_name, note that for 1-to-1 chats the chat_name = other_senders_name
     
     * Deleted messages that have been exported are treated as 'normal' messages from the sender with the 'deleted message' message (i.e. "This message was deleted"; "You deleted this message"); as opposed to an icon next to a grey italics 'deleted message' message per WhatsApp
     
     * "Edited' messages that have been exported are treated as 'normal' messages with the suffix "<This message was edited>" (as opposed to the "Edited _timestamp_" being displayed in place of the 'sent timestamp' under the message contents)

     * Messages with prompts/action buttons are treated as 'normal' messages (i.e without the prompts/action buttons)

     * There is no indication of 'unread' messages in the generated PDF (i.e "X UNREAD MESSAGES" banners)

     * 'Missed call' messages are treated as a 'normal' message from the sender (as opposed to a 'blue, centered'/'off-white, centered' message; or icon message with text "Missed voice/video call /nTap to call back")

     * 'In progress call' messages are treated as a 'normal' message from the sender (as opposed to an icon message with text ""Voice/Video call /nN joined • Tap to Join"")

     * 'Completed call' messages are treated as a 'normal' message from the sender (as opposed to an icon message with text "Voice/Video call /n_duration_")

     * 'Completed group call' messages are treated as a 'normal' message from the sender (as opposed to an icon message with text "Voice/Video call /n_duration_ N joined")
     
     * Generated message "Invitation to join my Whatsapp group" is treated as a "system" message (i.e. 'blue, centered' message/'off-white, centered' message) with the format:
         sender:

     * Generated message for an "Invite to Group via link" message (i.e message text "Invitation to jon my WhatsApp group") and associated 'group chat attachment' are treated as a "system" messages (i.e. 'blue, centered'/'off-white, centered' messages)'blank' message with text:
             sender:

     * Generated message for an "Invite to Group via link" message (with: icon, "Join Group" button; forward button; and user message) is treated as a 'normal' message with only the 'user message text' (including the chat URL)
     
     * Sender profile pics from group chats are not replicated in the received messages in the generated PDF
     
     * Group chats with 2 or less senders (including the group itself, i.e. sender with name = chat_name) are treated as a non-group chat (i.e. received messages do not include the sender's name)

     * Group chats and non-group chats with 1 sender are treated as a non-group chat; all the messages are treated as 'sent' (i.e. you have to choose at least one 'sender' to generate a PDF)

     * Chats with no sender/no messages cannot be exported (i.e. the 'Export Chat' option is disabled)

     * 'Polls' are treated as a 'normal' message and generated as a text representation only (format only includes number of votes per option, not which sender voted for each option)

     * 'Events' are treated as a "system" message (i.e. 'blue/off-white, centered' messages) **here**

     * Link previews (ie URLs) are *NOT* generated to PDF

     * Document previews are *NOT* generated to PDF

     * 'View once' attachments (that have been viewed) are treated as a 'normal' message from the sender (as opposed to "view once icon" inline with message text "Opened"/"Photo"/"Video"/"Voice message") with message text "attachment omitted"

     * Photos (.jpg) are stored in ChatPDF and in the generated PDF are:
         - a 'normal' message (when "4. Include images" = false AND exported chat file "Without Media") with text:
             image omitted
         - replaced with a placeholder image (when "4. Include images" = true AND exported chat file "Without Media")
         - or (when "4. Include images" = false AND exported chat file "Attach Media") by a 'normal' message with format:
             <attached: messageID-PHOTO-timestamp.jpg>
         - a resized copy of the source image (when "4. Include images" = true AND exported chat file "Attach Media")
         
     * When user has exported chat file "Without Media" but selected to "Include images" a placeholder image is used to represent the missing image

     * Contacts (.vcf) are stored in ChatPDF and in the generated PDF are:
          - a 'normal' message (when "4. Include images" = false AND exported chat file "Without Media") with text:
              Contact card omitted
         - replaced with placeholder image (when "4. Include images" = true AND exported chat file "Without Media")
         - or (when "4. Include images" = false AND exported chat file "Attach Media") by a 'normal' message with format:
             <attached: messageID-contact_name-timestamp.vcf>
         - or (when "4. Include images" = true AND exported chat file "Attach Media") by a 'normal' message with format:
             given_name middle_name family_name
             phone_number(s) 1-N
             email(s) 1-N
             address(es) 1-N //address contains: street \n city \n state \n postcode \n country
             
     * Locations are only shown as a message containing the URL (i.e. no map/link preview), format:
         Location: https://maps.google.com/?q=lattitude,longitude
     
     * GIFs (.mp4) are not saved to ChatPDF, instead a thumbnail of the GIF is saved. In the generated PDF the GIF is represented as:
         - a 'normal' message (when "4. Include images" = false AND exported chat file "Without Media") with text:
             GIF omitted
         - a placeholder image (when "4. Include images" = true AND exported chat file "Without Media")
         - a 'normal' message (when "4. Include images" = true/false AND exported chat file "Attach Media") with format:
             <attached: messageID-GIF-timestamp.mp4>
         - the thumbnail of the GIF (when "4. Include images" = true AND exported chat file "Attach Media") or a placeholder image when the thumbnail cannot be found
             
     * Videos (.mp4, .MOV) are not saved to ChatPDF, instead a thumbnail of the video is saved. In the generated PDF the video is represented as:
         - a 'normal' message (when "4. Include images" = false AND exported chat file "Without Media") with text:
             video omitted
         - a placeholder image (when "4. Include images" = true AND exported chat file "Without Media")
         - a 'normal' message (when "4. Include images" = false AND exported chat file "Attach Media") with format:
             <attached: messageID-VIDEO-timestamp.mp4>
         - the thumbnail of the video (when "4. Include images" = true AND exported chat file "Attach Media") or a placeholder image when the thumbnail cannot be found

     * Voice Messages (.opus) are not saved to ChatPDF nor generated to PDF, instead replaced in the genearated PDF by:
         - a 'normal' message (when "4. Include images" = false AND exported chat file "Without Media") with text:
             audio omitted
          - a placeholder image (when "4. Include images" = true AND exported chat file "Without Media")
          - or (when "4. Include images" = true/false AND exported chat file "Attach Media") by a 'normal' message with format:
             <attached: messageID-AUDIO-timestamp.opus>
     
     * Documents (pdf; doc; docx; txt; zip; jpeg; jpg; png; mp4; MOV; opus?) are not saved to ChatPDF nor generated to PDF, instead replaced in the genereated PDF by:
         - a 'normal' message (when "4. Include images" = false AND exported chat file "Without Media") with text:
             document omitted
          - a placeholder image (when "4. Include images" = true AND exported chat file "Without Media")
          - or (when "4. Include images" = true/false AND exported chat file "Attach Media") by a 'normal' message with format:
             <attached: messageID-filename.filetype_extension>
                 or
             "filename.pdf" • ‎n page(s) (U+201E)<attached: messageID-"filename.pdf">

     * Stickers (.webp) are stored in ChatPDF and in the generated PDF are:
          - a 'normal' message (when "4. Include images" = false AND exported chat file "Without Media") with text:
              sticker omitted
          - replaced with a placeholder image (when "4. Include images" = true AND exported chat file "Without Media")
          - or (when "4. Include images" = false AND exported chat file "Attach Media") by a 'normal' message with format:
              <attached: messageID-STICKER-timestamp.webp>
          - a resized copy of the source sticker (when "4. Include images" = true AND exported chat file "Attach Media")

     * Messages in the generated PDF with an image/placeholder icon contain the underlying 'normal' message (i.e "X omitted" or the exported attachment syntax) in a transparent text colour, i.e it can still be searched/selected in a PDF viewer app


*/

import Foundation
import UIKit

class Helper {
    
    static var app: Helper = {
        return Helper()
    }()
    
    let animationTime: Double = 0.25
    
    let colorPrimary = UIColor(red: 224.0/255, green: 31.0/255, blue: 31.0/255, alpha: 1) // hex: #E01F1F
    let colorPrimaryCellSelected = UIColor(red: 250.0/255, green: 180.0/255, blue: 180.0/255, alpha: 0.8) // hex: FAB3B3
    
    let colorSecondary = UIColor(red: 16.0/255, green: 209.0/255, blue: 224.0/255, alpha: 1) //10D1E0
    let colorTertiary = UIColor(red: 135.0/255, green: 16.0/255, blue: 224.0/255, alpha: 1) //8710E0
    
    
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
                    print(".zip file found!")
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
