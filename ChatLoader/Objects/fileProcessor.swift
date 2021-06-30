//
//  fileProcessor.swift
//  ChatLoader
//
//  Created by Paul Michael Whiten on 12/2/21.
//

// handles the file processing on a background process

import Foundation
import UIKit
import CoreData

protocol protocolFileProcessor {
    func updateProgress(percentComplete:Int)
    func processingComplete(message:String)
}

/*  ****Happy Path****
 
    processFile(initInputFileURL:URL)
        getchatName()
        unzipFile()
        validateFileFromURL()
            processChatFile(inputFile:[String], dateTimeDelimiter:String)
                setupchildContext()
                setupDateFormatters()
                self.delegate?.promptUserInput(distinctSenders: distinctSendersList)
 */

class fileProcessor:NSObject {
    
    let printToggle:Bool = false
    
    let importedChatsDir = "importedChats"
    let tempDir = "importedChats/tempDir"
    
    let whatsappFilePrefix = "WhatsApp Chat - "
    
    var delegate:protocolFileProcessor?
    
    var childContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
    
    var previousMessageID:NSManagedObjectID?  //used for appending subsequent lines to the previous message
    
    var inputFileURL:URL?       //
    var importedChatsURL:URL?   //
    var tempDirURL:URL?
    var fileToProcessURL:URL?  //the _chat.txt file
    
    var isSavingCoreData:Bool = false
    
    var chatName:String?
    var selectedChat:Chat?
    
    let localeDateFormatter = DateFormatter()
    let localeCalendar = Calendar(identifier: Calendar.Identifier.gregorian)
    var locale:String?
    
    var groupChatSenderIndex = [String]()    //used to index the senders for group chats
    

