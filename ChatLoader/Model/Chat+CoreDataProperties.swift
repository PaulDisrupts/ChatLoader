//
//  Chat+CoreDataProperties.swift
//  ChatLoader
//
//  Created by Paul Michael Whiten on 27/6/21.
//
//  For storing details of a WhatsApp chat; 1-to-many with Message
//

import Foundation
import CoreData


extension Chat {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Chat> {
        return NSFetchRequest<Chat>(entityName: "Chat")
    }

    @NSManaged public var chatID: Int16         //first Chat loaded will be 0001
    @NSManaged public var chatName: String?
    @NSManaged public var dateLoad: NSDate?
    @NSManaged public var senderCount: Int16
    @NSManaged public var senderList: String?
    @NSManaged public var messages: Message?
    
    func printChat() {
        print("chatID: \(chatID)")
        print("chatName: \(String(describing: chatName))")
        print("dateLoad: \(Helper.app.converNSDateToLocalDate(inputDate: self.dateLoad!))")
        print("senderCount: \(senderCount)")
        print("senderList: \(String(describing: senderList))")
    }

}

extension Chat : Identifiable {

}
