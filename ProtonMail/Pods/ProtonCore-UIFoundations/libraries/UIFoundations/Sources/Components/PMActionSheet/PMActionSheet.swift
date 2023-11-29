//
//  PMActionSheet.swift
//  ProtonCore-UIFoundations-iOS - Created on 2023/1/18.
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

private struct Constants {
    static let PLAIN_CELL_NAME = "PMActionSheetPlainCell"
    static let GRID_CELL_NAME = "PMActionSheetGridCell"
    static let ANIMATION_DURATION: CGFloat = 0.25
}

public protocol PMActionSheetEventsListener: AnyObject {
    func willPresent()
    func willDismiss()
    func didDismiss()
}

protocol PMActionSheetProtocolV2: AnyObject {
    func reloadRows(at indexPaths: [IndexPath])
    func reloadSection(_ section: Int)
    func dismiss(animated: Bool)
}

public final class PMActionSheet: UIView, PMActionSheetProtocolV2, AccessibleView {
    public weak var eventsListener: PMActionSheetEventsListener?
    private var headerView: PMActionSheetHeaderView?
    private var tableView = UITableView(frame: .zero)
    private var container = UIView(frame: .zero)
    private var bottomCover = UIView(frame: .zero)
    private var enableBGTap: Bool = true
    private var hasDismissed: Bool = false
    private var viewModel: PMActionSheetVM!
    private var displayState: SheetDisplayState = .initialized
    private var initDisplayState: SheetDisplayState = .initialized

    private var containerViewBottom: NSLayoutConstraint?
    private var bottomCoverHeight: NSLayoutConstraint?
    private var tableViewHeight: NSLayoutConstraint?
    private var initContainerViewBottomConstant: CGFloat?
    private var handleTablePanGesture = false

    public var itemGroups: [PMActionSheetItemGroup] { viewModel.itemGroups }

    public convenience init(
        headerView: PMActionSheetHeaderView?,
        itemGroups: [PMActionSheetItemGroup],
        enableBGTap: Bool = true,
        delegate: PMActionSheetEventsListener? = nil
    ) {
        self.init(frame: .zero)
        self.viewModel = PMActionSheetVM(actionSheet: self, itemGroups: itemGroups)
        self.headerView = headerView
        self.enableBGTap = enableBGTap
        self.eventsListener = delegate
        setUp()
        generateAccessibilityIdentifiers()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(iOS, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        setRoundedCorners()
    }
}

extension PMActionSheet {
    public func presentAt(_ parentVC: UIViewController, hasTopConstant: Bool = true, animated: Bool) {
        eventsListener?.willPresent()
        guard let parent = parentVC.view else { return }
        parent.addSubview(self)
        let topConstant = hasTopConstant ? parent.safeGuide.top : 0
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: parent.topAnchor, constant: topConstant),
            leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            bottomAnchor.constraint(equalTo: parent.bottomAnchor),
            trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            container.widthAnchor.constraint(equalTo: parent.widthAnchor).prioritised(as: .defaultLow)
        ])
        parent.layoutIfNeeded()
        setUpBottomConstraintTo(displayState: .initialized, animated: animated)
    }

    public func dismiss(animated: Bool) {
        guard self.hasDismissed == false else { return }
        hasDismissed = true
        eventsListener?.willDismiss()
        guard let bottom = containerViewBottom else {
            self.removeFromSuperview()
            return
        }
        let height = container.frame.size.height
        let duration = Constants.ANIMATION_DURATION
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0
            bottom.constant = height
            self.layoutIfNeeded()
        }, completion: { (_) in
            self.removeFromSuperview()
            self.eventsListener?.didDismiss()
        })
    }

    func reloadRows(at indexPaths: [IndexPath]) {
        self.tableView.beginUpdates()
        self.tableView.reloadRows(at: indexPaths, with: .none)
        self.tableView.endUpdates()
    }

    public func reloadSection(_ section: Int) {
        self.tableView.beginUpdates()
        self.tableView.reloadSections(.init(integer: section), with: .none)
        self.tableView.endUpdates()
    }
}

