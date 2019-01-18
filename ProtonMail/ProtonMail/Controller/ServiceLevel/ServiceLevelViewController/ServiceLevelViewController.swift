//
//  ServiceLevelViewController.swift
//  ProtonMail - Created on 07/08/2018.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
    internal lazy var refreshHandler: ()->Void = { [weak self] in
        DispatchQueue.main.async {
            self?.dataSource.reload()
            self?.collectionView?.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.dataSource.title
        if let collectionView = self.collectionView {
            [AutoLayoutSizedCell.self, FirstSubviewSizedCell.self].forEach(collectionView.register)
            collectionView.setCollectionViewLayout(TableLayout(), animated: true, completion: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        StoreKitManager.default.refreshHandler = self.refreshHandler
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
            assert(false, "Something wrong in collection view")
            return UICollectionReusableView()
        }
        return separator
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let section = self.dataSource.sections[indexPath.section]
        guard let cell = self.collectionView?.dequeueReusableCell(section.cellType, for: indexPath) else {
            assert(false, "Something wrong in collection view")
            return UICollectionViewCell()
        }
        section.embed(indexPath.row, onto: cell)
        return cell
    }
}

extension ServiceLevelViewControllerBase: ServiceLevelDataSourceDelegate {
    func purchaseProduct(id: String) {
        let successCompletion: ()->Void = { [weak self] in
            DispatchQueue.main.async {
                // TODO: nice congratulating animation
                self?.navigationController?.popViewController(animated: true)
            }
        }
        let errorCompletion: (Error)->Void = { error in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: LocalString._error_occured, message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(.init(title: LocalString._general_ok_action, style: .cancel, handler: nil))
                UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
            }
        }
        let deferredCompletion: ()->Void = {
            // TODO: nice animation to explain user should be patient
        }
        
        StoreKitManager.default.purchaseProduct(withId: id, successCompletion: successCompletion, errorCompletion: errorCompletion, deferredCompletion: deferredCompletion)
    }
    
    func canPurchaseProduct(id: String) -> Bool {
        return StoreKitManager.default.readyToPurchaseProduct()
    }
}
