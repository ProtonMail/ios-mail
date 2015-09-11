//
//  RecipientView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/10/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class RecipientView: PMView {
    override func getNibName() -> String {
        return "RecipientView"
    }
    var promptString : String?
    var labelValue : String?
    
    var labelSize : CGSize?;
    
    //@IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    private let kContactCellIdentifier: String = "ContactCell"
    
    
    override func setup() {
        self.tableView.registerNib(UINib(nibName: "ContactsTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: kContactCellIdentifier)
        self.tableView.alwaysBounceVertical = false
        self.tableView.separatorStyle = .None
        self.tableView.allowsSelection = false

    }
    
    var prompt : String {
        get {
            return promptString ?? ""
        }
        set (t) {
            promptString = t
        }
    }
    
    var label : String? {
        get {
            return labelValue;
        }
        set (t) {
            labelValue = t;
        }
    }
    
    func getContentSize() -> CGSize{
        tableView.reloadData()
        tableView.layoutIfNeeded();
        let s = tableView!.contentSize
        return s;
    }
    
    func showDetails() {
        
    }
    
    func hideDetails() {
        
    }

    override func sizeToFit() {
        super.sizeToFit()
        
        //no details
        // update label
        
        
//        // update tableview
//        tableView.hidden = true;
//        fromLabel.sizeToFit();
//        var s = fromLabel.sizeThatFits(CGSizeZero)
//        if s.width == 0 {
//            labelSize = CGSizeZero;
//        } else {
//            
//            labelSize = CGSize(width: s.width, height: s.height + fromLabel.frame.origin.y)
//        }
        //details
    }
    
    override func sizeThatFits(size: CGSize) -> CGSize {
        return super.sizeThatFits(size)
//        let s = tableView!.contentSize
//        if s.height <= 0 {
//            return self.labelSize ?? size;
//        }
//        return s
    }
    
    
    //    attachmentView!.reloadData()
    //    attachmentView!.layoutIfNeeded();
    //
    //    let h = self.attachmentCount > 0 ? attachmentView!.contentSize.height : 0;
    //    self.separatorBetweenHeaderAndAttView.hidden = self.attachmentCount == 0
    //
    //    separatorBetweenHeaderAndBodyView.mas_updateConstraints { (make) -> Void in
    //    make.removeExisting = true
    //    make.left.equalTo()(self)
    //    make.right.equalTo()(self)
    //    make.top.equalTo()(self.emailHeaderView.mas_bottom).with().offset()(self.kSeparatorBetweenHeaderAndBodyMarginTop)
    //    make.height.equalTo()(1)
    //    }
    //    self.attachmentView!.mas_updateConstraints { (make) -> Void in
    //    make.removeExisting = true
    //    make.left.equalTo()(self)
    //    make.right.equalTo()(self)
    //    make.top.equalTo()(self.separatorBetweenHeaderAndBodyView.mas_bottom)
    //    make.height.equalTo()(h)
    //    }
    //
    //
}
extension RecipientView: UITableViewDataSource {
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kContactCellIdentifier, forIndexPath: indexPath) as! ContactsTableViewCell
        //cell.backgroundColor = UIColor.greenColor()
        return cell;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2;// attachments.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44;
    }
}

extension RecipientView: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
    }
}