//
//  SocketIOManager.swift
//  Messenger
//
//  Created by Alexandr on 14.07.16.
//  Copyright © 2016 Alexandr. All rights reserved.
//

import UIKit
import SocketIOClientSwift

class SocketIOManager: NSObject {
    static let sharedInstance = SocketIOManager()
    
    var socket = SocketIOClient(socketURL: NSURL(string: "http://192.168.1.2:3000")!)
    
    override init() {
        super.init()
    }
    
    func establishConnection() {
        socket.connect()
    }
    
    func closeConnection() {
        socket.disconnect()
    }
    
    func userIsTyping(username: String) {
        socket.emit("typing", username)
    }
    
    func userStopTyping(username: String) {
        socket.emit("stop typing", username)
    }
    
    func connectToServerWithUser(user: User, completion: (userList: [[String: AnyObject]]!) -> Void) {
        socket.emit("add user", user.username)
    
        socket.on("login") { (dataArray, ack) in
            completion(userList: dataArray as! [[String: AnyObject]])
        }
        
        listenForOtherChatMessages()
    }
    
    func getChatMessage(completion: (message: [String: AnyObject]) -> Void) {
        socket.on("new message") { (dataArray, ack) in
            let messageDict = dataArray.first as! [String: AnyObject]
            
            completion(message: messageDict)
        }
    }
    
    func sendMessage(message: String) {
        socket.emit("new message", message)
    }
    
    private func listenForOtherChatMessages() {
        socket.on("user joined") { (dataArray, ack) in
            NSNotificationCenter.defaultCenter().postNotificationName("userJoinedChat", object: dataArray[0] as! [String: AnyObject])
        }
        
        socket.on("user left") { (dataArray, ack) in
            NSNotificationCenter.defaultCenter().postNotificationName("userLeftChat", object: dataArray[0] as! [String: AnyObject])
        }
        
        socket.on("typing") { (dataArray, ack) in
            NSNotificationCenter.defaultCenter().postNotificationName("userIsTyping", object: dataArray[0] as! [String: AnyObject])
        }
        
        socket.on("stop typing") { (dataArray, ack) in
            NSNotificationCenter.defaultCenter().postNotificationName("userStopTyping", object: dataArray[0] as! [String: AnyObject])
        }
    }
    
}
