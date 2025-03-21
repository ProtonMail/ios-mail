// Copyright (c) 2024 Proton Technologies AG
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

import InboxCoreUI
import UIKit

enum RecipientsFieldExpandedLayout {
    static let minCellHeight: CGFloat = 40.0
}

final class RecipientsFieldExpandedController: UIViewController {
    private let collectionView = SubviewFactory.collectionView

    private var contentSizeObservation: NSKeyValueObservation?
    private var heightConstraint: NSLayoutConstraint!

    private var cellUIModels: [RecipientUIModel] = [] {
        didSet {
            reloadCollectionItems()
        }
    }

    var state: RecipientFieldState {
        didSet {
            if oldValue.recipients != state.recipients {
                cellUIModels = state.recipients
            }
        }
    }

    init(state: RecipientFieldState) {
        self.state = state
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setUpConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        heightConstraint.constant = RecipientsFieldExpandedLayout.minCellHeight
        view.layoutIfNeeded()
    }

    private func setUpUI() {
        view.translatesAutoresizingMaskIntoConstraints = false

        collectionView.dataSource = self
        collectionView.register(cellType: RecipientCell.self)
        view.addSubview(collectionView)

        contentSizeObservation = collectionView.observe(\.contentSize, options: .new) { [weak self] (collection, _) in
            self?.onContentSizeChange(collectionView: collection)
        }
    }

    private func setUpConstraints() {
        heightConstraint = collectionView.heightAnchor.constraint(equalToConstant: .zero)
        heightConstraint.isActive = true

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

// MARK: Private functions

extension RecipientsFieldExpandedController {

    private func onContentSizeChange(collectionView: UICollectionView) {
        let contentHeight = collectionView.collectionViewLayout.collectionViewContentSize.height
        heightConstraint.constant = max(contentHeight, RecipientsFieldExpandedLayout.minCellHeight)
        view.layoutIfNeeded()
    }

    private func reloadCollectionItems() {
        DispatchQueue.main.async { [unowned self] in
            UIView.performWithoutAnimation {
                collectionView.performBatchUpdates({ collectionView.reloadSections(IndexSet(integer: 0)) })
            }
            view.layoutIfNeeded()
        }
    }
}

// MARK: UICollectionViewDataSource

extension RecipientsFieldExpandedController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        cellUIModels.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let recipientCell: RecipientCell = collectionView.dequeueReusableCell(for: indexPath)
        recipientCell.configure(with: cellUIModels[indexPath.item], maxWidth: collectionContentWidth())
        return recipientCell
    }

    private func collectionContentWidth() -> CGFloat {
        collectionView.frame.width
    }
}

extension RecipientsFieldExpandedController {

    private enum SubviewFactory {

        static var collectionView: UICollectionView {
            let view = UICollectionView(frame: .zero, collectionViewLayout: .allRecipientsLayout)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = .clear
            view.isScrollEnabled = false
            return view
        }
    }
}
