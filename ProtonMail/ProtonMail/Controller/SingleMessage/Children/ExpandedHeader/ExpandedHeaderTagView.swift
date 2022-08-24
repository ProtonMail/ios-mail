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

final class ExpandedHeaderTagView: PMView {
    @IBOutlet private var iconImageView: UIImageView!
    @IBOutlet private var tagCollectionView: UICollectionView!
    @IBOutlet private var tagCollectionViewHeight: NSLayoutConstraint!

    private var isReloadData = false
    private var tags: [TagUIModel] = []

    override init(frame: CGRect) { // for using CustomView in code
        super.init(frame: frame)
        setUpIcon()
        setUpCollectionView()
    }

    required init(coder aDecoder: NSCoder) { // for using CustomView in IB
        super.init(coder: aDecoder)
        setUpIcon()
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
        tagCollectionViewHeight.constant = height
        layoutIfNeeded()
        isReloadData = false
    }

    override func getNibName() -> String {
        String(describing: ExpandedHeaderTagView.self)
    }

    private func setUpCollectionView() {
        let nib = TagCollectionCell.defaultNib()
        let reuseID = TagCollectionCell.cellID
        tagCollectionView.register(nib, forCellWithReuseIdentifier: reuseID)

        let layout = ExpandedTagFlowLayout()
        layout.minimumLineSpacing = 7
        layout.minimumInteritemSpacing = 4
        layout.sectionInset = .zero
        layout.headerReferenceSize = .zero
        layout.footerReferenceSize = .zero
        tagCollectionView.collectionViewLayout = layout
    }

    private func setUpIcon() {
        iconImageView.image = IconProvider.tag
        iconImageView.tintColor = ColorProvider.IconWeak
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
