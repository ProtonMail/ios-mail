//
//  Images.swift
//  ProtonMail - Created on 12/6/18.
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

extension UIImage {
    
    enum Top {
        static var archive: UIImage? {
            return UIImage(named: "top_archive")
        }

        static var compose: UIImage? {
            return UIImage(named: "top_compose")
        }
        
        static var search: UIImage? {
            return UIImage(named: "top_search")
        }
        
        static var more: UIImage? {
            return UIImage(named: "top_more")
        }

        static var unread: UIImage? {
            return UIImage(named: "top_unread")
        }

        static var label: UIImage? {
            return UIImage(named: "top_label")
        }
        
        static var folder: UIImage? {
            return UIImage(named: "top_folder")
        }
    
        static var trash: UIImage? {
            return UIImage(named: "top_trash")
        }
        
//        static var favorite: UIImage? {
//            return UIImage(named: "favorite")
//        }

    }
    
}
