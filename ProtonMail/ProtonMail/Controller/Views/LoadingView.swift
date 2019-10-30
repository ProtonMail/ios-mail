//
//  LoadingView.swift
//  ProtonMail
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

class LoadingView: UIView {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadingLabel: UILabel!
    
    fileprivate struct NibName {
        static let Name = "LoadingView"
    }
    
    class func viewForOwner(_ owner: Any?) -> LoadingView {
        if let objects = Bundle.main.loadNibNamed(NibName.Name, owner: owner, options: nil) {
            for object in objects {
                if let view = object as? LoadingView {
                    return view
                }
            }
        }
        assertionFailure("LoadingView did not load from nib!")
        return LoadingView()
    }
}
