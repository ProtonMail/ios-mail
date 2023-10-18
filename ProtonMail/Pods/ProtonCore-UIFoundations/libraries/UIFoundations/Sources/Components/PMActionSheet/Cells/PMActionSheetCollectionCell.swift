//
//  PMActionSheetGridCell.swift
//  ProtonCore-UIFoundations-iOS - Created on 2023/1/21.
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

#if os(iOS)

import UIKit
import ProtonCoreFoundations

final class PMActionSheetCollectionCell: UITableViewCell, AccessibleView {
    private var collectionView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: .init())
    private var items: [PMActionSheetItem] = []
    private var colInRows: Int = 1
    private let cellIdentifier = "PMActionSheetGridCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = PMActionSheetConfig.shared.actionSheetBackgroundColor
        setUpCollectionView()
        generateAccessibilityIdentifiers()
    }

    @available(iOS, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func config(items: [PMActionSheetItem], colInRows: Int) {
        self.items = items
        self.colInRows = colInRows
        collectionView.setCollectionViewLayout(flowLayout(boundSize: bounds.size), animated: false)
        collectionView.reloadData()
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        collectionView.setCollectionViewLayout(flowLayout(boundSize: targetSize), animated: false)
        collectionView.layoutIfNeeded()
        let contentSize = collectionView.collectionViewLayout.collectionViewContentSize
        let topPadding: CGFloat = 8
        let size = CGSize(width: contentSize.width, height: contentSize.height + topPadding)
        return  size
    }
}

extension PMActionSheetCollectionCell {
    private func setUpCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PMActionSheetGridCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        ])
    }

    private func flowLayout(boundSize: CGSize) -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        let collectionPadding: CGFloat = 16
        let collectionWidth = boundSize.width - 2 * collectionPadding

        let interItemSpacing: CGFloat = 9
        let width = (collectionWidth - (CGFloat(colInRows - 1) * interItemSpacing)) / CGFloat(colInRows)
        layout.estimatedItemSize = CGSize(width: floor(width), height: 64)
        layout.minimumLineSpacing = PMActionSheetConfig.shared.gridLineSpacing
        layout.minimumInteritemSpacing = interItemSpacing
        return layout
    }
}

extension PMActionSheetCollectionCell: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView
            .dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? PMActionSheetGridCell,
              let component = items[safeIndex: indexPath.row]?.components else {
            return UICollectionViewCell()
        }

        cell.config(indexPath: indexPath, components: component)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = items[safeIndex: indexPath.row] else { return }
        item.handler?(item)
    }
}

extension PMActionSheetCollectionCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }

        let rowsWithFullCols = Int(floor(CGFloat(items.count) / CGFloat(colInRows)))
        let isFullRow = rowsWithFullCols * colInRows > indexPath.row && items.count >= colInRows
        if isFullRow {
            return layout.estimatedItemSize
        }

        let collectionPadding: CGFloat = 16
        let collectionWidth = bounds.width - 2 * collectionPadding
        let colsInLastRow = items.count % colInRows
        let hPadding: CGFloat = 9
        let width = (collectionWidth - (CGFloat(colsInLastRow - 1) * hPadding)) / CGFloat(colsInLastRow)
        return .init(width: width, height: 64)
    }
}

#endif
