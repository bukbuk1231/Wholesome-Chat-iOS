//
//  RegisterViewController.swift
//  Wholesome Chat
//
//  This is the View Controller which registers new users with Firebase
//

import UIKit
import Firebase
import SVProgressHUD

class RegisterViewController: UIViewController {

    @IBOutlet var emailTextfield: UITextField!
    @IBOutlet var passwordTextfield: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    @IBAction func registerPressed(_ sender: AnyObject) {
        SVProgressHUD.show()
        
        //TODO: Set up a new user on Firbase database
        Auth.auth().createUser(withEmail: emailTextfield.text!, password: passwordTextfield.text!) {
            (user, error) in
            if error != nil {
                print(error!.localizedDescription)
                if (error?.localizedDescription.contains("must be provided"))! {
                    SVProgressHUD.showError(withStatus: "An email address must ")
                    SVProgressHUD.dismiss(withDelay: 1)
                } else if (self.passwordTextfield.text?.count)! < 6 {
                    SVProgressHUD.showError(withStatus: "Password must be greater than length of 6")
                    SVProgressHUD.dismiss(withDelay: 1)
                } else if (error?.localizedDescription.contains("badly formatted"))! {
                    SVProgressHUD.showError(withStatus: "Email address invalid")
                    SVProgressHUD.dismiss(withDelay: 1)
                } else if (error?.localizedDescription.contains("already in use"))! {
                    SVProgressHUD.showError(withStatus: "Email address already registered")
                    SVProgressHUD.dismiss(withDelay: 1)
                }
            }
            else {
                SVProgressHUD.dismiss()
                self.performSegue(withIdentifier: "goToChat", sender: self)
                
            }
        }
    } 
    
    
}