    func processFile(initInputFileURL:URL) {
        
        /*
         1. setup URLs
         2. get file name
         3. unzip files, find _chat.txt, remove unwanted files
         4. process _chat.txt file
         5. rename directory --> called in func saveContexts() {
 
         */
        
        //1. setup URLs
        inputFileURL = initInputFileURL
        
        if let libraryDir = FileManager().urls(for: .libraryDirectory, in: .userDomainMask).first as URL? {
            
            importedChatsURL = libraryDir.appendingPathComponent(UserDefaults.standard.string(forKey: "appDirectory")!).appendingPathComponent(importedChatsDir)
            
            tempDirURL = libraryDir.appendingPathComponent(UserDefaults.standard.string(forKey: "appDirectory")!).appendingPathComponent(tempDir)
        }
        
        if printToggle {
            print("\n*****inputFileURL: \(inputFileURL!.path)")
            print("\n*****tempDirURL: \(tempDirURL!.path)")
        }
        
        //2. get file name
        getchatName()
        
        //3. unzip files, find _chat.txt, remove unwanted files
        unzipFile()
        
        //4. process _chat.txt
        if fileToProcessURL != nil {
            validateFileFromURL()
        }
    }

    
    func getchatName() {
        
        //file type is either .zip or .txt
        if inputFileURL!.path.range(of: ".zip") != nil {
            
            if inputFileURL!.path.range(of: "Inbox/") != nil {
                //file loaded from "Copy to ChatLoader" in UIActivityViewController
                chatName = String(inputFileURL!.path[inputFileURL!.path.range(of: "Inbox/")!.upperBound..<inputFileURL!.path.range(of: ".zip")!.lowerBound])
                
            } else {
                //file loaded from file directory
                chatName = String(inputFileURL!.path[(inputFileURL!.path.range(of: "/", options: .backwards)?.upperBound)!..<inputFileURL!.path.range(of: ".zip")!.lowerBound])
            }
        }
        
        if let range = chatName!.range(of: whatsappFilePrefix) {
            chatName!.removeSubrange(range)
        }
        
        print("\n\nfileProcessor_chatName: \(chatName!)\n")
    }
    
    
    func unzipFile() {
        
        //create temp dir: importedChats/tempDir
        let fileManager = FileManager()
        
        if !fileManager.fileExists(atPath: (tempDirURL!.path)) {
            
            do {
                try fileManager.createDirectory(atPath: (tempDirURL!.path), withIntermediateDirectories: true, attributes: nil)
                
            } catch let error as NSError {
                print("ERROR: try fileManager.createDirectoryAtPath(newDir.path!, withIntermediateDirectories: true, attributes: nil): Failed to create dir at \(String(describing: tempDirURL!.path)); error: \(error.localizedDescription)")
            }
        }
        
        
        //unzip to tempDir
        WPZipArchive.unzipFile(atPath: inputFileURL!.path, toDestination: tempDirURL!.path)
        

        //find the _chat.txt file (assumes only single .txt file in .zip), find the image files; delete all other files
        do {
            let unzippedFiles = try fileManager.contentsOfDirectory(atPath: tempDirURL!.path) as [String]?
            
            for f in unzippedFiles! {
                
                let tempURL = tempDirURL!.appendingPathComponent(f)

                //Save _chat.txt and specified attachment types
                if f.range(of: ".txt") != nil {
                    
                    //assign URL of _chat.txt
                    fileToProcessURL = tempURL
                    
                    if printToggle {
                     print("\nupdated fileToProcessURL: \(fileToProcessURL!.path)")
                    }
                    
                } else if f.hasSuffix(".jpg") {
                    //keep this file type
                    
                } else if f.hasSuffix(".png") {
                    //keep this file type
                    
                } else {
                    //remove unwanted file(s)
                    
                    do {
                        try fileManager.removeItem(atPath: tempURL.path)
                        print("\nfunc unzipFile(): removed file: \(tempURL.lastPathComponent)")
                        
                    } catch let error as NSError {
                        print("ERROR: func unzipFile(); try fileManager.removeItemAtPath(tempURL.path!): \(error.localizedDescription)")
                    }
                }
            }//for f in unzippedFiles! {
            
        } catch let error as NSError {
            print("ERROR: func unzipFile(); let unzippedFiles = try fileManager.contentsOfDirectoryAtPath(inboxDir.path!) as [String]!: \(error)")
        }
    }
    
    
    //process files (both 12/24hr) in the users current locale
    func validateFileFromURL() {
        
        var processed = false
        
        // **ASSUMPTION**: WhatsApp message end of message sequence is: \r\n
        if let mytext = (try? String(contentsOf: fileToProcessURL!, encoding: String.Encoding.utf8))?.components(separatedBy: "\r\n") {
            

            //validate file formatting
            if mytext.first?.first == "[" {

                //validate the message formatting in the file
                if let inputLine = mytext.first {
                    
                    //[DD/M/YY, HH:mm:ss] sender: message
                    //2018 file format, 2 senders
                    if let indexDateTime = inputLine.range(of: ", "){
                        if let indexTimeSender = inputLine.range(of: "] ") {
                            if indexDateTime.upperBound<indexTimeSender.lowerBound {
                                
                                if let indexSenderMessage = inputLine.range(of: ": ") {
                                    if indexTimeSender.upperBound<indexSenderMessage.lowerBound {
                                        
                                        print("processFile2018(inputFile: mytext)")
                                        processed = true
                                        processChatFile(inputFile: mytext, dateTimeDelimiter: ", ")
                                    }
                                    
                                } else if let indexTimestampMessage = inputLine.range(of: " ", options: [], range: indexTimeSender.upperBound..<inputLine.endIndex, locale: nil) {
                                    //2018 file format, 2+ senders (ie group chat); or encryption message
                                    
                                    if indexTimeSender.upperBound<indexTimestampMessage.lowerBound {
                                        
                                        print("group chat: processFile2018(inputFile: mytext)")
                                        processed = true
                                        processChatFile(inputFile: mytext, dateTimeDelimiter: ", ")
                                    }
                                }
                            }//if indexDateTime.upperBound<indexTimeSender.lowerBound {
                        }//if let indexTimeSender = inputLine.range(of: "] ") {
                    }//if let indexDateTime = inputLine.range(of: ", "){
                    
                    
                    //[DD/M/YY HH:mm:ss] sender: message
                    //2018 alternate file format, 2 senders
                    if !processed {
                        if let indexDateTime = inputLine.range(of: " "){
                            if let indexTimeSender = inputLine.range(of: "] ") {
                                if indexDateTime.upperBound<indexTimeSender.lowerBound {
                                    
                                    if let indexSenderMessage = inputLine.range(of: ": ") {
                                        if indexTimeSender.upperBound<indexSenderMessage.lowerBound {
                                            
                                            print("processFile2018_alternateDateFormat(inputFile: mytext)")
                                            processed = true
                                            processChatFile(inputFile: mytext, dateTimeDelimiter: " ")
                                        }
                                        
                                    } else if let indexTimestampMessage = inputLine.range(of: " ", options: [], range: indexTimeSender.upperBound..<inputLine.endIndex, locale: nil) {
                                        //2018 alternate file format, 2+ senders (ie group chat); or encryption message
                                        
                                        if indexTimeSender.upperBound<indexTimestampMessage.lowerBound {
                                            
                                            print("group chat: processFile2018_alternateDateFormat(inputFile: mytext)")
                                            processed = true
                                            processChatFile(inputFile: mytext, dateTimeDelimiter: " ")
                                        }
                                    }
                                }//if indexDateTime.upperBound<indexTimeSender.lowerBound {
                            }//if let indexTimeSender = inputLine.range(of: "] ") {
                        }//if let indexDateTime = inputLine.range(of: " "){
                    }//if !processed {
                }//if let inputLine = mytext.first {
            }//if mytext.first?.first == "[" {
        }//if let mytext = (try? String(contentsOf: fileToProcessURL!, encoding: String.Encoding.utf8))?.components(separatedBy: "\r\n") {
        
        //file format of fileToLoad! not recognised
        if !processed {
            errorLoadingFile()
        }
    }
    
    
    func renameDirectory() {
        
        //rename folder then delete .zip file
        let fileManager = FileManager()
        
        do {
            
            deleteFiles(zipAndDirectory: false)
            
            let directoryIndex = UserDefaults.standard.integer(forKey: "totalFilesLoaded") + 1
            let directoryName = Helper.app.formatChatIDToDirectoryName(chatID: directoryIndex)
            try fileManager.moveItem(at: tempDirURL!, to: importedChatsURL!.appendingPathComponent(String(directoryName)))
            
            //update UserDefaults
            UserDefaults.standard.set(directoryIndex, forKey: "totalFilesLoaded")
            UserDefaults.standard.synchronize()
            

        } catch let error as NSError {
            print("ERROR: try fileManager.moveItem(at: tempDirURL!, to: importedChatsURL!.appendingPathComponent(String(directoryName)))\nFailed to rename dir at \(String(describing: tempDirURL!.path));\nError code: \(error.localizedDescription)")
        }
    }
    
    
    //MARK: process file functions
    func setupDateFormatters() {
        
        locale = "\((Locale.current as NSLocale).object(forKey: NSLocale.Key.identifier)!)"
        
        print("func setupDateFormatters() {, locale: \(locale!)")
        if printToggle {
            print("func setupDateFormatters() {, locale: \(locale!)")
        }
        
        
        //for Simulator make sure the locale is set to the same as the WhatsApp exported chat
        localeDateFormatter.dateFormat = (Locale.current as NSLocale).object(forKey: NSLocale.Key.identifier) as? String
        
        localeDateFormatter.dateStyle = .short
    }
    
    
    //takes in WhatsApp formatted date only, including any suffexes
    func convertDateLocale_WhatsApp(_ inputDateString:String) -> (yyyy:Int?, MM:Int?, dd:Int?, yyyyMMdd:String?) {
        
        var tempDate = inputDateString
        
        //[DD/M/YY, HH:mm:ss] sender: image omitted
        //sends through as [DD/M/YY or [DD/M/YY,
        if tempDate.range(of: "[") != nil {
            //            print("old tempDate: \(tempDate)")
            tempDate.remove(at: tempDate.startIndex)
            //            print("new tempDate: \(tempDate)")
        }
        
        //clean out punctuation! (older format uses " " to seperate the date and time; .zip format uses ", ")
        if tempDate.range(of: ",") != nil {
            tempDate = String(inputDateString[inputDateString.startIndex..<inputDateString.index(before: inputDateString.endIndex)])
        }
        

        if let inputDate = localeDateFormatter.date(from: tempDate) {
            
            let components = (localeCalendar as NSCalendar).components([.year, .month, .day], from: inputDate)
            
            var yyyy = String(describing: components.year!)
            if yyyy.count == 2 {
                yyyy = "20\(yyyy)"
            }
            
            var MM:String = String(describing: components.month!)
            if MM.count == 1 {
                MM = "0\(MM)"
            }
            
            var dd = String(describing: components.day!)
            if dd.count == 1 {
                dd = "0\(dd)"
            }
            
            return (Int(yyyy), Int(MM), Int(dd), "\(yyyy)/\(MM)/\(dd)")
            
        } else {
            
            print("if let inputDate = localeDateFormatter.dateFromString(tempDate) {: \(inputDateString)")
            
            return (nil, nil, nil, "f")
        }
    }
    
    
    func updateLoadProgress(_ progressUpdate:Int, totalLines:Int) {

        let tempValue = round(Double(progressUpdate)/Double(totalLines)*100)
        
        //update the UI on the main queue
        DispatchQueue.main.async(execute: {
            self.delegate?.updateProgress(percentComplete: Int(tempValue))
        })
    }
    
    
    func appendMessage(_ inputLine:String) {
        
        if self.previousMessageID != nil {
            
            if let prevMsg = self.childContext.object(with: self.previousMessageID!) as? Message {
                prevMsg.messageContent = prevMsg.messageContent!+"\n"+inputLine.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
            
        } else {
            //valid message not yet found (first line of the file); 'break' is no longer called and the rest of file still will be processed (eg. prefixed lines/incorrectly formatted text)
            //errorLoadingFile() is now called *after* the entire file is processed
        }
    }
    

    func getGroupSenderIndex(_ senderName:String) -> Int {
        
        if let i = groupChatSenderIndex.firstIndex(of: senderName) {
            return i
            
        } else {
            groupChatSenderIndex.append(senderName)
            return groupChatSenderIndex.count-1
        }
    }
    
    
    func errorLoadingFile() {
        print("func errorLoadingFile()")
        
        deleteFiles(zipAndDirectory: true)
        
        DispatchQueue.main.async(execute: {
            self.delegate?.processingComplete(message: "error loading file")
        })
    }
    
    
    func deleteFiles(zipAndDirectory:Bool) {
        
        let fileManager = FileManager()
        
        if zipAndDirectory {
            
            //delete temp directory and contents
            do {
                try fileManager.removeItem(at: tempDirURL!)
                
            } catch let error as NSError {
                print("ERROR: try fileManager.removeItem(at: tempDirURL!.path)\nFailed to remove file \( inputFileURL!.path));\nError code: \(error.localizedDescription)")
            }
        
        } else {
            //remove the _chat.txt file only
            
            do {
                try fileManager.removeItem(atPath: fileToProcessURL!.path)
                
                if printToggle {
                    print("func deleteFiles(zipAndDirectory:Bool): removed file at: \(fileToProcessURL!.path)")
                }
                
            } catch let error as NSError {
                print("ERROR: func deleteFiles(zipAndDirectory:Bool); try fileManager.removeItemAtPath(fileToProcessURL!.path!): \(error.localizedDescription)")
            }
        }
        
        
        //remove the imported .zip file if it is *not* the simulator, ie from the devices 'Inbox'
        #if !targetEnvironment(simulator)
//            print("#if !targetEnvironment(simulator)")
        
            do {
                try fileManager.removeItem(at: inputFileURL!)
                
            } catch let error as NSError {
                print("ERROR: try fileManager.removeItem(at: inputFileURL!)\nFailed to remove file \(String(describing: inputFileURL!.path));\nError code: \(error.localizedDescription)")
            }
        
        #endif
    }
    

    func processChatFile(inputFile:[String], dateTimeDelimiter:String) {
        //file _chat.txt has been found
        
        //CoreData
        setupchildContext()
        
        setupDateFormatters()
        
        //add chat to the temporary managed object context
        selectedChat = Chat(entity: NSEntityDescription.entity(forEntityName: "Chat", in: childContext)!, insertInto: childContext) as Chat
        
        selectedChat!.chatName = chatName!
        selectedChat!.dateLoad = NSDate()
        
        selectedChat!.chatID = Int16(UserDefaults.standard.integer(forKey: "totalFilesLoaded") + 1) // chatID updated in func saveContexts()
        
        
        /*
         WhatsApp line format:
         [DD/M/YY, HH:mm:ss] sender: message
         
         or alternate language format:
         [DD/M/YY HH:mm:ss] sender: message
         */

        let lineCount = inputFile.count     //number of messages = (lineCount-1) because of the 'end of file' char/line
        var distinctSenders = Set<String>()
        var i = 0                           //message count from 0 to (lineCount-2); 'end of file' char/line not counted
        var attachmentCount:Int = 0
        
        var onePercent:Int = 1
        if lineCount > 100 {
            onePercent = Int(round(Double(lineCount/100)))
        }
        
        //process file in background
        DispatchQueue.global(qos: .background).async(execute: {
            
            //process the file line by line
            NSLog("**START: process file - # of lines = \(inputFile.count)")
            for inputLine in inputFile {
                
                if i == (lineCount-1) {
                    print("******last line: i = (lineCount-1), #\(i): \(inputLine)")
                }
                
                if i == lineCount {
                    print("******should not trigger: i = lineCount, #\(i): \(inputLine)")
                }
                
                if i%onePercent == 0  {
                    self.updateLoadProgress(i, totalLines: lineCount)
                }
                
                //process input line
                //[DD/M/YY, HH:mm:ss] sender: message
                if let indexDateTime = inputLine.range(of: dateTimeDelimiter){
                    if let indexTimeSender = inputLine.range(of: "] ") {
                        if indexDateTime.upperBound<indexTimeSender.lowerBound {
                            
                            // localeDateFormatter tuple return (optimised)
                            let dateTuple2 = self.convertDateLocale_WhatsApp(String(inputLine[inputLine.index(after: inputLine.startIndex)..<indexDateTime.lowerBound]))
                            
                            //unrecognised date format; append to previous message
                            if dateTuple2.yyyyMMdd! == "f" {
                                
                                self.appendMessage(inputLine)
                                
                            } else {
                                //line has passed format validation, create message object
                                
                                let message = Message(entity: NSEntityDescription.entity(forEntityName: "Message", in: self.childContext)!, insertInto: self.childContext) as Message
                                
                                self.previousMessageID = message.objectID
                                
                                //populate message details
                                message.fromChat = self.selectedChat!
                                message.messageID = Int64(i)
                                
                                message.timeSend = String(inputLine[indexDateTime.upperBound..<indexTimeSender.lowerBound])
                                
                                message.dateSend = dateTuple2.yyyyMMdd!
                                message.dd = Int16(dateTuple2.dd!)
                                message.mm = Int16(dateTuple2.MM!)
                                message.yyyy = Int16(dateTuple2.yyyy!)
                                
                                message.outgoing = false
                                
                                
                                //process message contents
                                if let indexSenderMessage = inputLine.range(of: ": ", options: [], range: indexTimeSender.upperBound..<inputLine.endIndex, locale: nil) {
                                    
                                    message.sender = String(inputLine[indexTimeSender.upperBound..<indexSenderMessage.lowerBound])
                                    
                                    distinctSenders.insert(message.sender!)
                                    
                                    message.messageContent = inputLine[indexSenderMessage.upperBound..<inputLine.endIndex].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                    
                                    if message.messageContent!.hasSuffix("omitted") {
                                        attachmentCount += 1
                                    }
                                    
                                } else {
                                    //cannot distinguish between sender and message; assume that it is a group status update; note: this will be set as outgoing = false
                                    
                                    message.sender = "group_status_update"
                                    message.messageContent = inputLine[indexTimeSender.upperBound..<inputLine.endIndex].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                }
                                
                                message.senderColour = Int16(self.getGroupSenderIndex(message.sender!))
                                
                                i += 1 // only increment on messages and not on lines
                            }
                            
                        } else { //if indexDateTime.endIndex<indexTimeSender.startIndex {
                            self.appendMessage(inputLine)
                            //                                print("if indexDateTime.endIndex<indexTimeSender.startIndex {: \(inputLine)")
                        }
                        
                    } else { //if let indexTimeSender = inputLine.range(of: "] ") {
                        //append to previous message
                        self.appendMessage(inputLine)
                        //                            print("if let indexTimeSender = inputLine.rangeOfString(: \(inputLine)")
                    }
                    
                } else { //if let indexDateTime = inputLine.range(of: dateTimeDelimiter){
                    
                    //append to previous message if it is *not* end of file
                    //ie last line ('end of file' char) is when: i = (lineCount-1)
                    if (i+1 != lineCount) {
                        self.appendMessage(inputLine)
                        print("**line #\(i) appended")
                    }
                }
                            
            } //for inputLine in inputFile {
            
            NSLog("**END: process file")
            
            //update chat
            if self.previousMessageID != nil {
                //loading file complete, at least one message processed
                
                //update chat count and senders
                self.selectedChat!.senderCount = Int16(distinctSenders.count)
                
                var distinctSendersList:String = ""
                for senderName in distinctSenders {
                    distinctSendersList = distinctSendersList + "\(senderName)\n"
                }
                
                distinctSendersList = String(distinctSendersList.dropLast(1))   //remove the last \n character
                self.selectedChat!.senderList = distinctSendersList
                
                if self.printToggle {
                    print("fileProcessor_distinctSendersList:\n\(distinctSendersList)")
                }
                
                
                //update the UI on main queue
                DispatchQueue.main.async(execute: {
                    
                    //finished processing, save to coredata in parent VC
                    self.delegate?.processingComplete(message: "saving")
                    self.saveContexts()
                })
                
            } else {//if self.previousMessageID != nil {
                //no messages processed (wrong file format?), delete file
                print("} else {//if self.previousMessageID != nil {")
                self.errorLoadingFile()
            }
            
        }) //dispatch_async(dispatch_get_global_queue(qos, 0), {; //process file in background
    }
    
    
    //MARK: CoreData
    func setupchildContext() {
        childContext.parent = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    
    func saveContexts() {
        
        isSavingCoreData = true
        
        if childContext.hasChanges {
            
            do {
                try childContext.save()
                
                childContext.parent?.perform({
                    
                    do {
                        try self.childContext.parent?.save()
                        self.isSavingCoreData = false
                        
                        //5. rename directory --> called in func saveContexts() {
                        self.renameDirectory()
                        
                        DispatchQueue.main.async(execute: {
                            self.delegate?.processingComplete(message: "saved")
                        })
                        
                    } catch let error as NSError {
                        print("ERROR: templateModalPopoverViewController.swift; func saveContexts(); try self.childContext.parentContext?.save(): \(error)")
                    }
                })
                
            } catch let error as NSError {
                print("ERROR: templateModalPopoverViewController; func saveContexts(); try childContext.save(): \(error)")
            }
        }
    }
    
    
    func finishSaving() {
        print("func finishSaving () {")
    }
    
}
