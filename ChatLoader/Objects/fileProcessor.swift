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
    func processingStarted()
    func updateProgress(percentComplete:Int)
    func processingError()
    func processingSaving()
    func processingComplete()
}

/*
    ***Happy Path***
    processExportedFile(initInputFileURL:URL)
        getChatName()
        unzipExportedFile()
        validateTextFileFormat()
            processTextFile(inputFile:[String], dateTimeDelimiter:String)
                saveContexts()
                    self.renameDirectory()
                    self.delegate?.processingComplete(message: "saved")
 */

class fileProcessor:NSObject {
    
    let printToggle:Bool = false
        
    var delegate:protocolFileProcessor?
    
    var childContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
    
    var previousMessageID:NSManagedObjectID?  //used for appending subsequent lines to the previous message
    
    var inputFileURL:URL?      //the .zip file; note that the filename does not have to be prefixed with Helper.app.whatsappZipFilePrefix, ie. "WhatsApp Chat - "
    var fileToProcessURL:URL?  //the _chat.txt file; note that the text filename does not have to be "_chat.txt"
    var tempDirURL:URL?        //temp directory for unzipping exported chats - either deleted if loading chat fails or renamed corresponding to the Chat.chatID
    
    var isSavingCoreData:Bool = false
    
    var chatName:String?
    var selectedChat:Chat?
    
    let localeDateFormatter = DateFormatter()
    let localeCalendar = Calendar(identifier: Calendar.Identifier.gregorian)
    var locale:String?
    
    var groupChatSenderIndex = [String]()    //used to index the senders for group chats
    

