//
//  PMActionSheetGridCell.swift
//  ProtonCore-UIFoundations - Created on 22.07.20.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import UIKit
import ProtonCore_Foundations

protocol PMActionSheetGridDelegate: AnyObject {
    func tapGridItemAt(section: Int, row: Int)
}

final class PMActionSheetGridCell: UITableViewCell, AccessibleView {
    // MARK: Constants
    private let ROW_HEIGHT: CGFloat = 100
    private let TAGOFFSET = 10
    private let ICON_SIZE: CGFloat = 32
    private let PADDING: CGFloat = 2

    // MARK: Variable
    private var indexPath: IndexPath = IndexPath(row: -1, section: -1)
    private var containerStack: UIStackView?
    private weak var delegate: PMActionSheetGridDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.containerStack = nil
    }
}

// MARK: Public function
extension PMActionSheetGridCell {
    func config(group: PMActionSheetItemGroup, at indexPath: IndexPath, delegate: PMActionSheetGridDelegate) throws {
        guard group.style == .grid else {
            throw PMActionSheetError.styleError
        }
        self.backgroundColor = ColorProvider.BackgroundNorm
        self.delegate = delegate
        self.indexPath = indexPath
        let numberOfRow: CGFloat = CGFloat((group.items.count + 1) / 2)
        let container = self.createContainer(numberOfRow: numberOfRow)
        self.appendSubitems(group.items, in: container, numberOfRow: numberOfRow)
        generateAccessibilityIdentifiers()
    }
}

extension PMActionSheetGridCell {
    private func setupGesture(gridView: UIView) {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressGridView(ges:)))
        longPress.minimumPressDuration = 0
        gridView.addGestureRecognizer(longPress)
    }

    @objc private func longPressGridView(ges: UILongPressGestureRecognizer) {
        guard let view = ges.view else { return }
        switch ges.state {
        case .began:
            view.backgroundColor = ColorProvider.BackgroundSecondary
        case .ended:
            view.backgroundColor = .clear
            let point = ges.location(in: view)
            let width = view.bounds.size.width

            guard 0 <= point.x,
                point.x <= width,
                0 <= point.y,
                point.y <= ROW_HEIGHT else { return }

            let row = view.tag - TAGOFFSET
            self.delegate?.tapGridItemAt(section: self.indexPath.section, row: row)
        default:
            break
        }
    }
}

// MARK: UI Relative
extension PMActionSheetGridCell {
    private func createContainer(numberOfRow: CGFloat) -> UIStackView {
        let container = UIStackView(.vertical, alignment: .fill, distribution: .fillEqually, useAutoLayout: true)
        self.contentView.addSubview(container)
        let view = self.contentView
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.heightAnchor.constraint(equalToConstant: ROW_HEIGHT * numberOfRow)
        ])
        self.containerStack = container
        return container
    }

    private func appendSubitems(_ items: [PMActionSheetItem], in container: UIStackView, numberOfRow: CGFloat) {
        var currentStack: UIStackView?
        for (idx, item) in items.enumerated() {
            if currentStack == nil {
                currentStack = UIStackView(.horizontal, alignment: .fill, distribution: .fillEqually)
                self.containerStack?.addArrangedSubview(currentStack!)
            }
            let row = CGFloat((idx + 2) / 2)
            let isLastRow = row == numberOfRow
            let hasRLine = ((idx & 1) == 0) && idx < items.count - 1
            let gridView = self.createGridView(item, index: idx, hasRLine: hasRLine, hasBLine: !isLastRow)
            currentStack?.addArrangedSubview(gridView)
            if !hasRLine {
                currentStack = nil
            }
        }
    }

    private func createGridView(_ item: PMActionSheetItem, index: Int, hasRLine: Bool, hasBLine: Bool) -> UIView {

        let view = UIView()
        view.tag = TAGOFFSET + index
        self.setupGesture(gridView: view)
        let imgView = self.createImageView(item.icon, color: item.iconColor)
        self.setupGridIconConstraint(imgView, in: view)
        let label = UILabel(item.title,
                            font: .adjustedFont(forTextStyle: .body),
                            textColor: item.textColor,
                            alignment: .center,
                            useAutoLayout: true)
        self.setupGridLabelConstraint(label, in: view, under: imgView)

        if hasRLine {
            self.addSeperateLine(.vertical, in: view)
        }

        if hasBLine {
            self.addSeperateLine(.horizontal, in: view)
        }
        return view
    }

    private func createImageView(_ icon: UIImage?, color: UIColor) -> UIImageView {
        let imgView = UIImageView(image: icon)
        imgView.tintColor = color
        imgView.contentMode = .scaleAspectFit
        imgView.translatesAutoresizingMaskIntoConstraints = false
        return imgView
    }

    private func setupGridIconConstraint(_ imgView: UIImageView, in view: UIView) {
        view.addSubview(imgView)
        imgView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        imgView.topAnchor.constraint(equalTo: view.topAnchor, constant: 23).isActive = true
        imgView.widthAnchor.constraint(equalToConstant: ICON_SIZE).isActive = true
        imgView.heightAnchor.constraint(equalToConstant: ICON_SIZE).isActive = true
    }

    private func setupGridLabelConstraint(_ label: UILabel, in view: UIView, under imgView: UIImageView) {
        view.addSubview(label)
        label.topAnchor.constraint(equalTo: imgView.bottomAnchor, constant: PADDING).isActive = true
        label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: PADDING).isActive = true
        label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: PADDING).isActive = true
    }

    private func addSeperateLine(_ axis: NSLayoutConstraint.Axis, in view: UIView) {
        let line = UIView()
        line.backgroundColor = ColorProvider.SeparatorNorm
        line.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(line)

        if axis == .horizontal {
            line.heightAnchor.constraint(equalToConstant: 1).isActive = true
            line.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8).isActive = true
            line.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            line.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        } else {
            line.widthAnchor.constraint(equalToConstant: 1).isActive = true
            line.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.8).isActive = true
            line.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            line.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        }
    }
}
