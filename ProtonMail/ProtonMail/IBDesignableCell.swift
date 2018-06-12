//
//  IBDesignableCell.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 10/06/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

/// Calling method labelAtInterfaceBuilder() in prepareForInterfaceBuilder() of a concrete class will label cell with a class name in Interface Builder.
protocol IBDesignableCell: class {}
extension IBDesignableCell where Self: UITableViewCell {
    internal func labelAtInterfaceBuilder() {
        let label = UILabel.init(frame: self.contentView.bounds)
        label.text = "\(Self.self)"
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        
        let colors: [UIColor] = [.magenta, .green, .blue]
        
        self.contentView.backgroundColor = colors[Int(arc4random_uniform(UInt32(colors.count)))]
        self.contentView.addSubview(label)
    }
}
