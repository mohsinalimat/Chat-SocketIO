//
//  DataManager.swift
//  Messenger
//
//  Created by Alexandr on 19.07.16.
//  Copyright © 2016 Alexandr. All rights reserved.
//

import UIKit
import RealmSwift
import JSQMessagesViewController

class DataManager: NSObject {
    
    let realm = try! Realm()
 
    func fetchUser() -> User? {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let username = defaults.valueForKey("username") {
            let user = realm.objects(User).filter(NSPredicate(format: "username == %@", username as! String)).first! as User
            return user
        }
        return nil
    }
    
    func saveUser(user: User) {
        try! realm.write({ 
            realm.add(user)
        })
    }
    
    func removeMessagesFromChatGroup(chatGroup: ChatGroup) {
        try! realm.write({ 
            chatGroup.messages.removeAll()
        })
    }
    
    func saveMessagesInChatGroup(chatGroup: ChatGroup, messages: [JSQMessage]) {
        let user = fetchUser()
        try! realm.write({
            for message in messages {
                let msg = Message(senderId: message.senderId, displayId: message.senderDisplayName, date: message.date, text: message.text)
                user?.chatGroups.filter(NSPredicate(format: "name == %@", chatGroup.name)).first?.messages.append(msg)
            }
        })
    }
    
    func deleteOldMessages(completion: () -> Void) {
        let currentDate = NSDate()
        let calendar: NSCalendar = NSCalendar.currentCalendar()
        let flag = NSCalendarUnit.Day
        
        try! realm.write({ 
            
            let user = fetchUser()
            for group: ChatGroup in (user?.chatGroups)! {
                for message: Message in group.messages {
                    let messageDate = message.date
                    
                    let components = calendar.components(flag, fromDate: currentDate, toDate: messageDate, options: [])
                    if components.day < -1 {
                        realm.delete(message)
                    }
                }
            }
            completion()
        })
    }

}
