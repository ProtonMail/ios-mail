//
//  PMActionSheet.swift
//  ProtonCore-UIFoundations - Created on 20.07.20.
//
//  Copyright (c) 2020 Proton Technologies AG
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

import UIKit

public protocol PMActionSheetEventsListener: AnyObject {
    func willPresent()
    func willDismiss()
    func didDismiss()
}

protocol PMActionSheetProtocol: AnyObject {
    var itemGroups: [PMActionSheetItemGroup]? { get }

    func reloadRows(at indexPaths: [IndexPath])
    func reloadSection(_ section: Int)
    func dismiss(animated: Bool)
}

public final class PMActionSheet: UIView {

    // MARK: Variables
    private var tableView: UITableView!
    private var containerView: UIView?
    private var containerViewBottom: NSLayoutConstraint?
    private var headerView: PMActionSheetHeaderView?
    private var dragView: PMActionSheetDragBarView?
    private var viewModel: PMActionSheetVMProtocol!
    private var showDragBar: Bool = true
    private var enableBGTap: Bool = true
    // Is dissmiss function called before?
    private var hasDismissed: Bool = false
    /// Initialized center of contaienr
    private var initCenter: CGPoint = .zero
    /// Initialized center of drag view
    private var dragViewCenter: CGPoint = .zero
    private let MAXIMUM_SHEET_WIDTH: CGFloat = 414
    public weak var eventsListener: PMActionSheetEventsListener?
    public var itemGroups: [PMActionSheetItemGroup]? {
        return self.viewModel?.itemGroups
    }

    /// Initializer of action sheet
    /// - Parameters:
    ///   - headerView: Header view of action sheet
    ///   - itemGroups: Action item groups of action sheet
    ///   - showDragBar: Set `true` to enable drag down to dismiss action sheet and show drag bar
    ///   - enableBGTap: Set `true` to enable tap background to dismiss action sheet
    public convenience init(headerView: PMActionSheetHeaderView?,
                            itemGroups: [PMActionSheetItemGroup],
                            showDragBar: Bool = true,
                            enableBGTap: Bool = true) {
        self.init(frame: .zero)
        self.headerView = headerView
        self.showDragBar = showDragBar
        self.enableBGTap = enableBGTap
        self.viewModel = PMActionSheetVM(actionsheet: self, itemGroups: itemGroups)
        self.setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        showDragBar ? setDragBarRoundedCorners() : setHeaderRoundedCorners()
    }
}

extension PMActionSheet: PMActionSheetProtocol {
    func reloadRows(at indexPaths: [IndexPath]) {
        self.tableView.beginUpdates()
        self.tableView.reloadRows(at: indexPaths, with: .automatic)
        self.tableView.endUpdates()
    }

    func reloadSection(_ section: Int) {
        self.tableView.beginUpdates()
        self.tableView.reloadSections(.init(integer: section), with: .automatic)
        self.tableView.endUpdates()
    }
}

// MARK: Public function
extension PMActionSheet {
    public func presentAt(_ parentVC: UIViewController, hasTopConstant: Bool = true, animated: Bool) {
        eventsListener?.willPresent()
        guard let parent = parentVC.view else { return }
        parent.addSubview(self)
        let topConstant = hasTopConstant ? parent.safeGuide.top : 0
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: parent.topAnchor, constant: topConstant),
            self.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            self.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
            self.trailingAnchor.constraint(equalTo: parent.trailingAnchor)
        ])
        parent.layoutIfNeeded()
        self.setupTableBottomConstraint()
        guard let bottom = self.containerViewBottom else {
            return
        }

        guard animated else {
            bottom.constant = 0
            return
        }

        let duration = self.viewModel.value.DURATION
        UIView.animate(withDuration: duration, animations: {
            bottom.constant = 0
            self.layoutIfNeeded()
        })
    }

    public func dismiss(animated: Bool) {
        guard self.hasDismissed == false else { return }
        self.hasDismissed = true
        eventsListener?.willDismiss()
        guard let bottom = self.containerViewBottom else {
            self.removeFromSuperview()
            return
        }
        let height = self.containerView?.frame.size.height ?? 200
        let duration = self.viewModel.value.DURATION
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0
            bottom.constant = height
            self.layoutIfNeeded()
        }, completion: { (_) in
            self.removeFromSuperview()
            self.eventsListener?.didDismiss()
        })
    }
}

