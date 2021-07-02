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
    var modalPresentation = false

    private let navigationBarAdjuster = NavigationBarAdjustingScrollViewDelegate()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableHeaderView?.isHidden = true
        tableView.tableFooterView?.isHidden = true
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
    }

    override public func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        navigationBarAdjuster.setUp(for: tableView, parent: parent)
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
        if !activityIndicator.isHidden {
            activityIndicator.isHidden = true
        }
        showBanner(message: message, position: .top)
    }
    
    func reloadData() {
        isData = true
        if isViewLoaded {
            tableView.reloadData()
            reloadUI()
        }
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
        guard isDataLoaded else { return }
        if let isAnyPlanToPurchase = model?.isAnyPlanToPurchase {
            self.tableFooterTextDescription.isHidden = !isAnyPlanToPurchase
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
                    navigationItem.title = CoreString._pu_current_plan_title
                case .update:
                    if model?.isAnyPlanToPurchase ?? false {
                        navigationItem.title = CoreString._pu_update_plan_title
                    } else {
                        navigationItem.title = CoreString._pu_current_plan_title
                    }
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
