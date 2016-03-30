//
//  CountryPickerViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/29/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation


protocol CountryPickerViewControllerDelegate {
    func dismissed();
}

class CountryPickerViewController : UIViewController {
    
    private var selected : NSIndexPath?
    private var isCreateView: Bool = false
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var applyButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.layer.cornerRadius = 4;
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    @IBAction func applyAction(sender: AnyObject) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancelAction(sender: AnyObject) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        
    }
}


// MARK: - UITableViewDataSource

extension CountryPickerViewController: UITableViewDataSource {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if (self.tableView.respondsToSelector("setSeparatorInset:")) {
            self.tableView.separatorInset = UIEdgeInsetsZero
        }
        
        if (self.tableView.respondsToSelector("setLayoutMargins:")) {
            self.tableView.layoutMargins = UIEdgeInsetsZero
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var labelCell = tableView.dequeueReusableCellWithIdentifier("labelApplyCell", forIndexPath: indexPath) as! LabelTableViewCell
//        if let label = fetchedLabels?.objectAtIndexPath(indexPath) as? Label {
//            labelCell.ConfigCell(viewModel.getLabelMessage(label), vc: self)
//        }
        return labelCell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
//        if (editingStyle == .Delete) {
//            // deleteMessageForIndexPath(indexPath)
//        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
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

// MARK: - UITableViewDelegate

extension CountryPickerViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 45.0
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let trashed: UITableViewRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: title) { (rowAction, indexPath) -> Void in
            //self.deleteMessageForIndexPath(indexPath)
        }
        trashed.backgroundColor = UIColor.ProtonMail.Red_D74B4B
        return [trashed]
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // verify whether the user is checking messages or not
    }
}