// MARK: Private functions
extension PMActionSheet {
    @objc private func tapBackground(ges: UIGestureRecognizer) {
        self.dismiss(animated: true)
    }

    @objc private func panSheet(ges: UIPanGestureRecognizer) {
        let state = ges.state
        switch state {
        case .began:
            guard let containerView = self.containerView,
                  let dragView = self.dragView else { return }
            self.initCenter = containerView.center
            self.dragViewCenter = dragView.center
        case .changed:
            guard let containerView = self.containerView,
                  let dragView = self.dragView else { return }
            let translation = ges.translation(in: containerView)
            let center = containerView.center
            var newY = center.y + translation.y
            var dragY = dragView.center.y + translation.y
            if newY <= self.initCenter.y {
                newY = self.initCenter.y
                dragY = self.dragViewCenter.y
            }

            containerView.center = CGPoint(x: center.x, y: newY)
            dragView.center = CGPoint(x: dragView.center.x, y: dragY)
            ges.setTranslation(.zero, in: containerView)
        case .ended:
            let velocity = ges.velocity(in: self.containerView)
            if velocity.y > 100 {
                // positive number means drag down
                self.dismiss(animated: true)
            } else {
                self.resetCenter()
            }
        default: break
        }
    }
}

// MARK: UI Relative
extension PMActionSheet {
    private func setup() {
        guard self.viewModel.itemGroups != nil else { return }
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = Blenders._P48
        self.setupDismissGesture()

        let container = self.createContainer()
        let table = self.createTable()
        if let _headerView = self.headerView {
            self.addTableView(table, in: container, hasHeader: true)
            self.addHeaderView(_headerView, in: container)
        } else {
            self.addTableView(table, in: container, hasHeader: false)
        }
        self.addDragView(onTopOf: container)
        self.setupPanGesture()
    }

