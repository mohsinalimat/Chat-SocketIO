//
//  ViewController.swift
//  Messenger
//
//  Created by Alexandr on 14.07.16.
//  Copyright © 2016 Alexandr. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class ViewController: JSQMessagesViewController {
        
    var messages = [JSQMessage]()
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    
    var nickname: String!
    var typingUsers = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureComponents()
        registerNotifications()
        setupBubbles()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        askForNickname()
        
        SocketIOManager.sharedInstance.getChatMessage { (message) in
            dispatch_async(dispatch_get_main_queue(), {
                let username = message["username"] as! String
                let text = message["message"] as! String
                self.addMessage(username, displayName: username, text: text)
                self.finishReceivingMessageAnimated(true)
            })
        }
    }
    
    func configureComponents() {
        self.senderId = "none"
        self.senderDisplayName = "none"
        self.title = "Chat"
        
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
    }
    
    func registerNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.userJoinedChat(_:)), name: "userJoinedChat", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.userLeftChat(_:)), name: "userLeftChat", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.userIsTyping(_:)), name: "userIsTyping", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.userStopTyping(_:)), name: "userStopTyping", object: nil)
    }
    
    func userJoinedChat(notification: NSNotification) {
        let connectedUserInfo = notification.object as! [String: AnyObject]
        let connectedUsername = connectedUserInfo["username"] as! String
        let connectedNumUsers = connectedUserInfo["numUsers"] as! NSNumber
        print("There is \(connectedNumUsers) participants")
        print("\(connectedUsername) joined the chat")
    }
    
    func userLeftChat(notification: NSNotification) {
        let disconnectedUserInfo = notification.object as! [String: AnyObject]
        let disconnectedUsername = disconnectedUserInfo["username"] as! String
        let disconnectedNumUsers = disconnectedUserInfo["numUsers"] as! NSNumber
        print("There is \(disconnectedNumUsers) participants")
        print("\(disconnectedUsername) left the chat")
    }
    
    func userIsTyping(notification: NSNotification) {
        let userInfo = notification.object as! [String: AnyObject]
        let username = userInfo["username"] as! String
        
        typingUsers.append(username)
        
        self.showTypingIndicator = typingUsers.count > 0
    }
    
    func userStopTyping(notification: NSNotification) {
        let userInfo = notification.object as! [String: AnyObject]
        let username = userInfo["username"] as! String
        
        if typingUsers.count > 0 {
            typingUsers.removeAtIndex(typingUsers.indexOf(username)!)
        }
        
        self.showTypingIndicator = typingUsers.count > 0
    }

    func askForNickname() {
        let alert = UIAlertController(title: "SocketChat", message: "Please, entre your nickname", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler(nil)
        let okAction = UIAlertAction(title: "Ok", style: .Default) { (action) in
            let textfield = alert.textFields![0]
            if textfield.text?.characters.count == 0 {
                self.askForNickname()
            }
            else {
                self.nickname = textfield.text!
                self.senderId = self.nickname
                self.senderDisplayName = self.nickname
                
                SocketIOManager.sharedInstance.connectToServerWithNickname(self.nickname, completion: { (userList) in
                    print("In chat \(userList[0]["numUsers"]!) persons")
                })
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
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        
        if indexPath.item == 0 {
            if messages[0].senderDisplayName == self.senderDisplayName {
                return 0
            }
            else {
                return 25
            }
        }
        else {
            if messages[indexPath.item].senderId == messages[indexPath.item-1].senderId || messages[indexPath.item].senderId == self.senderId {
                return 0
            }
            else {
                return 25
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

}

