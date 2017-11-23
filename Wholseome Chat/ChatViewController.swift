//
//  ViewController.swift
//  Wholesome Chat
//
//  Created by Junda Lou on 11-22-2017
//  Copyright (c) Junda Lou. All rights reserved.
//

import UIKit
import Firebase
import ChameleonFramework
import UICircularProgressRing
import Alamofire
import SwiftyJSON
import SVProgressHUD

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    // Declare instance variables here
    var toxicity : Double = 0
    var messageArray : [Message] = [Message]()
    let url : String = "https://gateway.watsonplatform.net/tone-analyzer/api/v3/tone?version=2017-11-22&sentences=true&tones=language"
    let username : String = ""  // get your own API key
    let password : String = ""
    let headers : [String : String] = ["Content-Type" : "text/plain", "Accept" : "application/json"]
    // keep API secret
    
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var messageTextfield: UITextField!
    @IBOutlet var messageTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        messageTableView.backgroundView = UIImageView(image: UIImage(named: "background_2"))
        
        //TODO: Set yourself as the delegate and datasource here:
        messageTableView.delegate = self
        messageTableView.dataSource = self
        
        
        //TODO: Set yourself as the delegate of the text field here:
        messageTextfield.delegate = self
        
        
        //TODO: Set the tapGesture here:
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tableViewTapped))
        messageTableView.addGestureRecognizer(tapGesture)
        

        //TODO: Register your MessageCell.xib file here:
        messageTableView.register(UINib(nibName: "MessageCell", bundle: nil), forCellReuseIdentifier: "customMessageCell")
        
        configureTableView()
        retrieveMessages()
        
        messageTableView.separatorStyle = .none
    }

    ///////////////////////////////////////////
    
    //MARK: - TableView DataSource Methods
    
    //TODO: Declare cellForRowAtIndexPath here:
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customMessageCell", for: indexPath) as! CustomMessageCell
        cell.tag = 0
        cell.messageBody.text = messageArray[indexPath.row].messageBody
        cell.senderUsername.text = messageArray[indexPath.row].sender
        cell.avatarImageView.image = UIImage(named: "akua")
        cell.senderUsername.textColor = UIColor.flatBlack()
        cell.backgroundColor = UIColor.clear
        if cell.senderUsername.text == Auth.auth().currentUser?.email as! String {
            cell.avatarImageView.backgroundColor = UIColor.flatMint()
            cell.messageBackground.backgroundColor = UIColor.flatSkyBlue()
        }
        if cell.senderUsername.text == "Watson" {
            cell.avatarImageView.image = UIImage(named : "watson")
            cell.avatarImageView.backgroundColor = UIColor.flatWhite()
            cell.messageBackground.backgroundColor = UIColor.flatRed()
        }
        return cell
    }
    
    
    //TODO: Declare numberOfRowsInSection here:
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return messageArray.count
    }
    
    
    //TODO: Declare tableViewTapped here:
    @objc func tableViewTapped() {
        messageTextfield.endEditing(true)
    }
    
    //TODO: Declare configureTableView here:
    func configureTableView() {
        messageTableView.rowHeight = UITableViewAutomaticDimension
        messageTableView.estimatedRowHeight = 120
    }
    
    
    ///////////////////////////////////////////
    
    //MARK:- TextField Delegate Methods
    
    //TODO: Declare textFieldDidBeginEditing here:
    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.5) {
            self.heightConstraint.constant = 308
            self.view.layoutIfNeeded()}
    }
    
    //TODO: Declare textFieldDidEndEditing here:
    func textFieldDidEndEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.5) {
            self.heightConstraint.constant = 50
            self.view.layoutIfNeeded()
        }
    }

    ///////////////////////////////////////////
    
    //MARK: - Send & Recieve from Firebase
    
    @IBAction func sendPressed(_ sender: AnyObject) {
        messageTextfield.endEditing(true)
        
        //TODO: Send the message to Firebase and save it in our database
        messageTextfield.isEnabled = false
        sendButton.isEnabled = false
        let messageDB = Database.database().reference().child("Messages")
        var messageDict = ["Sender": Auth.auth().currentUser?.email, "MessageBody": messageTextfield.text]
        messageDB.childByAutoId().setValue(messageDict) {
            (error, reference) in
            if error != nil {
                print(error!)
            } else {
                print("success")
                self.messageTextfield.isEnabled = true
                self.sendButton.isEnabled = true
                self.messageTextfield.text = ""
            }
        }
        
        let apiParam : [String : String] = ["tone_input" : messageTextfield.text!]

        Alamofire.request(url, method: .post, parameters: apiParam, headers : headers).authenticate(user: username, password: password).responseJSON {
            response in
               print(response)
            let responseJSON : JSON = JSON(response.result.value!)
            if let tmp = responseJSON["document_tone"]["tones"][0]["score"].double {
                if responseJSON["document_tone"]["tones"][0]["tone_id"] == "anger" {
                    self.toxicity = responseJSON["document_tone"]["tones"][0]["score"].double!
                    if self.toxicity > 0.5 {
                        SVProgressHUD.showError(withStatus: "Too Toxic! GET OUT!")
                        SVProgressHUD.dismiss(withDelay: 2.5)
                    }
                } else {
                    self.toxicity = 0
                }
            } else {
              self.toxicity = -1
            }
            // Based on IBM Watson, if the tone is not 'angry', then no toxicity at all
            
            if self.toxicity == -1 {
                messageDict = ["Sender" : "Watson", "MessageBody" : "Unable to anaylze the language"]
            } else {
                messageDict = ["Sender" : "Watson", "MessageBody" : "Toxicity: \(self.toxicity * 100)%"]
            }
            messageDB.childByAutoId().setValue(messageDict) {
                (error, reference) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: "Failed to send message")
                    SVProgressHUD.dismiss(withDelay: 0.7)
                }
            }
        }
    }
    
    //TODO: Create the retrieveMessages method here:
    func retrieveMessages() {
        let messageDB = Database.database().reference().child("Messages")
        messageDB.observe(.childAdded) {
            (snapshot) in
            let value = snapshot.value as! Dictionary<String, String>
            let text = value["MessageBody"]!
            let sender = value["Sender"]!
            let msg = Message()
            msg.messageBody = text
            msg.sender = sender
            self.messageArray.append(msg)
            self.configureTableView()
            self.messageTableView.reloadData()
        }
    }
    
    @IBAction func logOutPressed(_ sender: AnyObject) {
        //TODO: Log out the user and send them back to WelcomeViewController
        do {
            try Auth.auth().signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch {
            SVProgressHUD.showError(withStatus: "Logout Failed")
            SVProgressHUD.dismiss(withDelay: 1)
        }
    }
    


}