    private func setupDismissGesture() {
        guard self.enableBGTap else { return }
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapBackground(ges:)))
        tap.delegate = self
        self.addGestureRecognizer(tap)
    }

    private func setupPanGesture() {
        // No drag bar, no pan gesture
        guard self.showDragBar else { return }
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.panSheet(ges:)))
        pan.delegate = self
        self.addGestureRecognizer(pan)

        // Only fired when content offset is 0 or the normal scroll event works
        let pan2 = UIPanGestureRecognizer(target: self, action: #selector(self.panSheet(ges:)))
        pan2.delegate = self
        self.tableView.addGestureRecognizer(pan2)
    }

    private func createContainer() -> UIView {
        self.containerView = nil
        let container = UIView()
        container.backgroundColor = BackgroundColors._Main
        container.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(container)

        let leftConstraint = container.leadingAnchor.constraint(equalTo: self.leadingAnchor)
        leftConstraint.priority = UILayoutPriority(rawValue: 999)
        leftConstraint.isActive = true
        let rightConstraint = container.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        rightConstraint.priority = UILayoutPriority(rawValue: 999)
        rightConstraint.isActive = true
        container.widthAnchor.constraint(lessThanOrEqualToConstant: self.MAXIMUM_SHEET_WIDTH).isActive = true
        container.centerXInSuperview()

        let height = self.viewModel.calcTableViewHeight()
        self.containerViewBottom = container.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: height)
        self.containerViewBottom!.isActive = true
        self.containerView = container
        return container
    }

    private func createTable() -> UITableView {
        let table = UITableView()
        table.delegate = self
        table.dataSource = self
        table.separatorStyle = .none
        table.translatesAutoresizingMaskIntoConstraints = false
        table.tableFooterView = UIView(frame: .zero)
        table.register(PMActionSheetPlainCell.nib(), forCellReuseIdentifier: self.viewModel.value.PLAIN_CELL_NAME)
        table.register(PMActionSheetToggleCell.self, forCellReuseIdentifier: self.viewModel.value.TOGGLE_CELL_NAME)
        table.register(PMActionSheetGridCell.self, forCellReuseIdentifier: self.viewModel.value.GRID_CELL_NAME)
        table.register(cellType: PMActionSheetPlainCellHeader.self)

        self.tableView = table
        return table
    }

    private func addHeaderView(_ header: PMActionSheetHeaderView, in container: UIView) {
        container.addSubview(header)
        header.translatesAutoresizingMaskIntoConstraints = false
        header.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        header.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        header.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        header.bottomAnchor.constraint(equalTo: self.tableView.topAnchor).isActive = true
        header.heightAnchor.constraint(equalToConstant: self.viewModel.value.HEADER_HEIGHT).isActive = true
    }

    private func addTableView(_ table: UITableView, in container: UIView, hasHeader: Bool) {

        container.addSubview(table)
        table.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        table.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true

        // Maximum height of tableview
        table.heightAnchor.constraint(lessThanOrEqualTo: self.heightAnchor, multiplier: 0.9, constant: -1 * self.viewModel.value.HEADER_HEIGHT).isActive = true

        // Real height of tableview
        let height = self.viewModel.calcTableViewHeight()
        let heightAnchor = table.heightAnchor.constraint(equalToConstant: height)
        heightAnchor.priority = UILayoutPriority(rawValue: 999)
        heightAnchor.isActive = true
    }

    private func addDragView(onTopOf container: UIView) {
        guard self.showDragBar else { return }
        let dragView = PMActionSheetDragBarView(frame: .zero)
        self.dragView = dragView
        dragView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(dragView)
        NSLayoutConstraint.activate([
            dragView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            dragView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            dragView.bottomAnchor.constraint(equalTo: container.topAnchor),
            dragView.heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    private func setupTableBottomConstraint() {
        guard let container = self.containerView else { return }

        guard self.headerView != nil else {
            // Tableview bottom constraint when headerview missing
            self.tableView.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
            let padding = UIDevice.hasPhysicalHome ? 0: self.viewModel.value.BOTTOM_PADDING
            self.tableView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -1 * padding).isActive = true
            // Actionsheet without header shouldn't have bounces
            self.tableView.bounces = false
            return
        }

        // Tableview bottom constraint when headerview exist.
        let maxHeight = self.frame.size.height * 0.9 - self.viewModel.value.HEADER_HEIGHT
        let tableHeight = self.viewModel.calcTableViewHeight()
        let padding = UIDevice.hasPhysicalHome ? 0: self.viewModel.value.PLAIN_CELL_HEIGHT
        if maxHeight > tableHeight {
            self.tableView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -1 * padding).isActive = true
            self.tableView.bounces = false
        } else {
            self.tableView.contentInset.bottom = padding
            self.tableView.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
        }
    }

    /// Set top right and top left corner round
    private func setHeaderRoundedCorners() {
        guard let containerView = self.containerView else { return }
        setTopRoundedCorners(for: containerView)
    }

    private func setDragBarRoundedCorners() {
        guard let dragView = dragView else { return }
        setTopRoundedCorners(for: dragView)
    }

    private func setTopRoundedCorners(for view: UIView) {
        let radius = self.viewModel.value.RADIUS
        let size = CGSize(width: radius, height: radius)
        let path = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: size)
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        view.layer.mask = maskLayer
    }

    /// Reset position of container view and drag bar after pan gesture finish
    private func resetCenter() {
        UIView.animate(withDuration: 0.25) {
            guard let containerView = self.containerView,
                  let dragView = self.dragView else { return }
            containerView.center = self.initCenter
            dragView.center = self.dragViewCenter
        } completion: { (_) in
            self.initCenter = .zero
            self.dragViewCenter = .zero
        }

    }
}

