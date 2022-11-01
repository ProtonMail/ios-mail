//
//  PaymentsUIViewController.swift
//  ProtonCore_PaymentsUI - Created on 01/06/2021.
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

import UIKit
import ProtonCore_CoreTranslation
import ProtonCore_CoreTranslation_V5
import ProtonCore_Foundations
import ProtonCore_UIFoundations

protocol PaymentsUIViewControllerDelegate: AnyObject {
    func userDidCloseViewController()
    func userDidDismissViewController()
    func userDidSelectPlan(plan: PlanPresentation, addCredits: Bool, completionHandler: @escaping () -> Void)
    func planPurchaseError()
}

public final class PaymentsUIViewController: UIViewController, AccessibleView {
    
    // MARK: - Constants
    
    private let sectionHeaderView = "PlanSectionHeaderView"
    private let sectionHeaderHeight: CGFloat = 91.0
    
    // MARK: - Outlets
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableHeaderTitleLabel: UILabel! {
        didSet {
            tableHeaderTitleLabel.textColor = ColorProvider.TextNorm
        }
    }
    @IBOutlet weak var tableHeaderDescriptionLabel: UILabel! {
        didSet {
            tableHeaderDescriptionLabel.textColor = ColorProvider.TextWeak
        }
    }
    @IBOutlet var tableHeaderImageViews: [UIImageView]!
    @IBOutlet weak var tableFooterTextLabel: UILabel! {
        didSet {
            tableFooterTextLabel.textColor = ColorProvider.TextWeak
        }
    }
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
            tableView.register(PlanCell.nib, forCellReuseIdentifier: PlanCell.reuseIdentifier)
            tableView.register(CurrentPlanCell.nib, forCellReuseIdentifier: CurrentPlanCell.reuseIdentifier)
            tableView.separatorStyle = .none
            if #unavailable(iOS 13.0) {
                tableView.estimatedRowHeight = 600
            }
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedSectionHeaderHeight = sectionHeaderHeight
        }
    }
    @IBOutlet weak var infoIcon: UIImageView! {
        didSet {
            infoIcon.image = IconProvider.infoCircle
            infoIcon.tintColor = ColorProvider.IconWeak
        }
    }
    @IBOutlet weak var buttonStackView: UIStackView! {
        didSet {
            buttonStackView.isAccessibilityElement = true
        }
    }
    @IBOutlet weak var spacerView: UIView! {
        didSet {
            spacerView.isHidden = true
        }
    }
    @IBOutlet weak var extendSubscriptionButton: ProtonButton! {
        didSet {
            extendSubscriptionButton.isHidden = true
            extendSubscriptionButton.isAccessibilityElement = true
            extendSubscriptionButton.setMode(mode: .solid)
            extendSubscriptionButton.setTitle(CoreString_V5._new_plans_extend_subscription_button, for: .normal)
        }
    }
    
    // MARK: - Properties
    
    weak var delegate: PaymentsUIViewControllerDelegate?
    var model: PaymentsUIViewModel?
    var mode: PaymentsUIMode = .signup
    var modalPresentation = false
    var hideFooter = false
    private let planConnectionErrorView = PlanConnectionErrorView()

    private let navigationBarAdjuster = NavigationBarAdjustingScrollViewDelegate()
    
    override public var preferredStatusBarStyle: UIStatusBarStyle { darkModeAwarePreferredStatusBarStyle() }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        if #unavailable(iOS 13.0) {
            if Brand.currentBrand == .vpn {
                tableView.indicatorStyle = .white
            }
        }
        view.backgroundColor = ColorProvider.BackgroundNorm
        tableView.backgroundColor = ColorProvider.BackgroundNorm
        tableView.tableHeaderView?.backgroundColor = ColorProvider.BackgroundNorm
        tableView.tableFooterView?.backgroundColor = ColorProvider.BackgroundNorm
        tableView.tableHeaderView?.isHidden = true
        tableView.tableFooterView?.isHidden = true
        let nib = UINib(nibName: sectionHeaderView, bundle: PaymentsUI.bundle)
        tableView.register(nib, forHeaderFooterViewReuseIdentifier: sectionHeaderView)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        if mode != .signup {
            tableView.contentInset = UIEdgeInsets(top: -35, left: 0, bottom: 0, right: 0)
        }
        navigationItem.title = ""
        if modalPresentation {
            setUpCloseButton(showCloseButton: true, action: #selector(PaymentsUIViewController.onCloseButtonTap(_:)))
        } else {
            setUpBackArrow(action: #selector(PaymentsUIViewController.onCloseButtonTap(_:)))
        }

        if isDataLoaded {
            reloadUI()
        }
        generateAccessibilityIdentifiers()
        navigationItem.assignNavItemIndentifiers()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(PaymentsUIViewController.informAboutIAPInProgress),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    var banner: PMBanner?
    
    @objc private func informAboutIAPInProgress() {
        if model?.iapInProgress == true {
            let banner = PMBanner(message: CoreString._pu_iap_in_progress_banner,
                                  style: PMBannerNewStyle.error,
                                  dismissDuration: .infinity)
            showBanner(banner: banner, position: .top)
            self.banner = banner
        } else {
            self.banner?.dismiss(animated: true)
        }
        
    }

    override public func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        navigationBarAdjuster.setUp(for: tableView, parent: parent)
        tableView.delegate = self
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.userDidDismissViewController()
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderFooterViewHeight()
    }
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        showExpandButton()
    }
    
    @IBAction func onExtendSubscriptionButtonTap(_ sender: ProtonButton) {
        extendSubscriptionButton.isSelected = true
        guard case .withExtendSubscriptionButton(let plan) = model?.footerType else {
            extendSubscriptionButton.isSelected = false
            return
        }
        lockUI()
        delegate?.userDidSelectPlan(plan: plan, addCredits: true) { [weak self] in
            self?.unlockUI()
            self?.extendSubscriptionButton.isSelected = false
        }
    }
    
    // MARK: - Internal methods
    
    func reloadData() {
        isData = true
        if isViewLoaded {
            tableView.reloadData()
            reloadUI()
        }
    }

    func showPurchaseSuccessBanner() {
        let banner = PMBanner(message: CoreString_V5._new_plans_plan_successfully_upgraded,
                              style: PMBannerNewStyle.info,
                              dismissDuration: 4.0)
        showBanner(banner: banner, position: .top)
    }
    
    func extendSubscriptionSelection() {
        extendSubscriptionButton.isSelected = true
        extendSubscriptionButton.isUserInteractionEnabled = false
    }

    func showBanner(banner: PMBanner, position: PMBannerPosition) {
        if !activityIndicator.isHidden {
            activityIndicator.isHidden = true
        }
        PMBanner.dismissAll(on: self)
        banner.show(at: position, on: self)
    }
    
    func showOverlayConnectionError() {
        guard !view.subviews.contains(planConnectionErrorView) else { return }
        planConnectionErrorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(planConnectionErrorView)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: planConnectionErrorView.topAnchor),
            view.bottomAnchor.constraint(equalTo: planConnectionErrorView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: planConnectionErrorView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: planConnectionErrorView.trailingAnchor)
        ])
    }
    
    public func planPurchaseError() {
        delegate?.planPurchaseError()
    }

    // MARK: - Actions

    @objc func onCloseButtonTap(_ sender: UIButton) {
        delegate?.userDidCloseViewController()
    }
    
    // MARK: Private interface
    
    private func updateHeaderFooterViewHeight() {
        guard isDataLoaded, let headerView = tableView.tableFooterView, let footerView = tableView.tableFooterView else {
            return
        }
        if mode != .signup {
            tableView.tableHeaderView = nil
        } else {
            tableView.tableHeaderView?.isHidden = false
        }
        tableView.tableFooterView?.isHidden = hideFooter
        
        let width = tableView.bounds.size.width
        let headerSize = headerView.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height))
        if headerView.frame.size.height != headerSize.height {
            headerView.frame.size.height = headerSize.height
            tableView.tableFooterView = headerView
        }

        let footerSize = footerView.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height))
        if footerView.frame.size.height != footerSize.height {
            footerView.frame.size.height = footerSize.height
            tableView.tableFooterView = footerView
        }
    }

    private func reloadUI() {
        guard isDataLoaded else { return }
        var hasExtendSubscriptionButton = false
        switch model?.footerType {
        case .withPlansToBuy:
            tableFooterTextLabel.text = CoreString_V5._new_plans_plan_footer_desc
        case .withoutPlansToBuy:
            tableFooterTextLabel.text = CoreString._pu_plan_footer_desc_purchased
        case .withExtendSubscriptionButton:
            tableFooterTextLabel.text = CoreString._pu_plan_footer_desc_purchased
            hasExtendSubscriptionButton = true
        case .none:
            tableFooterTextLabel.text = CoreString._pu_plan_footer_desc_purchased
        case .disabled:
            hideFooter = true
        }
        spacerView.isHidden = !hasExtendSubscriptionButton
        extendSubscriptionButton.isHidden = !hasExtendSubscriptionButton
        activityIndicator.isHidden = true
        updateHeaderFooterViewHeight()
        if mode == .signup {
            tableHeaderTitleLabel.text = CoreString._pu_select_plan_title
            tableHeaderDescriptionLabel.text = CoreString_V5._new_plans_select_plan_description
            navigationItem.title = ""
            setupHeaderView()
        } else {
            if modalPresentation {
                switch mode {
                case .current:
                    navigationItem.title = CoreString._pu_subscription_title
                    updateTitleAttributes()
                case .update:
                    switch model?.footerType {
                    case .withPlansToBuy:
                        navigationItem.title = CoreString._pu_upgrade_plan_title
                    case .withoutPlansToBuy, .withExtendSubscriptionButton, .disabled, .none:
                        navigationItem.title = CoreString._pu_current_plan_title
                    }
                    updateTitleAttributes()
                default:
                    break
                }
            } else {
                navigationItem.setHidesBackButton(true, animated: false)
                navigationItem.title = ""
            }
        }
        navigationItem.assignNavItemIndentifiers()
    }
    
    private var isData = false
    
    private var isDataLoaded: Bool {
        return isData || mode == .signup
    }
    
    private func setupHeaderView() {
        let appIcons: [UIImage] = [
            IconProvider.mailMainTransparent,
            IconProvider.calendarMainTransparent,
            IconProvider.driveMainTransparent,
            IconProvider.vpnMainTransparent
        ]
        for (index, element) in tableHeaderImageViews.enumerated() {
            element.image = appIcons[index]
        }
    }
    
    private func showExpandButton() {
        guard let model = model else { return }
        for section in model.plans.indices {
            guard model.plans.indices.contains(section) else { continue }
            for row in model.plans[section].indices {
                let indexPath = IndexPath(row: row, section: section)
                if let cell = tableView.cellForRow(at: indexPath) as? PlanCell, model.shouldShowExpandButton {
                    cell.showExpandButton()
                }
            }
        }
    }
}

