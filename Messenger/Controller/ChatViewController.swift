//
//  ViewController.swift
//  Messenger
//
//  Created by Alexandr on 14.07.16.
//  Copyright © 2016 Alexandr. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class ChatViewController: JSQMessagesViewController {
        
    var messages = [JSQMessage]()
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    let dataManager = DataManager()
    
    var user: User!
    var chatGroup: ChatGroup!
    var typingUsers = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureComponents()
        registerNotifications()
        setupBubbles()
    }
    
    var signInTimer: NSTimer?
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let _ = NSUserDefaults.standardUserDefaults().stringForKey("username") {
            
            self.user = dataManager.fetchUser()
            
            self.senderId = self.user.username
            self.senderDisplayName = self.user.username
            
            signInTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(ChatViewController.signInUser), userInfo: nil, repeats: true)
        }
        else {
            askForNickname()
        }
        
        SocketIOManager.sharedInstance.getChatMessage { (message) in
            dispatch_async(dispatch_get_main_queue(), {
                let username = message["username"] as! String
                let text = message["message"] as! String
                self.addMessage(username, displayName: username, text: text)
                self.finishReceivingMessageAnimated(true)
                self.scrollToBottomAnimated(true)
            })
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        dataManager.removeMessagesFromChatGroup(self.chatGroup)
        dataManager.saveMessagesInChatGroup(chatGroup, messages: messages)
    }
    
    func configureComponents() {
        self.senderId = "none"
        self.senderDisplayName = "none"
        self.title = "Chat"
        
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
    }
    
    func registerNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.userJoinedChat(_:)), name: "userJoinedChat", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.userLeftChat(_:)), name: "userLeftChat", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.userIsTyping(_:)), name: "userIsTyping", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.userStopTyping(_:)), name: "userStopTyping", object: nil)
    }
    
    func signInUser() {
        SocketIOManager.sharedInstance.connectToServerWithUser(self.user, completion: { (userList) in
            if self.signInTimer != nil {
                self.signInTimer!.invalidate()
            }
            
            self.dataManager.deleteOldMessages({ 
                self.chatGroup = self.user?.chatGroups.filter(NSPredicate(format: "name == %@", "First chat")).first
                for message in self.chatGroup.messages {
                    self.addMessage(message.senderId, displayName: message.displayId, text: message.text)
                }
                self.finishReceivingMessageAnimated(true)
                
                print(self.chatGroup.name)
                
                let numUsers = userList[0]["numUsers"]!
                print("In chat \(numUsers) persons")
                self.title = "In chat \(numUsers) persons"
            })
        })
    }
    
    func userJoinedChat(notification: NSNotification) {
        let connectedUserInfo = notification.object as! [String: AnyObject]
        
        if connectedUserInfo["username"] == nil {
            print("no username of typing user. server error")
            return
        }
        
        let connectedUsername = connectedUserInfo["username"] as! String
        let connectedNumUsers = connectedUserInfo["numUsers"] as! NSNumber
        print("There is \(connectedNumUsers) participants")
        self.title = "In chat \(connectedNumUsers) persons"
        print("\(connectedUsername) joined the chat")
    }
    
    func userLeftChat(notification: NSNotification) {
        let disconnectedUserInfo = notification.object as! [String: AnyObject]
        
        if disconnectedUserInfo["username"] == nil {
            print("no username of typing user. server error")
            return
        }
        
        let disconnectedUsername = disconnectedUserInfo["username"] as! String
        let disconnectedNumUsers = disconnectedUserInfo["numUsers"] as! NSNumber
        print("There is \(disconnectedNumUsers) participants")
        self.title = "In chat \(disconnectedNumUsers) persons"
        print("\(disconnectedUsername) left the chat")
    }
    
    func userIsTyping(notification: NSNotification) {
        let userInfo = notification.object as! [String: AnyObject]
        
        if userInfo["username"] == nil {
            print("no username of typing user. server error")
            return
        }
        
        let username = userInfo["username"] as! String
        
        if typingUsers.contains(username) {
            return
        }
        
        typingUsers.append(username)
        
        self.showTypingIndicator = true
        
        for indexPath in self.collectionView.indexPathsForVisibleItems() {
            if indexPath.item == messages.count-1 {
                self.scrollToBottomAnimated(true)
            }
        }
    }
    
    func userStopTyping(notification: NSNotification) {
        let userInfo = notification.object as! [String: AnyObject]
        
        if userInfo["username"] == nil {
            print("no username of typing user. server error")
            return
        }
        
        let username = userInfo["username"] as! String
        
        if typingUsers.count > 0 {
            typingUsers.removeAtIndex(typingUsers.indexOf(username)!)
        }
        
        self.showTypingIndicator = typingUsers.count > 0
    }

    func askForNickname() {
        let alert = UIAlertController(title: "Chat", message: "Please, entre your nickname", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler(nil)
        let okAction = UIAlertAction(title: "Ok", style: .Default) { (action) in
            let textfield = alert.textFields![0]
            if textfield.text?.characters.count == 0 {
                self.askForNickname()
            }
            else {
                self.user = User(username: textfield.text!)
                let chatGroup = ChatGroup(name: "First chat")
                
                self.user.chatGroups.append(chatGroup)
                self.chatGroup = chatGroup
                self.dataManager.saveUser(self.user)
                
                self.senderId = self.user.username
                self.senderDisplayName = self.user.username
                
                NSUserDefaults.standardUserDefaults().setObject(self.user.username, forKey: "username")
                
                self.signInUser()
            }
            
        }
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    private func setupBubbles() {
        let factory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = factory.outgoingMessagesBubbleImageWithColor(
            UIColor.jsq_messageBubbleBlueColor())
        incomingBubbleImageView = factory.incomingMessagesBubbleImageWithColor(
            UIColor.jsq_messageBubbleLightGrayColor())
    }
    
    func addMessage(id: String, displayName: String, text: String) {
        let message = JSQMessage(senderId: id, displayName: displayName, text: text)
        messages.append(message)
    }
    
    //MARK: - Delegate methods
    
    override func collectionView(collectionView: JSQMessagesCollectionView!,
                                 messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!,
                                 messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if message.senderId == senderId {
            return outgoingBubbleImageView
        } else {
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(collectionView: UICollectionView,
                                 cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath)
            as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView!.textColor = UIColor.whiteColor()
        } else {
            cell.textView!.textColor = UIColor.blackColor()
        }
        
        return cell
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView?, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        switch message.senderId {
        case self.senderDisplayName:
            return nil
        default:
            guard let senderDisplayName = message.senderDisplayName else {
                assertionFailure()
                return nil
            }
            return NSAttributedString(string: senderDisplayName)
            
        }
    }
    
//    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
//        return NSAttributedString(string: "alksdjalksdjaljksd")
//    }
//    
//    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
//        return 22
//    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
    
        if indexPath.item == 0 {
            if messages[0].senderDisplayName == self.senderDisplayName {
                return 0
            }
            else {
                return 22
            }
        }
        else {
            if messages[indexPath.item].senderId == messages[indexPath.item-1].senderId || messages[indexPath.item].senderId == self.senderId {
                return 0
            }
            else {
                return 22
            }
        }
        
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!,
                                 avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        SocketIOManager.sharedInstance.sendMessage(text)
        addMessage(senderId, displayName: senderDisplayName, text: text)
        finishSendingMessageAnimated(true)
    }
    
    var typingTimer: NSTimer?
    
    override func textViewDidChange(textView: UITextView) {
        super.textViewDidChange(textView)
        
        SocketIOManager.sharedInstance.userIsTyping(user.username)
        typingTimer?.invalidate()
        typingTimer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: #selector(ChatViewController.userStopped), userInfo: textView, repeats: true)
    }
    
    func userStopped() {
        typingTimer?.invalidate()
        SocketIOManager.sharedInstance.userStopTyping(user.username)
    }

}

