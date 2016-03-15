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
    
    private let sectionSource : [FeedbackSection] = [.header, .reviews, .guid]
    private let dataSource : [FeedbackSection : [FeedbackItem]] = [.header : [.header], .reviews : [.rate, .tweet, .facebook], .guid : [.guide, .contact]]
    
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension;
        tableView.estimatedRowHeight = 36.0
    }
    
    override func viewWillAppear(animated: Bool) {
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if (self.tableView.respondsToSelector("setSeparatorInset:")) {
            self.tableView.separatorInset = UIEdgeInsetsZero
        }
        
        if (self.tableView.respondsToSelector("setLayoutMargins:")) {
            self.tableView.layoutMargins = UIEdgeInsetsZero
        }
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
    
    - parameter tableView:
    
    - returns:
    */
    func numberOfSectionsInTableView(tableView: UITableView!) -> Int  {
        return sectionSource.count
    }
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int  {
        let items = dataSource[sectionSource[section]]
        
        return items?.count ?? 0
    }
    
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let key = sectionSource[section]
        if key.hasTitle {
            let cell: FeedbackHeadCell = tableView.dequeueReusableCellWithIdentifier("feedback_table_section_header_cell") as! FeedbackHeadCell
            cell.configCell(key.title)
            //cell.backgroundColor = UIColor.whiteColor()
            return cell;
        } else {
            return nil
        }
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let key = sectionSource[section]
        if key.hasTitle {
            return 46
        } else {
            return 0.01
        }
    }
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell!  {
        let key = sectionSource[indexPath.section]
        let items : [FeedbackItem]? = dataSource[key]
        if key == .header {
            let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("feedback_table_top_cell", forIndexPath: indexPath) as! UITableViewCell
            cell.selectionStyle = .None
            return cell
        } else {
            let cell: FeedbackTableViewCell = tableView.dequeueReusableCellWithIdentifier("feedback_table_detail_cell", forIndexPath: indexPath) as! FeedbackTableViewCell
            if let item = items?[indexPath.row] {
                cell.configCell(item)
            }
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
         tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if (cell.respondsToSelector("setSeparatorInset:")) {
            cell.separatorInset = UIEdgeInsetsZero
        }
        
        if (cell.respondsToSelector("setLayoutMargins:")) {
            cell.layoutMargins = UIEdgeInsetsZero
        }
    }
}