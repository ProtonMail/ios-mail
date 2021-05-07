//
//  PMActionSheetPlainCellHeaderHeader.swift
//  PMUIFoundations
//
//  Created by Aaron Huánuco on 20/08/2020.
//

import UIKit

class PMActionSheetPlainCellHeader: UITableViewHeaderFooterView, LineSeparatable, Reusable {
    private lazy var label = UILabel(nil, font: .systemFont(ofSize: 13),
                                     textColor: AdaptiveTextColors._N3)
    private var separator: UIView?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        setupBackground()
        setupLabel()
    }

    func setupBackground() {
        contentView.backgroundColor = BackgroundColors._Main
    }
    func setupLabel() {
        addSubview(label)
        label.centerXInSuperview(constant: 16)
        label.leftAnchor.constraint(equalTo: leftAnchor, constant: 16).isActive = true
        label.topAnchor.constraint(equalTo: topAnchor, constant: 23).isActive = true
        label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -15).isActive = true
        label.numberOfLines = 1
        label.backgroundColor = BackgroundColors._Main
        separator = addSeparator(padding: 0)
    }

    func config(title: String) {
        label.text = title.uppercased()
    }
}
