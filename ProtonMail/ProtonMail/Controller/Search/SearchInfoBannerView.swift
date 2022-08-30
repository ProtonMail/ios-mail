// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import ProtonCore_UIFoundations
import UIKit

class SearchInfoBannerView: UIView {
    
    let label: UILabel = {
        let label: UILabel = UILabel(frame: CGRect(x:0, y: 0, width: 200, height: 21))
        label.center = CGPoint(x: 160, y: 285)
        label.textAlignment = .center
        label.text = "test"
        return label
    }()
    
    init() {
        super.init(frame: .zero)
        self.addSubviews()
        self.setUpLayout()
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.layoutFittingExpandedSize.width, height: bounds.height)
    }
    
    private func addSubviews(){
        addSubview(self.label)
    }
    
    private func setUpLayout() {
        //TODO add constraints
    }
    
}
