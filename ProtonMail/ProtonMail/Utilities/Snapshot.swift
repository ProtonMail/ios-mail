//
//  Snapshot.swift
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


import UIKit
import Foundation

class Snapshot {
    fileprivate struct Tag {
        static let snapshot = 101
    }
    
    fileprivate struct NibName {
        static let Name = "LaunchScreen"
    }
    
    private lazy var view: UIView = self.getFancyView() ?? self.getDefaultView()
    
    internal func show(at window: UIView) {
        window.addSubview(self.view)
        view.mas_makeConstraints { (make) -> Void in
            make?.top.equalTo()(window)
            make?.left.equalTo()(window)
            make?.right.equalTo()(window)
            make?.bottom.equalTo()(window)
        }
    }
    
    internal func remove() {
        self.view.removeFromSuperview()
    }
    
    private func getFancyView() -> UIView? {
        guard let view = Bundle.main.loadNibNamed(NibName.Name, owner: nil, options: nil)?.first as? UIView else {
            return nil
        }
        view.tag = Tag.snapshot
        return view
    }
    
    private func getDefaultView() -> UIView {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = UIColor.ProtonMail.Blue_85B1DE
        view.tag = Tag.snapshot
        return view
    }
}
