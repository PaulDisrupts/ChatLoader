//
//  Message+CoreDataProperties.swift
//  ChatLoader
//
//  Created by Paul Michael Whiten on 27/6/21.
//
//

import Foundation
import CoreData


extension Message {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Message> {
        return NSFetchRequest<Message>(entityName: "Message")
    }

    @NSManaged public var attachmentName: String?
    @NSManaged public var attachmentType: Int16
    @NSManaged public var dateSend: String?
    @NSManaged public var dd: Int16
    @NSManaged public var messageContent: String?
    @NSManaged public var messageID: Int64          //starts at 0
    @NSManaged public var mm: Int16
    @NSManaged public var outgoing: Bool
    @NSManaged public var sender: String?
    @NSManaged public var senderColour: Int16
    @NSManaged public var timeSend: String?
    @NSManaged public var yyyy: Int16
    @NSManaged public var fromChat: Chat?

}

extension Message : Identifiable {

}
