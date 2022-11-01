// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import ProtonCore_UIFoundations
import UIKit

final class ExpandedHeaderTagView: UIView {
    private let iconImageView = SubviewsFactory.iconImageView()
    private let tagCollectionView = SubviewsFactory.tagCollection()
    private var tagCollectionViewHeight: NSLayoutConstraint?

    private var isReloadData = false
    private var tags: [TagUIModel] = []

    override init(frame: CGRect) { // for using CustomView in code
        super.init(frame: frame)
        addSubViews()
        setUpConstraints()
        setUpCollectionView()
    }

    required init?(coder aDecoder: NSCoder) { // for using CustomView in IB
        super.init(coder: aDecoder)
        addSubViews()
        setUpConstraints()
        setUpCollectionView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if isReloadData {
            return
        }
        isReloadData = true
        // So collection view can get the correct frame
        tagCollectionView.reloadData()
        let height = tagCollectionView.collectionViewLayout.collectionViewContentSize.height
        tagCollectionViewHeight?.constant = height
        layoutIfNeeded()
        isReloadData = false
    }

    private func addSubViews() {
        backgroundColor = .clear
        addSubview(iconImageView)
        addSubview(tagCollectionView)
    }

    private func setUpConstraints() {
        [
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            iconImageView.topAnchor.constraint(equalTo: topAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20)
        ].activate()

        let heightConstraint = tagCollectionView.heightAnchor.constraint(equalToConstant: 76)
        tagCollectionViewHeight = heightConstraint
        [
            tagCollectionView.topAnchor.constraint(equalTo: iconImageView.topAnchor, constant: 1),
            tagCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            tagCollectionView.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            tagCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            heightConstraint
        ].activate()
    }

    private func setUpCollectionView() {
        tagCollectionView.dataSource = self
        tagCollectionView.delegate = self
    }

    func setUp(tags: [TagUIModel]) {
        self.tags = tags
    }
}

extension ExpandedHeaderTagView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        tags.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let reuseID = TagCollectionCell.cellID
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseID, for: indexPath)
        guard let tagCell = cell as? TagCollectionCell,
              let info = tags[safe: indexPath.row] else { return cell }
        tagCell.setup(backgroundColor: info.color,
                      title: info.title?.string ?? .empty,
                      titleColor: .white)
        return tagCell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let info = tags[safe: indexPath.row] else { return .zero }
        let text = info.title?.string ?? .empty
        let label = UILabel(font: .systemFont(ofSize: 11), text: text, textColor: .black)
        label.sizeToFit()
        let width = min(label.frame.width + 16, collectionView.frame.width - 8)
        return CGSize(width: width, height: 18)
    }
}

private struct SubviewsFactory {
    static func tagCollection() -> UICollectionView {
        let layout = ExpandedTagFlowLayout()
        layout.minimumLineSpacing = 7
        layout.minimumInteritemSpacing = 4
        layout.sectionInset = .zero
        layout.headerReferenceSize = .zero
        layout.footerReferenceSize = .zero

        let tagCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        tagCollectionView.backgroundColor = .clear
        let nib = TagCollectionCell.defaultNib()
        let reuseID = TagCollectionCell.cellID
        tagCollectionView.register(nib, forCellWithReuseIdentifier: reuseID)
        return tagCollectionView
    }

    static func iconImageView() -> UIImageView {
        let iconImageView = UIImageView()
        iconImageView.image = IconProvider.tag
        iconImageView.tintColor = ColorProvider.IconWeak
        return iconImageView
    }
}
