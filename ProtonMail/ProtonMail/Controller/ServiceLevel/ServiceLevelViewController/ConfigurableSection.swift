//
//  ConfigurableSection.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 12/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

struct Section<Element: UIView> {
    fileprivate(set) var elements: Array<Element>
    var cellType: ConfigurableCell.Type
    var count: Int {
        return self.elements.count
    }
    func embed(_ elementNumber: Int, onto cell: ConfigurableCell) {
        cell.configure(with: self.elements[elementNumber])
    }
}
