// Copyright (c) 2023 Proton Technologies AG
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

import LifetimeTracker
import ProtonCore_UIFoundations

final class BlockedSendersViewController: ProtonMailTableViewController {
    private let viewModel: BlockedSendersViewModelProtocol

    private let cellIdentifier = "BlockedSenderTableViewCell"

    init(viewModel: BlockedSendersViewModelProtocol) {
        self.viewModel = viewModel

        super.init(style: .plain)

        title = L11n.BlockSender.blockListScreenTitle

        trackLifetime()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(userDidPullToRefresh), for: .valueChanged)
        self.refreshControl = refreshControl

        tableView.allowsSelection = false
        tableView.noSeparatorsAboveFirstCell()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.zeroMargin()

        view.backgroundColor = ColorProvider.BackgroundDeep

        viewModel.output.setUIDelegate(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.input.viewWillAppear()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.output.numberOfRows()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let cellModel = viewModel.output.modelForCell(at: indexPath)
        cell.textLabel?.text = cellModel.title
        return cell
    }

    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        switch editingStyle {
        case .delete:
            let model = viewModel.output.modelForCell(at: indexPath)

            do {
                try viewModel.input.deleteRow(at: indexPath)

                showBanner(
                    message: String(format: L11n.BlockSender.successfulUnblockConfirmation, model.title),
                    style: .info
                )
            } catch {
                showBanner(message: "\(error)", style: .error)
            }
        default:
            assertionFailure("Unsupported editing style: \(editingStyle)")
        }
    }

    private func showBanner(message: String, style: PMBannerNewStyle) {
        let banner = PMBanner(message: message, style: style, bannerHandler: PMBanner.dismiss)
        banner.show(at: .bottom, on: self)
    }

    @objc
    private func userDidPullToRefresh() {
        viewModel.input.userDidPullToRefresh()
    }
}

extension BlockedSendersViewController: BlockedSendersViewModelUIDelegate {
    func refreshView(state: BlockedSendersViewModel.State) {
        let backgroundView: UIView?
        let refreshControlShouldBeRefreshing: Bool
        let rightBarButtonItem: UIBarButtonItem?

        switch state {
        case .blockedSendersFetched(let blockedSenders):
            if blockedSenders.isEmpty {
                backgroundView = SubviewFactory.emptyListPlaceholder()
                rightBarButtonItem = nil
            } else {
                backgroundView = nil
                rightBarButtonItem = editButtonItem
            }

            refreshControlShouldBeRefreshing = false
        case .fetchInProgress:
            backgroundView = nil
            refreshControlShouldBeRefreshing = true
            rightBarButtonItem = nil
        }

        navigationItem.rightBarButtonItem = rightBarButtonItem

        if refreshControlShouldBeRefreshing {
            if refreshControl?.isRefreshing == false {
                refreshControl?.beginRefreshing()
            }
        } else {
            refreshControl?.endRefreshing()
        }

        tableView.backgroundView = backgroundView
        tableView.reloadData()
    }
}

extension BlockedSendersViewController: LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }
}

extension BlockedSendersViewController {
    private enum SubviewFactory {
        static func emptyListPlaceholder() -> UIView {
            let container = UIView()

            let placeholderLabel = UILabel()
            placeholderLabel.numberOfLines = 0
            placeholderLabel.set(
                text: L11n.BlockSender.emptyList,
                preferredFont: .body,
                textColor: ColorProvider.TextHint
            )
            placeholderLabel.textAlignment = .center

            container.addSubview(placeholderLabel)
            placeholderLabel.centerInSuperview()
            placeholderLabel.leftAnchor.constraint(equalTo: container.leftAnchor, constant: 8).isActive = true

            return container
        }
    }
}
