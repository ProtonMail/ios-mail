//
//  TableSectionHeader.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 19/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class TableSectionHeader: UIView {
    @IBOutlet private weak var title: UILabel!
    
    convenience init(title: String) {
        self.init(frame: .zero)
        self.title.text = title
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
        var textSize = self.title.textRect(forBounds: .init(origin: .zero, size: size), limitedToNumberOfLines: 0)
        textSize = textSize.insetBy(dx: 0, dy: -20.0) // FIXME: magic number
        return textSize.size
    }
}