// MARK: - Action sheet initialize
extension PMActionSheet {
    private func setUp() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ColorProvider.BlenderNorm
        setUpContainerConstraint()
        setUpHeaderViewConstraint()
        setUpBottomCover()
        initializeTableView()
        setUpTableViewConstraint()
        setUpGestures()
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(preferredContentSizeChanged),
                         name: UIContentSizeCategory.didChangeNotification,
                         object: nil)
    }

    private func setUpGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.pan(gesture:)))
        container.addGestureRecognizer(pan)

        tableView.panGestureRecognizer.addTarget(self, action: #selector(self.tablePan(gesture:)))

        guard enableBGTap else { return }
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapBackground(gesture:)))
        tap.delegate = self
        tap.delaysTouchesBegan = false
        tap.delaysTouchesEnded = false
        tap.cancelsTouchesInView = false
        tap.require(toFail: pan)
        addGestureRecognizer(tap)
    }

    private func setUpContainerConstraint() {
        container.backgroundColor = PMActionSheetConfig.shared.actionSheetBackgroundColor
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)

        let config = PMActionSheetConfig.shared
        let maximumWidth = config.actionSheetMaximumWidth
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            container.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            container.widthAnchor.constraint(lessThanOrEqualToConstant: maximumWidth),
            container.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])

        let tableHeight = viewModel.calcTableViewHeight()
        let headerHeight: CGFloat
        if headerView == nil {
            headerHeight = 0
        } else {
            headerHeight = headerView?.frame.height ?? config.headerViewHeight
        }
        containerViewBottom = container.bottomAnchor.constraint(
            equalTo: safeAreaLayoutGuide.bottomAnchor,
            constant: headerHeight + tableHeight
        ).prioritised(as: .defaultLow)
        containerViewBottom?.isActive = true
    }

    private func setUpHeaderViewConstraint() {
        guard let headerView = headerView else { return }
        container.addSubview(headerView)
        let height = PMActionSheetConfig.shared.headerViewHeight
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: container.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            headerView.heightAnchor.constraint(greaterThanOrEqualToConstant: height)
        ])
        headerView.layoutIfNeeded()
    }

    private func setUpBottomCover() {
        bottomCover.translatesAutoresizingMaskIntoConstraints = false
        bottomCover.backgroundColor = PMActionSheetConfig.shared.actionSheetBackgroundColor
        addSubview(bottomCover)

        NSLayoutConstraint.activate([
            bottomCover.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomCover.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomCover.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        bottomCoverHeight = bottomCover.heightAnchor.constraint(equalToConstant: 0)
        bottomCoverHeight?.isActive = true
    }

    private func initializeTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = PMActionSheetConfig.shared.actionSheetBackgroundColor
        tableView.bounces = false
        tableView.automaticallyAdjustsScrollIndicatorInsets = false

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.register(PMActionSheetPlainCell.self, forCellReuseIdentifier: Constants.PLAIN_CELL_NAME)
        tableView.register(PMActionSheetCollectionCell.self, forCellReuseIdentifier: Constants.GRID_CELL_NAME)
        tableView.register(cellType: PMActionSheetCellHeader.self)
        tableView.tableFooterView = UIView(frame: .zero)
    }

    private func setUpTableViewConstraint() {
        container.addSubview(tableView)
        let topRef = headerView?.bottomAnchor ?? container.topAnchor

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: topRef),
            tableView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        let config = PMActionSheetConfig.shared
        let height = viewModel.value.tableViewHeight
        switch config.panStyle {
        case .v1:
            let constant = headerView?.frame.height ?? 0
            tableView.heightAnchor.constraint(
                lessThanOrEqualTo: heightAnchor,
                multiplier: config.actionSheetMaximumInitializeOccupy,
                constant: -1 * constant
            ).isActive = true
            tableViewHeight = tableView.heightAnchor.constraint(equalToConstant: height).prioritised(as: .init(999))
        case .v2:
            tableViewHeight = tableView.heightAnchor.constraint(equalToConstant: height)
        }
        tableViewHeight?.isActive = true
    }

    private func setRoundedCorners() {
        let radius = PMActionSheetConfig.shared.actionSheetRadius
        let size = CGSize(width: radius, height: radius)
        let path = UIBezierPath(roundedRect: container.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: size)
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        container.layer.mask = maskLayer
    }

    @objc
    private func preferredContentSizeChanged() {
        let height = viewModel.calcTableViewHeight(forceUpdate: true)
        tableViewHeight?.constant = height
    }
}

