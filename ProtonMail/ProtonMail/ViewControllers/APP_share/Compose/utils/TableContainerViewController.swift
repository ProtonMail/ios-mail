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

import ProtonCoreFoundations
import ProtonCoreUIFoundations
import UIKit

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

class TableContainerViewController<ViewModel: TableContainerViewModel>: UIViewController, UITableViewDelegate, UITableViewDataSource, ScrollableContainer, BannerPresenting, AccessibleView {

    let tableView = UITableView()

    func configureNavigationBar() {
        Self.configureNavigationBar(self)
    }

    // new code

    let viewModel: ViewModel
    private var contentOffsetToPerserve: CGPoint = .zero

    init(viewModel: ViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addSubviews()
        setUpLayout()

        Self.setup(self)

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

            NotificationCenter.default.addObserver(self, selector: #selector(restoreOffset), name: UIWindowScene.willEnterForegroundNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(saveOffset), name: UIWindowScene.didEnterBackgroundNotification, object: nil)
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
        embedChild(indexPath: indexPath, onto: cell)
        cell.clipsToBounds = true
        return cell
    }

    // --

    func scrollViewDidScroll(_ scrollView: UIScrollView) {}

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

    @objc internal func saveOffset() {
        self.contentOffsetToPerserve = self.tableView.contentOffset
    }

    @objc internal func restoreOffset() {
        self.tableView.setContentOffset(self.contentOffsetToPerserve, animated: false)
    }

    func embedChild(indexPath: IndexPath, onto cell: UITableViewCell) {
        fatalError("Missing implementation")
    }

    func embed(_ child: UIViewController,
               onto view: UIView,
               layoutGuide: UILayoutGuide? = nil,
               ownedBy controller: UIViewController) {
        assert(controller.isViewLoaded, "Attempt to embed child VC before parent's view was loaded - will cause glitches")

        // remove child from old parent
        if let parent = child.parent, parent != controller {
            child.willMove(toParent: nil)
            if child.isViewLoaded {
                child.view.removeFromSuperview()
            }
            child.removeFromParent()
        }

        // add child to new parent
        controller.addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        if view.subviews.isEmpty {
            view.addSubview(child.view)
        } else if let existedView = view.subviews.first {
            if existedView != child.view {
                existedView.removeFromSuperview()
                view.addSubview(child.view)
            }
        }

        child.didMove(toParent: controller)

        // autolayout guides priority: parameter, safeArea, no guide
        if let specialLayoutGuide = layoutGuide {
            specialLayoutGuide.topAnchor.constraint(equalTo: child.view.topAnchor).isActive = true
            specialLayoutGuide.bottomAnchor.constraint(equalTo: child.view.bottomAnchor).isActive = true
            specialLayoutGuide.leadingAnchor.constraint(equalTo: child.view.leadingAnchor).isActive = true
            specialLayoutGuide.trailingAnchor.constraint(equalTo: child.view.trailingAnchor).isActive = true
        } else {
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: child.view.topAnchor).isActive = true
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: child.view.bottomAnchor).isActive = true
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: child.view.leadingAnchor).isActive = true
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: child.view.trailingAnchor).isActive = true
        }
    }
}
