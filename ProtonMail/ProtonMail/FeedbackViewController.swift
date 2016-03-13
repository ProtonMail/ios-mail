//
//  FeedbackViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/11/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation


protocol FeedbackViewControllerDelegate {
    func dismissed();
}

class FeedbackViewController : ProtonMailViewController, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        
     //   tableView.estimatedRowHeight =
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
//        if (self.tableView.respondsToSelector("setSeparatorInset:")) {
//            self.tableView.separatorInset = UIEdgeInsetsZero
//        }
//        
//        if (self.tableView.respondsToSelector("setLayoutMargins:")) {
//            self.tableView.layoutMargins = UIEdgeInsetsZero
//        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    @IBAction func ilikeitAction(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func itisokAction(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    @IBAction func dontlikeAction(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    @IBAction func cancelAction(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    
     /**
    tableview
    
    - parameter tableView: <#tableView description#>
    
    - returns: <#return value description#>
    */
    func numberOfSectionsInTableView(tableView: UITableView!) -> Int  {
        return 1
    }
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int  {
        return 1
    }
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell!  {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("feedback_table_top_cell", forIndexPath: indexPath) as! UITableViewCell
        
        return cell
    }
}