// MARK: TableView
extension PMActionSheet: UITableViewDelegate, UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int {
        guard let groups = self.viewModel.itemGroups else {
            return 0
        }
        return groups.count
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let groups = self.viewModel.itemGroups,
              groups[section].title != nil else { return 0 }
        return viewModel.value.SECTION_HEADER_HEIGHT
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let groups = self.viewModel.itemGroups,
              let title = groups[section].title else { return nil }
        let sectionHeader: PMActionSheetPlainCellHeader = tableView.dequeueReusableCell()
        sectionHeader.config(title: title)
        return sectionHeader
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let groups = self.viewModel.itemGroups else {
            return 0
        }

        let group = groups[section]
        switch group.style {
        case .clickable, .singleSelection, .multiSelection, .toggle:
            return group.items.count
        case .grid:
            return 1
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let groups = self.viewModel.itemGroups else {
            return 0
        }

        let group = groups[indexPath.section]
        switch group.style {
        case .clickable, .singleSelection, .multiSelection:
            return self.viewModel.value.PLAIN_CELL_HEIGHT
        case .toggle:
            return self.viewModel.value.TOGGLE_CELL_HEIGHT
        case .grid:
            let section = indexPath.section
            return self.viewModel.calcGridCellHeightAt(section)
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let groups = self.viewModel.itemGroups else {
            fatalError(PMActionSheetError.itemGroupMissing.localizedDescription)
        }
        let group = groups[indexPath.section]
        switch group.style {
        case .clickable, .singleSelection, .multiSelection:
            return self.configPlainCellBy(group, at: indexPath)
        case .toggle:
            return self.configToggleCellBy(group, at: indexPath)
        case .grid:
            return self.configGridCellBy(group, at: indexPath)
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.viewModel.selectRowAt(indexPath)
    }

    // MARK: Cell configuration
    private func configPlainCellBy(_ group: PMActionSheetItemGroup, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.viewModel.value.PLAIN_CELL_NAME) as! PMActionSheetPlainCell
        let item = group.items[indexPath.row] as! PMActionSheetPlainItem
        cell.config(item: item)
        return cell
    }

    private func configToggleCellBy(_ group: PMActionSheetItemGroup, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.viewModel.value.TOGGLE_CELL_NAME) as! PMActionSheetToggleCell
        let item = group.items[indexPath.row] as! PMActionSheetToggleItem
        cell.config(item: item, at: indexPath, delegate: self.viewModel as! PMActionSheetToggleDelegate)
        return cell
    }

    private func configGridCellBy(_ group: PMActionSheetItemGroup, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.viewModel.value.GRID_CELL_NAME) as! PMActionSheetGridCell
        try! cell.config(group: group, at: indexPath, delegate: self.viewModel as! PMActionSheetGridDelegate)
        return cell
    }
}

extension PMActionSheet: UIGestureRecognizerDelegate {
    override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let containerView = self.containerView else {
            return true
        }

        if gestureRecognizer is UITapGestureRecognizer {
            // Check user tap position is gray overlay or container view
            let point = gestureRecognizer.location(in: containerView)
            // tap gray overlay
            if point.y < 0 {
                return true
            }
        } else if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            return self.shouldFirePanGes(ges: pan)
        }

        return false
    }

    private func shouldFirePanGes(ges: UIPanGestureRecognizer) -> Bool {
        let point = ges.location(in: self.dragView)
        // pan on gray overlay
        if point.y < 0 {
            return false
        }

        let tablePoint = ges.location(in: self.tableView)
        if self.tableView.bounds.contains(tablePoint) {
            if self.tableView.contentOffset.y <= 0 {
                let v = ges.velocity(in: self.tableView)
                // If the offset is 0
                // gesture always works
                return v.y > 0 ? true: false
            }
            return false
        }

        // pan on drag view or header view
        return true
    }
}
