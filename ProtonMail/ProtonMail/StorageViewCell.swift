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
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    func setValue(_ usedSpace:Int64, maxSpace:Int64)
    {
        storageProgressBar.progress = 0.0
        let formattedUsedSpace = ByteCountFormatter.string(fromByteCount: Int64(usedSpace), countStyle: ByteCountFormatter.CountStyle.binary)
        let formattedMaxSpace = ByteCountFormatter.string(fromByteCount: Int64(maxSpace), countStyle: ByteCountFormatter.CountStyle.binary)
        
        let progress: Float = Float(usedSpace) / Float(maxSpace)
        
        storageProgressBar.setProgress(progress, animated: false)
        storageUsageDescriptionLable.text = "\(formattedUsedSpace)/\(formattedMaxSpace)"
    }
}