// MARK: - Actions
extension PMActionSheet {
    @objc
    private func tapBackground(gesture: UITapGestureRecognizer) {
        dismiss(animated: true)
    }

    @objc
    private func pan(gesture: UIPanGestureRecognizer) {
        guard let bottomConstant = containerViewBottom?.constant else { return }
        switch gesture.state {
        case .began:
            initContainerViewBottomConstant = bottomConstant
            initDisplayState = displayState
        case .changed:
            // translation.y < 0 means drag to top
            let translation = gesture.translation(in: container)
            setUpBottomConstraintTo(displayState: .pan(translation.y), animated: false)
        case .ended:
            let velocity = gesture.velocity(in: container)
            if velocity.y > 100 {
                // velocity.y > 0, drag to bottom.
                dismiss(animated: true)
            } else if velocity.y < -100 {
                setUpBottomConstraintTo(displayState: .expanded, animated: false)
            } else {
                guard let oldValue = initContainerViewBottomConstant,
                      let currentValue = containerViewBottom?.constant else { return }
                let diff = currentValue - oldValue
                if diff <= -20 {
                    // Drag to top
                    setUpBottomConstraintTo(displayState: .expanded, animated: true)
                } else if diff >= 100 {
                    dismiss(animated: true)
                } else {
                    setUpBottomConstraintTo(displayState: initDisplayState, animated: true)
                }
            }
        default:
            break
        }
    }

    @objc
    private func tablePan(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            handleTablePanGesture = false
            // velocity.y > 0, drag to bottom
            let velocity = gesture.velocity(in: container)
            guard
                tableView.contentOffset.y <= 0,
                velocity.y >= 0
            else { return }
            handleTablePanGesture = true
            pan(gesture: gesture)
        default:
            guard handleTablePanGesture else { return }
            pan(gesture: gesture)
        }
    }
}

// MARK: - Private functions
extension PMActionSheet {
    private func setUpBottomConstraint(to constraint: CGFloat, animated: Bool) {
        guard animated else {
            containerViewBottom?.constant = constraint
            bottomCoverHeight?.constant = superview?.safeGuide.bottom ?? 0
            return
        }
        let duration = Constants.ANIMATION_DURATION
        UIView.animate(withDuration: duration, animations: {
            self.containerViewBottom?.constant = constraint
            self.bottomCoverHeight?.constant = self.superview?.safeGuide.bottom ?? 0
            self.layoutIfNeeded()
        })
    }

    private func setUpBottomConstraintTo(displayState: SheetDisplayState, animated: Bool) {
        self.displayState = displayState
        let viewHeight = frame.height - safeGuide.bottom
        let sheetHeight = container.frame.height
        if PMActionSheetConfig.shared.panStyle == .v2 {
            tableView.isScrollEnabled = false
        }
        switch displayState {
        case .expanded:
            guard PMActionSheetConfig.shared.panStyle == .v2 else { return }
            let constraint = max(sheetHeight - viewHeight, 0)
            setUpBottomConstraint(to: constraint, animated: animated)
            tableView.isScrollEnabled = true
            tableView.contentInset = .init(top: 0, left: 0, bottom: constraint - safeGuide.bottom, right: 0)
        case .initialized:
            let maximumOccupy = PMActionSheetConfig.shared.actionSheetMaximumInitializeOccupy
            let initializedMaximum = viewHeight * maximumOccupy
            let diff = initializedMaximum - sheetHeight
            let constraint = diff >= 0 ? 0 : abs(diff)
            setUpBottomConstraint(to: constraint, animated: animated)
        case .pan(let translationY):
            if PMActionSheetConfig.shared.panStyle == .v1 && translationY < 0 {
                // V1 can't drag to top
                return
            }
            guard let oldValue = initContainerViewBottomConstant else { return }
            let newConstraint = max(oldValue + translationY, 0)
            let maximumConstraint = max(sheetHeight - viewHeight, 0)
            let newValue = max(maximumConstraint, newConstraint)
            setUpBottomConstraint(to: newValue, animated: animated)
        }
    }

