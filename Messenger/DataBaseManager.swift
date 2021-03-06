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

class DataBaseManager: NSObject {
    
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
    
    func removeMessagesFromChat(chat: Chat) {
        try! realm.write({ 
            chat.messages.removeAll()
        })
    }
    
    func saveMessagesInChat(chat: Chat, messages: [JSQMessage]) {
        let user = fetchUser()
        try! realm.write({
            for message in messages {
                let msg = Message(senderId: message.senderId, displayId: message.senderDisplayName, date: message.date, text: message.text)
                user?.chats.filter(NSPredicate(format: "name == %@", chat.name)).first?.messages.append(msg)
            }
        })
    }
    
    func deleteOldMessages(completion: () -> Void) {
        let currentDate = NSDate()
        let calendar: NSCalendar = NSCalendar.currentCalendar()
        let flag = NSCalendarUnit.Day
        
        try! realm.write({ 
            
            let user = fetchUser()
            for chat: Chat in (user?.chats)! {
                for message: Message in chat.messages {
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
