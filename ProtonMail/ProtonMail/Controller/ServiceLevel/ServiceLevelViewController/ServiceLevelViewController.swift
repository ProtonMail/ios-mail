//
//  ServiceLevelViewController.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 07/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

protocol ServiceLevelDataSourceDelegate: class {
    func canPurchaseProduct(id: String) -> Bool
    func purchaseProduct(id: String)
}

extension ServiceLevelViewController: ServiceLevelDataSourceDelegate {
    func purchaseProduct(id: String) {
        try! StoreKitManager.default.purchaseProduct(withId: id, username: sharedUserDataService.username!) // FIXME: username
    }
    
    func canPurchaseProduct(id: String) -> Bool {
        return StoreKitManager.default.readyToPurchaseProduct(id: id, username: sharedUserDataService.username!) // FIXME: username
    }
}

class ServiceLevelViewController: UICollectionViewController, Coordinated {
    typealias CoordinatorType = ServiceLevelCoordinator
    internal var dataSource: ServiceLevelDataSource! {
        didSet {
            dataSource.delegate = self
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
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let destination = self.dataSource.shouldPerformSegue(byItemOn: indexPath) else {
            return
        }
        self.coordinator.go(to: destination, creating: ServiceLevelViewController.self)
    }
}


