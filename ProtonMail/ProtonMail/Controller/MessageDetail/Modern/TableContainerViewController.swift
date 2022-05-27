//
//  EmbeddingViewController.swift
//  Proton Mail - Created on 11/04/2019.
//
//
//  Copyright (c) 2019 Proton AG
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

import UIKit
import ProtonCore_UIFoundations

protocol ScrollableContainer: AnyObject {
    func propagate(scrolling: CGPoint, boundsTouchedHandler: () -> Void)
    var scroller: UIScrollView { get }

    func saveOffset()
}

private enum ComposerCell: String {
    case header = "ComposerHeaderCell"
    case body = "ComposerBodyCell"
    case attachment = "ComposerAttachmentCell"

    static func reuseID(for indexPath: IndexPath) -> String {
        switch indexPath.row {
        case 0:
            return ComposerCell.header.rawValue
        case 1:
            return ComposerCell.body.rawValue
        case 2:
            return ComposerCell.attachment.rawValue
        default:
            return ComposerCell.header.rawValue
        }
    }
}

class TableContainerViewController<ViewModel: TableContainerViewModel, Coordinator: TableContainerViewCoordinator>: UIViewController, ProtonMailViewControllerProtocol, UITableViewDelegate, UITableViewDataSource, ScrollableContainer, BannerPresenting, AccessibleView {

    let tableView = UITableView()

    @IBOutlet weak var menuButton: UIBarButtonItem!

    func configureNavigationBar() {
        ProtonMailViewController.configureNavigationBar(self)
    }

    // legacy

    @IBOutlet weak var backButton: UIBarButtonItem!

    // new code

    let viewModel: ViewModel
    let coordinator: Coordinator
    private var contentOffsetToPerserve: CGPoint = .zero

    init(viewModel: ViewModel, coordinator: Coordinator) {
        self.viewModel = viewModel
        self.coordinator = coordinator

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addSubviews()
        setUpLayout()

        UIViewController.setup(self, self.menuButton, self.shouldShowSideMenu())

        // table view
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: ComposerCell.header.rawValue)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: ComposerCell.body.rawValue)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: ComposerCell.attachment.rawValue)
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 85
        self.tableView.bounces = false
        self.tableView.separatorInset = .zero
        self.tableView.tableFooterView = UIView(frame: .zero)

        // events
        NotificationCenter.default.addObserver(self, selector: #selector(scrollToTop), name: .touchStatusBar, object: nil)

        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(restoreOffset), name: UIWindowScene.willEnterForegroundNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(saveOffset), name: UIWindowScene.didEnterBackgroundNotification, object: nil)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(restoreOffset), name: UIApplication.willEnterForegroundNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(saveOffset), name: UIApplication.didEnterBackgroundNotification, object: nil)
        }
        generateAccessibilityIdentifiers()
    }

    private func addSubviews() {
        self.view.addSubview(self.tableView)
    }

    private func setUpLayout() {
        [
            self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ].activate()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // --

    @objc func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.numberOfSections
    }

    @objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfRows(in: section)
    }

    @objc func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = ComposerCell.reuseID(for: indexPath)
        let cell = self.tableView.dequeueReusableCell(withIdentifier: id, for: indexPath)
        cell.contentView.backgroundColor = ColorProvider.BackgroundNorm
        self.coordinator.embedChild(indexPath: indexPath, onto: cell)
        cell.clipsToBounds = true
        return cell
    }

    // --

    func scrollViewDidScroll(_ scrollView: UIScrollView) {}

    @objc func scrollToTop() {
        guard self.presentedViewController == nil, self.navigationController?.topViewController == self else { return }
        self.tableView.scrollToRow(at: .init(row: 0, section: 0), at: .top, animated: true)
    }

    func propagate(scrolling delta: CGPoint, boundsTouchedHandler: () -> Void) {
        UIView.animate(withDuration: 0.001) { // hackish way to show scrolling indicators on tableView
            self.tableView.flashScrollIndicators()
        }
        let maxOffset = self.tableView.contentSize.height - self.tableView.frame.size.height
        guard maxOffset > 0 else { return }

        let yOffset = self.tableView.contentOffset.y + delta.y

        if yOffset < 0 { // not too high
            self.tableView.setContentOffset(.zero, animated: false)
            boundsTouchedHandler()
        } else if yOffset > maxOffset { // not too low
            self.tableView.setContentOffset(.init(x: 0, y: maxOffset), animated: false)
            boundsTouchedHandler()
        } else {
            self.tableView.contentOffset = .init(x: 0, y: yOffset)
        }
    }

    var scroller: UIScrollView {
        return self.tableView
    }

    // --

    @objc func presentBanner(_ sender: BannerRequester) {
        #if !APP_EXTENSION
        guard UIApplication.shared.applicationState == .active else {
            return
        }
        #endif
        guard let banner = sender.errorBannerToPresent() else {
            return
        }
        self.view.addSubview(banner)
        banner.drop(on: self.view, from: .top)
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

// iPads think tableView is resized when app is backgrounded and reloads it's data
// by some mysterious reason if MessageBodyViewController cell occupies whole screen at that moment, tableView will scroll to bottom. So we perserve contentOffset with help of these methods

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        self.saveOffset()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // scrolling happens after traits collection change, so we have to run restore async
        DispatchQueue.main.async {
            self.restoreOffset()
        }
    }

    @objc internal func saveOffset() {
        self.contentOffsetToPerserve = self.tableView.contentOffset
    }

    @objc internal func restoreOffset() {
        self.tableView.setContentOffset(self.contentOffsetToPerserve, animated: false)
    }
}
