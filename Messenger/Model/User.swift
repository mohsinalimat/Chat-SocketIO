//
//  User.swift
//  Messenger
//
//  Created by Alexandr on 19.07.16.
//  Copyright © 2016 Alexandr. All rights reserved.
//

import Foundation
import RealmSwift

class User: Object {
    
    dynamic var username = ""
    let chats = List<Chat>()
    
    convenience init(username: String) {
        self.init()
        
        self.username = username
    }
    
// Specify properties to ignore (Realm won't persist these)
    
//  override static func ignoredProperties() -> [String] {
//    return []
//  }
}