    //MARK: class functions
    init(delegate: protocolFileProcessor, inputFile: URL) {
        super.init( )
    
        /*
         1. setup URLs, delegate
         //call processExportedFile() from delegate object
         2. get file name
         3. unzip files, find _chat.txt, remove unwanted files
         4. process _chat.txt file
         5. rename directory --> called in func saveContexts() {
         */
        
        //1. setup URLs, delegate
        self.delegate = delegate
        self.inputFileURL = inputFile   //always of filetype .zip
        self.tempDirURL = Helper.app.tempDirURL()
    }
    
    
    func processExportedFile() {
        //errorLoadingFile() called when:
        //a) No .txt file found in the .zip (ie. inputFileURL, which has to be of type .zip); note that the text filename does not have to be "_chat.txt"
        //b) .txt file is of the wrong format
        
        if printToggle {
            print("\n*****inputFileURL: \(inputFileURL!.path)")
            print("\n*****tempDirURL: \(tempDirURL!.path)")
        }
        
        //2. get file name
        getChatName()   //note that the filename does not have to be prefixed with Helper.app.whatsappZipFilePrefix, ie. "WhatsApp Chat - "
        
        //3. unzip files, find _chat.txt, remove unwanted files
        unzipExportedFile()
        
        //4. process _chat.txt
        if fileToProcessURL != nil {
            validateTextFileFormat()
        } else {
            //a) No .txt file found in the .zip (ie. inputFileURL, which has to be of type .zip); note that the text filename does not have to be "_chat.txt"
            print("fileProcessor.swift\n\tfunc processExportedFile() {\n\t\tif fileToProcessURL != nil {\n\t\t\tERROR:.txt not found!!")
            errorLoadingFile()
        }
        
        //5. rename directory --> called in func saveContexts() {
    }

    
    func getChatName() {
        
        //file type is .zip only
        if inputFileURL!.path.range(of: ".zip") != nil {
            
            if inputFileURL!.path.range(of: "Inbox/") != nil {
                //file loaded via UIActivityViewController/'share'/"Copy to app" from an exported Whatsapp chat .zip file
                chatName = String(inputFileURL!.path[inputFileURL!.path.range(of: "Inbox/")!.upperBound..<inputFileURL!.path.range(of: ".zip")!.lowerBound])
                
            } else {
                //file loaded from file directory
                chatName = String(inputFileURL!.path[(inputFileURL!.path.range(of: "/", options: .backwards)?.upperBound)!..<inputFileURL!.path.range(of: ".zip")!.lowerBound])
            }
        }
        
        if let range = chatName!.range(of: Helper.app.whatsappZipFilePrefix) {
            chatName!.removeSubrange(range)
        }
        
        print("\n\nfileProcessor_chatName: \(chatName!)\n")
    }
    
    
    func unzipExportedFile() {
        
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
        //Feel free to use your preferred archiving library here
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
                } else {//add else if statement to keep filetypes, eg. else if f.hasSuffix(".jpg")
                    
                    //remove unwanted file(s)
                    do {
                        try fileManager.removeItem(atPath: tempURL.path)
                        print("\nfunc unzipExportedFile(): removed file: \(tempURL.lastPathComponent)")
                        
                    } catch let error as NSError {
                        print("ERROR: func unzipExportedFile(); try fileManager.removeItemAtPath(tempURL.path!): \(error.localizedDescription)")
                    }
                }
            }//for f in unzippedFiles! {
            
        } catch let error as NSError {
            print("ERROR: func unzipExportedFile(); let unzippedFiles = try fileManager.contentsOfDirectoryAtPath(inboxDir.path!) as [String]!: \(error)")
        }
    }
    
    
    //Validate _chat.txt file format based on first line/message and determine the indexDateTime delimiter
    func validateTextFileFormat() {
        
        var validFileFormat = false
        
        // **ASSUMPTION**: WhatsApp message end of message sequence is: \r\n
        if let textFileContents = (try? String(contentsOf: fileToProcessURL!, encoding: String.Encoding.utf8))?.components(separatedBy: "\r\n") {

            /*
             Expected message format depending on localization settings:
             
             [DD/M/YY, HH:mm:ss] sender: message\r\n
                or
             [DD/M/YY HH:mm:ss] sender: message\r\n
             
             Process the first line to validate the message formatting in the imported file; check the expected delimiters are in sequence:
              1) "["           --> indexDate; first char of the timestamp
              2) ", " or " "   --> indexDateTime; delimiter between date and time
              3) "] "          --> indexTimeSender; delimiter between timestamp and sender
              4) ": "          --> indexSenderMessage; delimiter between sender and message
             */
            if let inputLine = textFileContents.first {
                if let indexDate = inputLine.range(of: "[") { //1) "[" --> indexDate; first char of the timestamp
                    
                    /*
                     determine the delimiter between the date and time, ie. ", " or " " depending on the localization
                     
                     Edge case: First line/message in format:
                        [DD/M/YY HH:mm:ss] sender: "message_content_contains_', '_delimiter"\r\n
                            --> will trigger errorLoadingFile() because: (validFileFormat = false) && (indexDateTime > indexTimeSender)
                    */
                    
                    var indexDateTime:Range<String.Index>?
                    var dateTimeDelimiter:String = ", "
                    
                    indexDateTime = inputLine.range(of: dateTimeDelimiter) //2) ", "  --> indexDateTime; delimiter between date and time
                    
                    if indexDateTime == nil {
                        indexDateTime = inputLine.range(of: " ") //2) " "  --> indexDateTime; delimiter between date and time
                        dateTimeDelimiter = " "
                    }
                    
                    if indexDateTime != nil {
                        if indexDate.upperBound<indexDateTime!.lowerBound {
                            
                            if let indexTimeSender = inputLine.range(of: "] ") { //3) "] " --> indexTimeSender; delimiter between timestamp and sender
                                if indexDateTime!.upperBound<indexTimeSender.lowerBound {
                                    
                                    if let indexSenderMessage = inputLine.range(of: ": ") { //4) ": " --> indexSenderMessage; delimiter between sender and message
                                        if indexTimeSender.upperBound<indexSenderMessage.lowerBound {
                                            //at least one message in valid format, process the text file
                                            
                                            if printToggle {
                                                print("func validateTextFileFormat() {\n\tinputLine: \(inputLine)")
                                                print("func validateTextFileFormat() {\n\tprocessTextFile(inputFile: textFileContents, dateTimeDelimiter: \(dateTimeDelimiter)")
                                            }
                                            
                                            validFileFormat = true
                                            processTextFile(inputFile: textFileContents, dateTimeDelimiter: dateTimeDelimiter)
                                        }
                                    }//if let indexSenderMessage = inputLine.range(of: ": ") {
                                }//if indexDateTime!.upperBound<indexTimeSender.lowerBound {
                            }//if let indexTimeSender = inputLine.range(of: "] ") {
                        }//if indexDate.upperBound<indexDateTime!.lowerBound {
                    }//if indexDatetime != nil {
                }//if let indexDate = inputLine.range(of: "["){
            }//if let inputLine = textFileContents.first {
        }//if let textFileContents = (try? String(contentsOf: fileToProcessURL!, encoding: String.Encoding.utf8))?.components(separatedBy: "\r\n") {
        
        //.txt file format of fileToProcessURL! not valid format
        if !validFileFormat {
            //b) .txt file is of the wrong format
            print("fileProcessor.swift/n/tfunc validateTextFileFormat() {/n/tif !validFileFormat {/n/tERROR: .txt invalid format!!")
            errorLoadingFile()
        }
    }

    
    func processTextFile(inputFile:[String], dateTimeDelimiter:String) {
        //file _chat.txt has been found and the first line is the correct format
        
        //CoreData
        setupchildContext()
        
        setupDateFormatters()
        
        //add chat to the temporary managed object context
        selectedChat = Chat(entity: NSEntityDescription.entity(forEntityName: "Chat", in: childContext)!, insertInto: childContext) as Chat
        
        selectedChat!.chatName = chatName!
        selectedChat!.dateLoad = NSDate()
        
        selectedChat!.chatID = Int16(UserDefaults.standard.integer(forKey: "totalChatsLoaded") + 1) // chatID saved in saveContexts(); UserDefaults.standard.integer(forKey: "totalChatsLoaded") incremented in func saveContexts() --> renameDirectory()
        
        
        /*
         WhatsApp line format:
         [DD/M/YY, HH:mm:ss] sender: message
         
         or alternate language format:
         [DD/M/YY HH:mm:ss] sender: message
         */

        let lineCount = inputFile.count     //number of messages = (lineCount-1) because of the 'end of file' char/line
        var distinctSenders = Set<String>()
        var i = 0                           //message count from 0 to (lineCount-2); 'end of file' char/line not counted
        
        var onePercent:Int = 1
        if lineCount > 100 {
            onePercent = Int(round(Double(lineCount/100)))
        }
        
        //process file in background
        self.delegate?.processingStarted()
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
                            
                            if dateTuple2.yyyyMMdd! == "f" {
                                //inputLine is not in the expected timestamp format, append to previous message
                                self.appendMessage(inputLine)
                                
                            } else {
                                //inputLine has passed file format validation, create message object; NOTE: at least one message will be processed as .txt file format validated in validateTextFileFormat()
                                
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
                                    
                                    //use this line to capture the attachment types; comment out to improve performance
                                    message.attachmentType = self.getMessageAttachmentType(messageText: message.messageContent!)
                                    
                                } else {
                                    //cannot distinguish between sender and message; assume that it is a group status update; note: this will be set as outgoing = false
                                    
                                    message.sender = Helper.app.groupMessageSender
                                    message.messageContent = inputLine[indexTimeSender.upperBound..<inputLine.endIndex].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                }
                                
                                message.senderColour = Int16(self.getGroupSenderIndex(message.sender!))
                                
                                i += 1 // only increment on messages and not on lines
                            }
                            
                        } else { //if indexDateTime.upperBound<indexTimeSender.lowerBound {
                            //inputLine is not in the expected timestamp format, append to previous message
                            self.appendMessage(inputLine)
                        }
                        
                    } else { //if let indexTimeSender = inputLine.range(of: "] ") {
                        //inputLine is not in the expected timestamp format, append to previous message
                        self.appendMessage(inputLine)
                    }
                    
                } else { //if let indexDateTime = inputLine.range(of: dateTimeDelimiter){
                    
                    //append to previous message if it is *not* end of file
                    //ie last line ('end of file' char) is when: i = (lineCount-1)
                    if (i+1 != lineCount) {
                        self.appendMessage(inputLine)
                        print("**line #\(i) appended")
                    }
                }
                            
            }//for inputLine in inputFile {
            
            //loading file complete, at least one message processed, ie. inputFile:[String].first , as .txt file format validated in validateTextFileFormat()
            NSLog("**END: process file")
            
            //update selectedChat variables
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
                self.delegate?.processingSaving()
                self.saveContexts()
            })
            
        })//DispatchQueue.global(qos: .background).async(execute: {
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
            //errorLoadingFile() is called *after* the entire file is processed
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
    
    
    func getMessageAttachmentType(messageText:String) -> Int16 {
        /*
         Exported with "Attach media":
         attachmentType File type      Extension   ‘Filename code’  Preview image
         0              Text            n/a        n/a              n/a - message text
         1              Contact        .vcf        n/a              "iconContactCard 144.png"
         2              Locations       n/a        n/a              n/a - message text of "Location" format
         3              Image          .jpg        PHOTO            .jpg or "iconImage 144.png"
         4              GIF            .mp4        GIF              .jpg (generated thumbnail) or "iconGIF 144.png"
         5              Video          .mp4/.mov   VIDEO            .jpg (generated thumbnail) or "iconVideo 144.png"
         6              Voice message  .opus       AUDIO            "iconAudio 144.png"
         7              Document       multiple    n/a              "iconDocument 144.png"
         8              Sticker        .webp       STICKER          .webp or "iconImage 144.png"
         
         Exported with "Without media":
         attachmentType File type      Message text            Preview image
         101            Contact        Contact card omitted    "iconContactCard 144.png"
         102            Locations      n/a                     n/a - message text of "Location" format
         103            Image          image omitted           "iconImage 144.png"
         104            GIF            GIF omitted             "iconGIF 144.png"
         105            Video          video omitted           "iconVideo 144.png"
         106            Voice message  audio omitted           "iconAudio 144.png"
         107            Document       document omitted        "iconDocument 144.png"
         108            Sticker        sticker omitted         "iconImage 144.png"
         */
        
        var attachmentType:Int16 = 0
        
        if messageText.hasSuffix(".vcf>") {
            //contact
            attachmentType = 1
            
        } else if messageText.hasSuffix(".jpg>") || messageText.hasSuffix(".png>"){
            //image
            attachmentType = 3
            
        } else if messageText.hasSuffix(".mp4>") {
            //GIF or video
            
            if messageText.range(of: "GIF") != nil {
                //GIF
                attachmentType = 4
            } else {
                //video
                attachmentType = 5
            }
            
        } else if messageText.hasSuffix(".mov") {
            //video
            attachmentType = 5
            
        } else if messageText.hasSuffix(".opus>") {
            //voice message
            attachmentType = 6
            
        } else if messageText.hasSuffix(".pdf>") || messageText.hasSuffix(".doc>") {
            //document
            attachmentType = 7
            
        } else if messageText.hasSuffix(".webp>") {
            //sticker
            attachmentType = 8
            
        } else if messageText.hasSuffix("rd omitted") {
            //contact
            attachmentType = 101
        } else if messageText.hasSuffix("ge omitted") {
            //image
            attachmentType = 103
            
        } else if messageText.hasSuffix("IF omitted") {
            //gif
            attachmentType = 104
            
        } else if messageText.hasSuffix("eo omitted") {
            //video
            attachmentType = 105
            
        } else if messageText.hasSuffix("io omitted") {
            //audio
            attachmentType = 106
            
        } else if messageText.hasSuffix("nt omitted") {
            //document
            attachmentType = 107
            
        } else if messageText.hasSuffix("er omitted") {
            //sticker
            attachmentType = 108
        }
        

        return attachmentType
    }
    
    
    func renameDirectory() {
        
        do {
            
            let fileManager = FileManager()
            
            deleteFiles(tempDirectory: false)
            
            //rename "tempDir" to self.selectedChat!.chatID
            try fileManager.moveItem(at: tempDirURL!, to: Helper.app.importedChatsURL().appendingPathComponent(Helper.app.formatChatIDToDirectoryName(chatID: Int(self.selectedChat!.chatID))))
            
            //increment the all-time chat count
            UserDefaults.standard.set(Int(self.selectedChat!.chatID), forKey: "totalChatsLoaded")
            UserDefaults.standard.synchronize()
            

        } catch let error as NSError {
            print("ERROR: try fileManager.moveItem(at: tempDirURL!, to: importedChatsURL!.appendingPathComponent(String(directoryName)))\nFailed to rename dir at \(String(describing: tempDirURL!.path));\nError code: \(error.localizedDescription)")
        }
    }

    
    func errorLoadingFile() {
        print("func errorLoadingFile()")
        
        deleteFiles(tempDirectory: true)
        
        DispatchQueue.main.async(execute: {
            self.delegate?.processingError()
        })
    }
    
    
    func deleteFiles(tempDirectory:Bool) {
        
        let fileManager = FileManager()
        
        if tempDirectory {
            //delete temp directory and contents, ie error loading chat file
            
            do {
                try fileManager.removeItem(at: tempDirURL!)
                
            } catch let error as NSError {
                print("ERROR: try fileManager.removeItem(at: tempDirURL!.path)\nFailed to remove file \( inputFileURL!.path));\nError code: \(error.localizedDescription)")
            }
        
        } else {
            //remove the _chat.txt file only, ie chat loaded successfully
            
            do {
                try fileManager.removeItem(atPath: fileToProcessURL!.path)
                
                if printToggle {
                    print("func deleteFiles(tempDirectory:Bool): removed file at: \(fileToProcessURL!.path)")
                }
                
            } catch let error as NSError {
                print("ERROR: func deleteFiles(tempDirectory:Bool); try fileManager.removeItemAtPath(fileToProcessURL!.path!): \(error.localizedDescription)")
            }
        }
        
        
        //remove the imported .zip file if it is *not* the simulator, ie from the device's 'Inbox'
        #if !targetEnvironment(simulator)
//            print("#if !targetEnvironment(simulator)")
        
            do {
                try fileManager.removeItem(at: inputFileURL!)
                
            } catch let error as NSError {
                print("ERROR: try fileManager.removeItem(at: inputFileURL!)\nFailed to remove file \(String(describing: inputFileURL!.path));\nError code: \(error.localizedDescription)")
            }
        
        #endif
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
                            self.delegate?.processingComplete()
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
    
}
