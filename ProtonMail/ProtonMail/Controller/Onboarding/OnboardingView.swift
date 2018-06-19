//
//  OnboardingView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/21/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import UIKit
class OnboardingView : PMView {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descLabel: UILabel!
    
    
    override func getNibName() -> String {
        return "OnboardingView"
    }

    func config(with board: Onboarding) {
        imageView.image = UIImage(named: board.image)
        titleLabel.text = board.title
        descLabel.text = board.description
    }
}