    enum SheetDisplayState {
        case expanded, initialized, pan(CGFloat)
    }
}

extension PMActionSheet: UITableViewDelegate, UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.itemGroups.count
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard viewModel.itemGroups[section].title != nil else { return 0 }
        if DFSSetting.enableDFS {
            return UITableView.automaticDimension
        } else {
            return PMActionSheetConfig.shared.sectionHeaderHeight
        }
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let group = viewModel.itemGroups[section]
        guard let title = group.title else { return nil }
        let sectionHeader: PMActionSheetCellHeader = tableView.dequeueReusableCell()
        sectionHeader.config(title: title, hasSeparator: group.hasSeparator)
        return sectionHeader
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let group = viewModel.itemGroups[section]
        switch group.style {
        case .clickable, .singleSelection, .multiSelection, .toggle, .singleSelectionNewStyle, .multiSelectionNewStyle:
            return group.items.count
        case .grid:
            return 1
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let group = viewModel.itemGroups[indexPath.section]
        switch group.style {
        case .clickable, .singleSelection, .multiSelection, .singleSelectionNewStyle, .multiSelectionNewStyle:
            return PMActionSheetConfig.shared.plainCellHeight
        case .toggle:
            return PMActionSheetConfig.shared.toggleCellHeight
        case .grid:
            return UITableView.automaticDimension
        }
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let group = viewModel.itemGroups[indexPath.section]
        switch group.style {
        case .clickable, .singleSelection, .multiSelection, .singleSelectionNewStyle, .multiSelectionNewStyle:
            return PMActionSheetConfig.shared.plainCellHeight
        case .toggle:
            return PMActionSheetConfig.shared.toggleCellHeight
        case .grid(let colInRows):
            let section = indexPath.section
            return viewModel.calcGridCellHeightAt(section, colInRow: colInRows)
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = viewModel.itemGroups[indexPath.section]
        switch group.style {
        case .clickable, .singleSelection, .multiSelection, .singleSelectionNewStyle, .multiSelectionNewStyle, .toggle:
            let cell: PMActionSheetPlainCell = tableView.dequeueReusableCell(
                withIdentifier: Constants.PLAIN_CELL_NAME,
                for: indexPath
            ) as! PMActionSheetPlainCell
            let item = group.items[indexPath.row]
            cell.config(
                item: item,
                at: indexPath,
                style: group.style,
                totalItemsCount: group.items.count,
                delegate: self
            )
            return cell
        case .grid(let colInRows):
            let cell = tableView.dequeueReusableCell(
                withIdentifier: Constants.GRID_CELL_NAME,
                for: indexPath
            ) as! PMActionSheetCollectionCell
            cell.config(items: group.items, colInRows: colInRows)
            return cell
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectRowAt(indexPath)
    }
}

extension PMActionSheet: PMActionSheetPlainCellDelegate {
    func toggleTriggeredAt(indexPath: IndexPath) {
        viewModel.triggerToggle(at: indexPath)
    }
}

// MARK: - UITapGesture
extension PMActionSheet: UIGestureRecognizerDelegate {
    override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer {
            // Check user tap position is gray overlay or container view
            let point = gestureRecognizer.location(in: container)
            // tap gray overlay
            if point.y < 0 {
                return true
            }
        }
        return false
    }
}

#endif
