//
//  ServiceLevelViewController.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 07/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

//FIXME: the whole structure has an issue. when some of the data in details need to load dynamically.
//       it is hard to change. I will leave it here and make an easy workaround. we change it later in an ideal way.

protocol ServiceLevelDataSourceDelegate: class {
    func canPurchaseProduct(id: String) -> Bool
    func purchaseProduct(id: String)
}

class BuyMoreViewController: ServiceLevelViewControllerBase, Coordinated {
    typealias CoordinatorType = BuyMoreCoordinator
    
    func setup(with subscription: Subscription) {
        self.dataSource = BuyMoreDataSource(delegate: self, subscription: subscription)
    }
}

class PlanDetailsViewController: ServiceLevelViewControllerBase, Coordinated {
    typealias CoordinatorType = PlanDetailsCoordinator
    
    func setup(with plan: ServicePlan) {
        self.dataSource = PlanDetailsDataSource(delegate: self, plan: plan)
    }
}

class ServiceLevelViewController: ServiceLevelViewControllerBase, Coordinated {
    typealias CoordinatorType = ServiceLevelCoordinator
    private var subscriptionChanges: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.subscriptionChanges = ServicePlanDataService.shared.observe(\ServicePlanDataService.currentSubscription) { [weak self] shared, change in
            guard let newerSubscription = shared.currentSubscription else { return }
            self?.setup(with: newerSubscription)
            self?.collectionView?.reloadData()
        }
    }
    
    func setup(with subscription: Subscription?) {
        self.dataSource = PlanAndLinksDataSource(delegate: self, subscription: ServicePlanDataService.shared.currentSubscription)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let destination = self.dataSource.shouldPerformSegue(byItemOn: indexPath) else {
            return
        }
        switch destination {
        case .buyMore:
            self.coordinator.go(to: destination, creating: BuyMoreViewController.self)
        case .details:
            self.coordinator.go(to: destination, creating: PlanDetailsViewController.self)
        }
    }
}

class ServiceLevelViewControllerBase: UICollectionViewController {
    internal var dataSource: ServiceLevelDataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.dataSource.title
        if let collectionView = self.collectionView {
            [AutoLayoutSizedCell.self, FirstSubviewSizedCell.self].forEach(collectionView.register)
            collectionView.setCollectionViewLayout(TableLayout(), animated: true, completion: nil)
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.dataSource.sections.count
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int
    {
        return self.dataSource.sections[section].count
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView
    {
        guard let separator = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kind, for: indexPath) as? SeparatorDecorationView else {
            fatalError()
        }
        return separator
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let section = self.dataSource.sections[indexPath.section]
        guard let cell = self.collectionView?.dequeueReusableCell(section.cellType, for: indexPath) else {
            fatalError()
        }
        section.embed(indexPath.row, onto: cell)
        return cell
    }
}

extension ServiceLevelViewControllerBase: ServiceLevelDataSourceDelegate {
    func purchaseProduct(id: String) {
        guard let username = sharedUserDataService.username else {
            return
        }
        let successCompletion: ()->Void = {
            self.navigationController?.popViewController(animated: true)
        }
        let errorCompletion: (Error)->Void = { error in
            let alert = UIAlertController(title: LocalString._error_occured, message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(.init(title: LocalString._general_ok_action, style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        let deferredCompletion: ()->Void = {
            
        }
        
        StoreKitManager.default.purchaseProduct(withId: id, username: username, successCompletion: successCompletion, errorCompletion: errorCompletion, deferredCompletion: deferredCompletion)
    }
    
    func canPurchaseProduct(id: String) -> Bool {
        // no matter which user is logged in now, if there is any unfinished transaction - we do not want to give opportunity to start new purchase. BE currently can process only last transaction in Receipts, so we do not want to mess up the older ones.
        return StoreKitManager.default.readyToPurchaseProduct()
    }
}
