//
//  SignInViewController.swift
//  CMU-SV-Indoor-Swift
//
//  Created by Jeremy Chipman on 11/16/15.
//  Copyright © 2015 CMU-SV. All rights reserved.
//

import UIKit

class SignInViewController: UIViewController {
    
    @IBOutlet weak var email: UITextField!
    
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var signIn: UIButton!
    
    @IBOutlet weak var activityIdicator: UIActivityIndicatorView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    let emptyFieldAlertController = UIAlertController (title: "Email and password required", message: "Please enter both your email address and password.", preferredStyle: .Alert)
    let badMatchAlertController = UIAlertController (title: "Sign in failed", message: "Your email and password do not match!", preferredStyle: .Alert)
    let cancelAction = UIAlertAction (title: "OK", style: .Cancel){
        (action) in
        // handle cancel response here. Doing nothing will dismiss the view.
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add the cancel action to the alertController
        self.emptyFieldAlertController.addAction(self.cancelAction)
        self.badMatchAlertController.addAction(self.cancelAction)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        // Do any additional setup after loading the view.
    }
    
    func keyboardWillShow(notification: NSNotification!) {
        
        scrollView.contentOffset.y = 125
        
    }
    func keyboardWillHide(notification: NSNotification!) {
        
        scrollView.contentOffset.y = -125
        
        // Get the keyboard height and width from the notification
        
        // Size varies depending on OS, language, orientation
        
    }
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
        
    }
    
    @IBAction func onPressButton(sender: AnyObject) {
        if email.text!.isEmpty || password.text!.isEmpty {
            
            presentViewController(emptyFieldAlertController, animated: true) {
                
                // optional code for what happens after the alert controller has finished presenting
                
                // create a cancel action
            }
            // otherwise
            
        } else if email.text != "jc" || password.text != "pass"{
            
            activityIdicator.startAnimating()
            // Delay for 2 seconds, then run the code between the braces.
            delay (1) {
                self.activityIdicator.stopAnimating()
                self.presentViewController(self.badMatchAlertController, animated: true){
                    
                    
                    
                    // optional code for what happens after the alert controller has finished presenting
                    
                    // create a cancel action
                    
                    
                    // add the cancel action to the alertController
                    
                }
            }
            
        }else if self.email.text == "jc" && self.password.text == "pass" {
            
            activityIdicator.startAnimating()
            // Delay for 2 seconds, then run the code between the braces
        }
        delay(2) {
            self.performSegueWithIdentifier("loginSegue", sender: nil)
            
        }
    }
    
}