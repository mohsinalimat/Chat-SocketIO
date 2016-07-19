//
//  Message.swift
//  Messenger
//
//  Created by Alexandr on 19.07.16.
//  Copyright © 2016 Alexandr. All rights reserved.
//

import Foundation
import RealmSwift

class Message: Object {
    
    dynamic var senderId = ""
    dynamic var displayId = ""
    dynamic var text = ""
    dynamic var data: NSData? = nil
    dynamic var date = NSDate()
    
    let owners = LinkingObjects(fromType: ChatGroup.self, property: "messages")
    
    convenience init(senderId: String, displayId: String, date: NSDate, text: String) {
        self.init()
        
        self.senderId = senderId
        self.displayId = displayId
        self.text = text
        self.date = date
    }
    
// Specify properties to ignore (Realm won't persist these)
    
//  override static func ignoredProperties() -> [String] {
//    return []
//  }
}
