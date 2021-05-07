//
//  LabelPaletteCell.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
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

import PMUIFoundations
import UIKit

protocol LabelPaletteCellDelegate: AnyObject {
    func selectColor(hex: String, index: Int)
}

final class LabelPaletteCell: UITableViewCell {

    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var collectionHeight: NSLayoutConstraint!
    private weak var delegate: LabelPaletteCellDelegate?
    private var colors: [String] = []
    private var selectedColor: String = ""
    private var type: PMLabelType = .unknow
    private let itemSize = CGSize(width: 48, height: 48)

    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.backgroundColor = UIColorManager.BackgroundNorm
        self.collectionView.backgroundColor = UIColorManager.BackgroundNorm
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(LabelColorCell.defaultNib(), forCellWithReuseIdentifier: LabelColorCell.identifier)

        let padding: CGFloat = 35
        let screenSize = UIScreen.main.bounds.width
        let space: CGFloat = (screenSize - 2 * padding - 4 * self.itemSize.width) / 3
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = self.itemSize
        layout.minimumLineSpacing = self.itemSize.height
        layout.minimumInteritemSpacing = floor(space)
        self.collectionView.collectionViewLayout = layout
    }

    func config(colors: [String], selected: String, type: PMLabelType, delegate: LabelPaletteCellDelegate?) {
        self.colors = colors
        self.selectedColor = selected
        self.type = type
        self.collectionView.reloadData()
        self.collectionHeight.constant = self.itemSize.height * 9
        self.delegate = delegate
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
        let isSelected = colorHex == self.selectedColor
        cell.config(color: color, type: self.type, isSelected: isSelected)
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
