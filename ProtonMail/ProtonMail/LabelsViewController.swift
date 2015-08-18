//
//  LabelsViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


class LablesViewController : UIViewController {

    @IBOutlet weak var backgroundImageView: UIImageView!

    @IBOutlet weak var contentView: UIView!
    
    
    @IBOutlet weak var titleLabel: UILabel!
    
    
    
    @IBOutlet weak var inputContentView: UIView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var applyButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    override func viewDidLoad() {
        
        
        contentView.layer.cornerRadius = 5;
    }
    
    
    @IBAction func applyAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    @IBAction func cancelAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}