extension PaymentsUIViewController: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return model?.plans.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model?.plans[safeIndex: section]?.count ?? 0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        guard let plan = model?.plans[safeIndex: indexPath.section]?[safeIndex: indexPath.row] else { return cell }
        switch plan.planPresentationType {
        case .plan:
            cell = tableView.dequeueReusableCell(withIdentifier: PlanCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? PlanCell {
                cell.delegate = self
                cell.configurePlan(plan: plan, indexPath: indexPath, isSignup: mode == .signup, isExpandButtonHidden: model?.isExpandButtonHidden ?? true)
            }
            cell.selectionStyle = .none
        case .current:
            cell = tableView.dequeueReusableCell(withIdentifier: CurrentPlanCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? CurrentPlanCell {
                cell.configurePlan(plan: plan)
            }
            cell.isUserInteractionEnabled = false
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard mode == .current && section == 1 else { return nil }
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: sectionHeaderView)
        if let header = view as? PlanSectionHeaderView {
            header.titleLabel.text = CoreString._pu_upgrade_plan_title
        }
        return view
    }
}

extension PaymentsUIViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard mode == .current && section == 1 else { return 0 }
        return UITableView.automaticDimension
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let plan = model?.plans[safeIndex: indexPath.section]?[safeIndex: indexPath.row] else { return }
        if case .plan = plan.planPresentationType {
            if let cell = tableView.cellForRow(at: indexPath) as? PlanCell {
                cell.selectCell()
            }
        }
    }
}

extension PaymentsUIViewController: PlanCellDelegate {
    func cellDidChange(indexPath: IndexPath) {
        tableView.beginUpdates()
        tableView.endUpdates()
        tableView.scrollToRow(at: indexPath, at: .none, animated: true)
    }
    
    func userPressedSelectPlanButton(plan: PlanPresentation, completionHandler: @escaping () -> Void) {
        lockUI()
        delegate?.userDidSelectPlan(plan: plan, addCredits: false) { [weak self] in
            self?.unlockUI()
            completionHandler()
        }
    }
}
