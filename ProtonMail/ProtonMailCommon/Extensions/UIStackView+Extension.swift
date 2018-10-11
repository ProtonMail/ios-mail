//
//  UIStackView+Extension.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/10/11.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

extension UIStackView
{
    func clearAllViews() {
        while self.arrangedSubviews.count > 0 {
            let view = self.arrangedSubviews[0]
            self.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
}
