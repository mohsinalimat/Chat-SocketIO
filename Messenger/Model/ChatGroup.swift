//
//  ChatGroup.swift
//  Messenger
//
//  Created by Alexandr on 19.07.16.
//  Copyright © 2016 Alexandr. All rights reserved.
//

import Foundation
import RealmSwift

class ChatGroup: Object {
    
    dynamic var name = ""
    let messages = List<Message>()
    let owners = LinkingObjects(fromType: User.self, property: "chatGroups")
    
    convenience init(name: String) {
        self.init()
        
        self.name = name
    }
    
// Specify properties to ignore (Realm won't persist these)
    
//  override static func ignoredProperties() -> [String] {
//    return ["id"]
//  }
}
