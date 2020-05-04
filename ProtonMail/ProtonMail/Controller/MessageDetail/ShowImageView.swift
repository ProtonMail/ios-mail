//
//  ShowImageView.swift
//  ProtonMail - Created on 3/22/16.
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

protocol ShowImageViewDelegate : AnyObject {
    func showImage()
}

class ShowImageView: PMView {
    
    @IBOutlet weak var showImageButton: UIButton!
    weak var delegate : ShowImageViewDelegate?
    
    override func getNibName() -> String {
        return "ShowImageView"
    }
    
    @IBAction func clickAction(_ sender: AnyObject) {
        self.delegate?.showImage()
    }
    
    override func setup() {
        showImageButton.layer.borderColor = UIColor.ProtonMail.Gray_C9CED4.cgColor
        showImageButton.layer.borderWidth = 1.0
        showImageButton.layer.cornerRadius = 2.0
        showImageButton.setTitle(LocalString._load_remote_content, for: .normal)
    }
}

class ShowImageCell: UITableViewCell {
    @IBOutlet weak var showImageView: ShowImageView!
}
