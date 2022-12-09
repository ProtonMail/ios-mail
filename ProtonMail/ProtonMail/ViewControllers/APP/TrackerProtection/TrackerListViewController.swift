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

import LifetimeTracker
import ProtonCore_UIFoundations
import UIKit

class TrackerListViewController: UIViewController, LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }

    let trackers: [TrackerInfo]

    private let tableView = SubviewFactory.tableView
    private var titleLabel: UILabel?
    private var detailTextView: UITextView?

    private var expandedSection: Int? {
        didSet {
            var sectionsToReload = IndexSet()

            if let previouslyExpandedSection = oldValue {
                sectionsToReload.insert(previouslyExpandedSection)
            }

            if let newlyExpandedSection = expandedSection {
                sectionsToReload.insert(newlyExpandedSection)
            }

            tableView.reloadSections(sectionsToReload, with: .automatic)
        }
    }

    init(trackerProtectionSummary: TrackerProtectionSummary) {
        trackers = trackerProtectionSummary.trackers
            .sorted { $0.key.compare($1.key) == .orderedAscending }
            .map {
                TrackerInfo(
                    provider: $0.key,
                    urls: $0.value.sorted()
                )
            }

        super.init(nibName: nil, bundle: nil)

        title = L11n.EmailTrackerProtection.title
        trackLifetime()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = customView()
    }

    private func customView() -> UIView {
        let trackerCount = trackers.map(\.urls.count).reduce(0, +)
        let tableViewHeader = SubviewFactory.tableViewHeader(numberOfTrackers: trackerCount)
        titleLabel = tableViewHeader.arrangedSubviews.first as? UILabel
        detailTextView = tableViewHeader.arrangedSubviews[safe: 1] as? UITextView

        tableView.register(viewType: TrackerTableViewHeaderView.self)
        tableView.register(cellType: TrackerTableViewCell.self)
        tableView.dataSource = self
        tableView.delegate = self

        let fakeSeparatorAtTop = SubviewFactory.fakeSeparatorAtTop
        fakeSeparatorAtTop.backgroundColor = tableView.separatorColor

        let stackView = UIStackView(arrangedSubviews: [fakeSeparatorAtTop, tableViewHeader, tableView])
        stackView.axis = .vertical

        return SubviewFactory.viewToRenderBackground(wrapping: stackView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(preferredContentSizeChanged(_:)),
                         name: UIContentSizeCategory.didChangeNotification,
                         object: nil)
    }

    @objc
    private func preferredContentSizeChanged(_ notification: Notification) {
        // The following elements can't reflect font size changed automatically
        // Reset font when event happened
        tableView.reloadData()
        titleLabel?.font = .adjustedFont(forTextStyle: .headline)
        detailTextView?.font = .adjustedFont(forTextStyle: .subheadline)
    }
}

extension TrackerListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        trackers.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == expandedSection ? trackers[section].urls.count : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cellType: TrackerTableViewCell.self)
        let trackerInfo = trackers[indexPath.section]
        let url = trackerInfo.urls[indexPath.row]
        cell.configure(with: url)
        return cell
    }
}

extension TrackerListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeue(viewType: TrackerTableViewHeaderView.self)
        let trackerInfo = trackers[section]
        let isExpanded = section == expandedSection
        header.configure(with: trackerInfo, isExpanded: isExpanded) { [weak self] in
            self?.expandedSection = isExpanded ? nil : section
        }
        return header
    }
}

private enum SubviewFactory {
    static var fakeSeparatorAtTop: UIView {
        let view = UIView()
        view.addConstraint(view.heightAnchor.constraint(equalToConstant: 0.5))
        return view
    }

    static var tableView: UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.zeroMargin()
        return tableView
    }

    static func tableViewHeader(numberOfTrackers: Int) -> UIStackView {
        let titleLabel = titleLabel(numberOfTrackers: numberOfTrackers)
        let detailsLabel = detailsLabel(numberOfTrackers: numberOfTrackers)

        let stackView = UIStackView(arrangedSubviews: [titleLabel, detailsLabel])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.isLayoutMarginsRelativeArrangement = true
        let margin: CGFloat = 16
        stackView.directionalLayoutMargins = .init(top: margin, leading: margin, bottom: margin, trailing: margin)
        return stackView
    }

    private static func titleLabel(numberOfTrackers: Int) -> UILabel {
        let titleLabel = UILabel()
        titleLabel.attributedText = String
            .localizedStringWithFormat(L11n.EmailTrackerProtection.n_email_trackers_blocked, numberOfTrackers)
            .apply(style: FontManager.DefaultStrong)
        return titleLabel
    }

    private static func detailsLabel(numberOfTrackers: Int) -> UIView {
        let details = NSMutableAttributedString()
        let attributes = FontManager.DefaultSmall

        let plainTextMessageComponents: [String] = [
            L11n.EmailTrackerProtection.email_trackers_can_violate_your_privacy,
            String.localizedStringWithFormat(
                L11n.EmailTrackerProtection.proton_found_n_trackers_on_this_message,
                numberOfTrackers
            )
        ]
        for component in plainTextMessageComponents {
            details.append(NSAttributedString(string: "\(component) ", attributes: attributes))
        }

        let learnMoreAttributes = attributes.link(url: Link.emailTrackerProtection)
        let learnMoreString = NSAttributedString(string: LocalString._learn_more, attributes: learnMoreAttributes)
        details.append(learnMoreString)

        let detailsTextView = UITextView()
        detailsTextView.attributedText = details
        detailsTextView.backgroundColor = .clear
        detailsTextView.isEditable = false
        detailsTextView.isScrollEnabled = false
        detailsTextView.textContainer.lineFragmentPadding = 0
        detailsTextView.textContainerInset = .zero
        return detailsTextView
    }

    static func viewToRenderBackground(wrapping stackView: UIStackView) -> UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.BackgroundNorm
        view.addSubview(stackView)
        stackView.fillSuperview()
        return view
    }
}
