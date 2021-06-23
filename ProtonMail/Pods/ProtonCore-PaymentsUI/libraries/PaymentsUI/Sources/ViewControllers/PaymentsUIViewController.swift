//
//  PaymentsUIViewController.swift
//  ProtonCore_PaymentsUI - Created on 01/06/2021.
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit
import ProtonCore_CoreTranslation
import ProtonCore_Foundations
import ProtonCore_UIFoundations

protocol PaymentsUIViewControllerDelegate: AnyObject {
    func userDidCloseViewController()
    func userDidDismissViewController()
    func userDidSelectPlan(plan: Plan, completionHandler: @escaping () -> Void)
}

public final class PaymentsUIViewController: UIViewController, AccessibleView {
    
    // MARK: - Outlets
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var tableHeaderLabel: UILabel! {
        didSet {
            tableHeaderLabel.textColor = UIColorManager.TextNorm
        }
    }
    @IBOutlet weak var tableFooterTextLabel: UILabel! {
        didSet {
            tableFooterTextLabel.text = CoreString._pu_plan_footer_title
            tableFooterTextLabel.textColor = UIColorManager.TextNorm
        }
    }
    @IBOutlet weak var tableFooterTextDescription: UILabel! {
        didSet {
            tableFooterTextDescription.text = CoreString._pu_plan_footer_desc
            tableFooterTextDescription.textColor = UIColorManager.TextWeak
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
        }
    }
    
    // MARK: - Properties
    
    weak var delegate: PaymentsUIViewControllerDelegate?
    var model: PaymentsUIViewModelViewModel?
    var mode: PaymentsUIMode = .signup
    var showHeader = false
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableHeaderView?.isHidden = true
        tableView.tableFooterView?.isHidden = true
        configureUI()
        generateAccessibilityIdentifiers()
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.userDidDismissViewController()
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderFooterViewHeight()
    }
    
    // MARK: - Public methods
    
    func showError(message: String) {
        showBanner(message: message, position: PMBannerPosition.topCustom(UIEdgeInsets(top: 64, left: 16, bottom: CGFloat.infinity, right: 16)))
    }
    
    func reloadData() {
        if isViewLoaded {
            tableView.reloadData()
            reloadUI()
        }
    }

    // MARK: - Actions

    @IBAction func onCloseButtonTap(_ sender: UIButton) {
        delegate?.userDidCloseViewController()
    }
    
    private func updateHeaderFooterViewHeight() {
        guard isDataLoaded, let headerView = tableView.tableFooterView, let footerView = tableView.tableFooterView else {
            return
        }
        if mode != .signup && showHeader == false {
            tableView.tableHeaderView = nil
        } else {
            tableView.tableHeaderView?.isHidden = false
        }
        tableView.tableFooterView?.isHidden = false
        
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
        if isDataLoaded {
            if let isAnyPlanToPurchase = model?.isAnyPlanToPurchase {
                self.tableFooterTextDescription.isHidden = !isAnyPlanToPurchase
            }
            activityIndicator.isHidden = true
            updateHeaderFooterViewHeight()
        }
    }
    
    private func configureUI() {
        reloadUI()
        if showHeader {
            switch mode {
            case .signup:
                tableHeaderLabel.text = CoreString._pu_select_plan_title
            case .current:
                tableHeaderLabel.text = CoreString._pu_current_plan_title
            case .update:
                tableHeaderLabel.text = CoreString._pu_update_plan_title
            }
        }
    }
    
    private var isDataLoaded: Bool {
        return model?.plans.count ?? 0 > 0
    }
}

extension PaymentsUIViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model?.plans.count ?? 0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PlanCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? PlanCell, let plan = model?.plans[indexPath.row] {
            cell.delegate = self
            cell.configurePlan(plan: plan, isSignup: mode == .signup)
        }
        return cell
    }
}

extension PaymentsUIViewController: UITableViewDelegate {

}

extension PaymentsUIViewController: PlanCellDelegate {
    func userPressedSelectPlanButton(plan: Plan, completionHandler: @escaping () -> Void) {
        lockUI()
        delegate?.userDidSelectPlan(plan: plan) {
            self.unlockUI()
            completionHandler()
        }
    }
}
