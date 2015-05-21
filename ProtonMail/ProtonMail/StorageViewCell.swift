//
//  StorageViewCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class StorageViewCell: UITableViewCell {

    @IBOutlet weak var storageProgressBar: UIProgressView!
    
    @IBOutlet weak var storageUsageDescriptionLable: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    func setValue(usedSpace:Int, maxSpace:Int)
    {
        storageProgressBar.progress = 0.0
        
        let formattedUsedSpace = NSByteCountFormatter.stringFromByteCount(Int64(usedSpace), countStyle: NSByteCountFormatterCountStyle.Binary)
        let formattedMaxSpace = NSByteCountFormatter.stringFromByteCount(Int64(maxSpace), countStyle: NSByteCountFormatterCountStyle.Binary)
        
        let progress: Float = Float(usedSpace) / Float(maxSpace)
        
        storageProgressBar.setProgress(progress, animated: false)
        storageUsageDescriptionLable.text = "\(formattedUsedSpace)/\(formattedMaxSpace)"
    }
}
