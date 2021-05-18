//
//  StorefrontCollectionViewController.swift
//  ProtonMail - Created on 16/12/2018.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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
import MBProgressHUD
import PromiseKit

final class StorefrontCollectionViewController: UICollectionViewController {
    typealias Sections = StorefrontViewModel.Sections
    private var coordinator: StorefrontCoordinator!
    
    internal var viewModel: StorefrontViewModel!
    private var viewModelObservers: [NSKeyValueObservation]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.setCollectionViewLayout(CollectionViewTableLayout(), animated: true, completion: nil)
        MBProgressHUD.showAdded(to: self.view, animated: true)
        _ = firstly {
            self.viewModel.updateSubscription()
        }.done {
            MBProgressHUD.hide(for: self.view, animated: true)
            self.setupObserve()
            self.collectionView.reloadData()
        }.catch({ (error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            Analytics.shared.error(message: .fetchSubscriptionData, error: error, user: self.viewModel.currentUser)
            self.showErrorAlert()
        })
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.viewModel.numberOfSections()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.numberOfItems(in: section)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = self.viewModel.item(for: indexPath)
        let cellReuseIdentifier = self.cellReuseIdentifier(for: item)
        
        guard let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as? StorefrontItemConfigurableCell else {
            assert(false, "Failed to dequeue cell")
            return UICollectionViewCell()
        }
        
        cell.setup(with: item)
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let section = Sections(rawValue: indexPath.section) else {
            return
        }
        switch section {
        case .others:
            if let plan = self.viewModel.plan(at: indexPath) {
                self.coordinator.go(to: plan)
            }
        
        case .buyLink:
            if let subscription = self.viewModel.currentSubscription {
                self.coordinator.goToBuyMoreCredits(for: subscription)
            }

        case .annotation where self.viewModel.isHavingVpnPlanInCurrentSubscription:
            self.coordinator.openProtonWebPage()
        default: break
        }
    }
    
    private func cellReuseIdentifier(for item: AnyStorefrontItem) -> String {
        switch item {
        case is LogoStorefrontItem: return "\(StorefrontLogoCell.self)"
        case is DetailStorefrontItem: return "\(StorefrontDetailCell.self)"
        case is AnnotationStorefrontItem: return "\(StorefrontAnnotationCell.self)"
        case is SubsectionHeaderStorefrontItem: return "\(StorefrontDisclaimerCell.self)"
        case is LinkStorefrontItem: return "\(StorefrontDetailCell.self)"
        case is BuyButtonStorefrontItem: return "\(StorefrontBuyButtonCell.self)"
        case is DisclaimerStorefrontItem: return "\(StorefrontDisclaimerCell.self)"
        default:
            assert(false, "Unknown cell type requested")
            return ""
        }
    }
    
    private func showErrorAlert() {
        let alertController = UIAlertController(title: LocalString._general_alert_title, message: LocalString._iap_unavailable, preferredStyle: .alert)
        alertController.addOKAction { [weak self](_) in
            self?.coordinator.goToInbox()
        }
        self.present(alertController, animated: true, completion: nil)
    }
}

extension StorefrontCollectionViewController {
    private func setupObserve() {
        self.viewModelObservers = [
            self.viewModel.observe(\.title, options: [.new, .initial], changeHandler: { [unowned self] viewModel, change in
                self.title = viewModel.title
            }),
            self.viewModel.observe(\.logoItem, options: [.new], changeHandler: { [unowned self] viewModel, change in
                self.collectionView.reloadSections(Sections.logo.indexSet)
            }),
            self.viewModel.observe(\.detailItems, options: [.new], changeHandler: { [unowned self] viewModel, change in
                self.collectionView.reloadSections(Sections.detail.indexSet)
            }),
            self.viewModel.observe(\.annotationItem, options: [.new], changeHandler: { [unowned self] viewModel, change in
                self.collectionView.reloadSections(Sections.annotation.indexSet)
            }),
            self.viewModel.observe(\.buyLinkItem, options: [.new], changeHandler: { [unowned self] viewModel, change in
                self.collectionView.performBatchUpdates({
                    self.collectionView.reloadSections(Sections.buyLinkHeader.indexSet)
                    self.collectionView.reloadSections(Sections.buyLink.indexSet)
                }, completion: nil)
            }),
            self.viewModel.observe(\.othersItems, options: [.new], changeHandler: { [unowned self] viewModel, change in
                self.collectionView.performBatchUpdates({
                    self.collectionView.reloadSections(Sections.others.indexSet)
                    self.collectionView.reloadSections(Sections.othersHeader.indexSet)
                }, completion: nil)
            }),
            self.viewModel.observe(\.buyButtonItem, options: [.new], changeHandler: { [unowned self] viewModel, change in
                self.collectionView.reloadSections(Sections.buyButton.indexSet)
            }),
            self.viewModel.observe(\.creditsItem, options: [.new], changeHandler: { [unowned self] viewModel, change in
                self.collectionView.reloadSections(Sections.credits.indexSet)
            })
        ]
    }
}

extension StorefrontCollectionViewController: StorefrontBuyButtonCellDelegate {
    func buyButtonTapped() {
        let window = self.view.window
        self.viewModel.buy(successHandler: { [weak self] in
            if let window = window {
                ConfettiLayer.fire(on: window, delegate: self)
                UINotificationFeedbackGenerator.init().notificationOccurred(.success)
            }
            self?.coordinator.stop()
        }, errorHandler: { error in
            let alert = UIAlertController(title: LocalString._error_occured, message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(.init(title: LocalString._general_ok_action, style: .cancel, handler: nil))
            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
        })
    }
}

extension StorefrontCollectionViewController: CoordinatedNew {
    typealias coordinatorType = StorefrontCoordinator
    
    func set(coordinator: StorefrontCoordinator) {
        self.coordinator = coordinator
    }
    
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
}

extension StorefrontCollectionViewController: CAAnimationDelegate {
    func animationDidStop(_ animation: CAAnimation, finished flag: Bool) {
        if let layer = animation.value(forKey: String(describing: ConfettiLayer.self)) as? CALayer {
            layer.removeAllAnimations()
            layer.removeFromSuperlayer()
        }
    }
}

