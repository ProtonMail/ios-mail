//
//  SignUpUserNameViewController.swift
//  
//
//  Created by Yanfeng Zhang on 12/17/15.
//
//

import UIKit

class SignUpUserNameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func createAccountAction(sender: UIButton) {
        
        self.performSegueWithIdentifier("sign_up_password_segue", sender: self)
    }

}
