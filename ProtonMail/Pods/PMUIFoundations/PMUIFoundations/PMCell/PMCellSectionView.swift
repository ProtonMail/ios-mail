//
//  PMCellSectionView.swift
//  PMUIFoundations
//
//  Created by Igor Kulman on 16.12.2020.
//

import UIKit

public final class PMCellSectionView: UITableViewHeaderFooterView {

    public static let reuseIdentifier = "PMCellSectionView"
    public static let nib = UINib(nibName: "PMCellSectionView", bundle: PMUIFoundations.bundle)

    // MARK: - Outlets

    @IBOutlet private weak var titleLabel: UILabel!

    // MARK: - Properties

    public var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    public override func awakeFromNib() {
        super.awakeFromNib()

        titleLabel.textColor = UIColorManager.TextWeak
        contentView.backgroundColor = UIColor.dynamic(light: .white, dark: .black)
    }
}
