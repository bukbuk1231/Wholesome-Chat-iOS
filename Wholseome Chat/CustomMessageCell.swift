//
//  CustomMessageCell.swift
//  Wholesome Chat
//
//  Created by Junda Lou on 11-22-2017
//  Copyright (c) Junda Lou. All rights reserved.
//

import UIKit

class CustomMessageCell: UITableViewCell {


    @IBOutlet var messageBackground: UIView!
    @IBOutlet var avatarImageView: UIImageView!
    @IBOutlet var messageBody: UILabel!
    @IBOutlet var senderUsername: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code goes here
        
    }
    

}
