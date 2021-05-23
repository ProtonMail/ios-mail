
//  Fonts.swift
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

//TODO:: move this to UI
enum Fonts : CGFloat {
    case h1 = 24.0
    /// size 18
    case h2 = 18.0
    case h3 = 17.0
    /// size 16
    case h4 = 16.0
    case h5 = 14.0
    /// size 12
    case h6 = 12.0
    case h7 = 9.0
    /// custom size
    case s20 = 20.0
    case s13 = 13.0
    
    var regular : UIFont {
        return UIFont.systemFont(ofSize: self.rawValue, weight: .regular)
    }
    
    var light : UIFont {
        return UIFont.systemFont(ofSize: self.rawValue, weight: .light)
    }
    
    var medium : UIFont {
        return UIFont.systemFont(ofSize: self.rawValue, weight: .medium)
    }
    
    var bold : UIFont {
        return UIFont.systemFont(ofSize: self.rawValue, weight: .bold)
    }
    
    var semiBold: UIFont {
        return UIFont.systemFont(ofSize: self.rawValue, weight: .semibold)
    }
}


extension UIFont {
    static var highlightSearchTextForTitle: UIFont {
        return  Fonts.h2.bold
    }
    
    static var highlightSearchTextForSubtitle: UIFont {
        return  Fonts.h5.bold
    }
}
