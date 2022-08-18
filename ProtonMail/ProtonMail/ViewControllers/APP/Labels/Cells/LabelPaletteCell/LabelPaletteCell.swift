//
//  LabelPaletteCell.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations
import UIKit

protocol LabelPaletteCellDelegate: AnyObject {
    func selectColor(hex: String, index: Int)
}

final class LabelPaletteCell: UITableViewCell {

    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var collectionHeight: NSLayoutConstraint!
    private weak var delegate: LabelPaletteCellDelegate?
    private var colors: [String] = []
    private var intenseColors: [String] = []
    private var selectedColor: String = ""
    private var type: PMLabelType = .unknown
    private let itemSize = CGSize(width: 32, height: 32)
    private var verticalPadding: CGFloat = 24

    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.backgroundColor = ColorProvider.BackgroundNorm
        self.collectionView.backgroundColor = ColorProvider.BackgroundNorm
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(LabelColorCell.defaultNib(), forCellWithReuseIdentifier: LabelColorCell.identifier)
    }

    func config(colors: [String],
                intenseColors: [String],
                selected: String,
                type: PMLabelType,
                delegate: LabelPaletteCellDelegate?) {
        self.colors = colors
        self.intenseColors = intenseColors
        self.selectedColor = selected
        self.type = type
        self.configSpacing(type: type)
        self.collectionView.reloadData()
        self.collectionHeight.constant = self.itemSize.height * 2 + self.verticalPadding
        self.delegate = delegate
    }

    private func configSpacing(type: PMLabelType) {
        self.verticalPadding = type == .label ? 24 : 32
        // left / right padding to the screen edge
        let padding: CGFloat = 28
        let screenSize = UIScreen.main.bounds.width
        let space: CGFloat = (screenSize - 2 * padding - 5 * self.itemSize.width) / 4
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = self.itemSize
        layout.minimumLineSpacing = self.verticalPadding
        layout.minimumInteritemSpacing = floor(space)
        self.collectionView.collectionViewLayout = layout
    }
}

extension LabelPaletteCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.colors.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = LabelColorCell.identifier
        guard let cell = collectionView
                .dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? LabelColorCell else {
            return .init()
        }
        let colorHex = self.colors[indexPath.row]
        let color = UIColor(hexColorCode: colorHex)
        let intenseHex = self.intenseColors[indexPath.row]
        let intenseColor = UIColor(hexColorCode: intenseHex)
        let isSelected = colorHex == self.selectedColor
        cell.config(color: color,
                    intenseColor: intenseColor,
                    type: self.type,
                    isSelected: isSelected)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        if let index = self.colors.firstIndex(of: self.selectedColor) {
            let path = IndexPath(row: index, section: 0)
            let cell = collectionView.cellForItem(at: path) as? LabelColorCell
            cell?.setSelected(isSelected: false)
        }

        let row = indexPath.row
        let cell = collectionView.cellForItem(at: indexPath) as? LabelColorCell
        cell?.setSelected(isSelected: true)

        let colorHex = self.colors[row]
        self.selectedColor = colorHex
        self.delegate?.selectColor(hex: colorHex, index: row)
    }
}
