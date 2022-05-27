//
//  TableCellLabelView.swift
//  Proton Mail - Created on 8/16/15.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

class TableCellLabelView: UIView, AccessibleCell {
    fileprivate let kCoverImageViewWidth: CGFloat = 3.0

    fileprivate var textLabel: UILabel!
    fileprivate var contentView: UIView!
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        contentView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 13))
        textLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 13))

        textLabel.text = ""
        textLabel.textColor = UIColor.green
        textLabel.layer.borderWidth = 1
        textLabel.layer.cornerRadius = 2
        textLabel.layer.borderColor = UIColor.green.cgColor
        textLabel.font = Fonts.h7.light
        self.contentView.addSubview(textLabel)
        self.addSubview(contentView)

        textLabel.mas_makeConstraints { (make) -> Void in
            _ = make?.top.equalTo()(self.contentView)
            _ = make?.bottom.equalTo()(self.contentView)
            _ = make?.right.equalTo()(self.contentView)
            _ = make?.left.equalTo()(self.contentView)
        }

        contentView.mas_makeConstraints { (make) -> Void in
            _ = make?.top.equalTo()(self)
            _ = make?.bottom.equalTo()(self)
            _ = make?.left.equalTo()(self)?.offset()(self.kCoverImageViewWidth)
            _ = make?.right.equalTo()(self)
        }
        self.clipsToBounds = true
        self.contentView.clipsToBounds = true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
}
