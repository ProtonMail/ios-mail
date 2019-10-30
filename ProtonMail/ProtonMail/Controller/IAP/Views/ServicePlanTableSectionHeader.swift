//
//  TableSectionHeader.swift
//  ProtonMail - Created on 19/08/2018.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation

class ServicePlanTableSectionHeader: UIView {
    @IBOutlet private weak var title: UILabel!
    
    convenience init(title: String, textAlignment: NSTextAlignment) {
        self.init(frame: .zero)
        defer {
            self.setup(title: title, textAlignment: textAlignment)
        }
    }
    
    func setup(title: String, textAlignment: NSTextAlignment) {
        self.title.text = title
        self.title.textAlignment = textAlignment
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadFromNib()
        self.setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadFromNib()
        self.setupSubviews()
    }
    
    private func setupSubviews() {
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var textSize = self.title.textRect(forBounds: CGRect(origin: .zero, size: size).insetBy(dx: 20, dy: 20),
                                           limitedToNumberOfLines: 0)
        textSize = textSize.insetBy(dx: -20, dy: -20)
        return textSize.size
    }
}
