//
//  Message+CoreDataProperties.swift
//  ChatLoader
//
//  Created by Paul Michael Whiten on 27/6/21.
//
//  For storing the individual messages in a WhatsApp chat; Many-to-1 with Chat
//

import Foundation
import CoreData


extension Message {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Message> {
        return NSFetchRequest<Message>(entityName: "Message")
    }

    @NSManaged public var attachmentName: String?
    @NSManaged public var attachmentType: Int16     //refer to Helper.attachmentTypes
    @NSManaged public var dateSend: String?
    @NSManaged public var dd: Int16
    @NSManaged public var messageContent: String?
    @NSManaged public var messageID: Int64          //starts at 0
    @NSManaged public var mm: Int16
    @NSManaged public var outgoing: Bool            //0 = incoming; 1 = outgoing
    @NSManaged public var sender: String?
    @NSManaged public var senderColour: Int16       //used for assigning a colour in group chats
    @NSManaged public var timeSend: String?
    @NSManaged public var yyyy: Int16
    @NSManaged public var fromChat: Chat?

}

extension Message : Identifiable {

}
