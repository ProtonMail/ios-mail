//
//  ContactDetailsEmailCell.swift
//  ProtonMail - Created on 5/3/17.
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

import ProtonCore_UIFoundations

final class ContactDetailsDisplayCell: UITableViewCell {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var value: UILabel!

    func configCell(title : String, value : String) {
        contentView.backgroundColor = ColorProvider.BackgroundNorm

        self.title.attributedText = title.apply(style: .DefaultSmallWeek)
        
        let attribute = FontManager.Default.addTruncatingTail()
        self.value.attributedText = value.apply(style: attribute)
    }
    
}
