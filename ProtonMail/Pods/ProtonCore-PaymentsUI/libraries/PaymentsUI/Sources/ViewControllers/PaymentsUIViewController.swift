//
//  PaymentsUIViewController.swift
//  ProtonCore_PaymentsUI - Created on 01/06/2021.
//
//  Copyright (c) 2021 Proton Technologies AG
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
import ProtonCore_Foundations
import ProtonCore_UIFoundations

protocol PaymentsUIViewControllerDelegate: AnyObject {
    func userDidCloseViewController()
    func userDidDismissViewController()
    func userDidSelectPlan(plan: PlanPresentation, completionHandler: @escaping () -> Void)
    func planPurchaseError()
}

public final class PaymentsUIViewController: UIViewController, AccessibleView {
    
    // MARK: - Constants
    
    private let sectionHeaderView = "PlanSectionHeaderView"
    private let sectionHeaderHeight: CGFloat = 91.0
    
    // MARK: - Outlets
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableHeaderLabel: UILabel! {
        didSet {
            tableHeaderLabel.textColor = ColorProvider.TextNorm
        }
    }
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
            tableView.allowsSelection = false
            tableView.separatorStyle = .none
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedSectionHeaderHeight = sectionHeaderHeight
        }
    }
    @IBOutlet weak var infoIcon: UIImageView! {
        didSet {
            infoIcon.image = IconProvider.info
        }
    }
    
    // MARK: - Properties
    
    weak var delegate: PaymentsUIViewControllerDelegate?
    var model: PaymentsUIViewModelViewModel?
    var mode: PaymentsUIMode = .signup
    var modalPresentation = false
    var hideFooter = false

    private let navigationBarAdjuster = NavigationBarAdjustingScrollViewDelegate()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {} else {
            if ProtonColorPallete.brand == .vpn {
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
    
    // MARK: - Internal methods
    
    func reloadData() {
        isData = true
        if isViewLoaded {
            tableView.reloadData()
            reloadUI()
        }
    }

    func showBanner(banner: PMBanner, position: PMBannerPosition) {
        if !activityIndicator.isHidden {
            activityIndicator.isHidden = true
        }
        PMBanner.dismissAll(on: self)
        banner.show(at: position, on: self)
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
        switch model?.footerType {
        case .withPlans:
            tableFooterTextLabel.text = CoreString._pu_plan_footer_desc
        case .withoutPlans, .none:
            tableFooterTextLabel.text = CoreString._pu_plan_footer_desc_purchased
        case .disabled:
            hideFooter = true
        }
        activityIndicator.isHidden = true
        updateHeaderFooterViewHeight()
        if mode == .signup {
            tableHeaderLabel.text = CoreString._pu_select_plan_title
            navigationItem.title = ""
        } else {
            if modalPresentation {
                switch mode {
                case .current:
                    navigationItem.title = CoreString._pu_subscription_title
                    updateTitleAttributes()
                case .update:
                    switch model?.footerType {
                    case .withPlans:
                        navigationItem.title = CoreString._pu_upgrade_plan_title
                    case .withoutPlans, .disabled, .none:
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
}

extension PaymentsUIViewController: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return model?.plans.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model?.plans[section].count ?? 0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PlanCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? PlanCell, let plan = model?.plans[indexPath.section][indexPath.row] {
            cell.delegate = self
            cell.configurePlan(plan: plan, isSignup: mode == .signup)
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
}

extension PaymentsUIViewController: PlanCellDelegate {
    func userPressedSelectPlanButton(plan: PlanPresentation, completionHandler: @escaping () -> Void) {
        lockUI()
        delegate?.userDidSelectPlan(plan: plan) { [weak self] in
            completionHandler()
            self?.unlockUI()
        }
    }
}
