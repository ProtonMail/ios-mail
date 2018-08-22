//
//  ServiceLevelViewController.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 07/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

class ServiceLevelViewController: UICollectionViewController, Coordinated {
    typealias CoordinatorType = ServiceLevelCoordinator
    internal var viewModel: ServiceLevelViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.viewModel.title
        if let collectionView = self.collectionView {
            self.viewModel.cellTypes.forEach(collectionView.register)
            collectionView.setCollectionViewLayout(self.viewModel.collectionViewLayout, animated: true, completion: nil)
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.viewModel.sections.count
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int
    {
        return self.viewModel.sections[section].count
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
        let section = self.viewModel.sections[indexPath.section]
        guard let cell = self.collectionView?.dequeueReusableCell(section.cellType, for: indexPath) else {
            fatalError()
        }
        section.embed(indexPath.row, onto: cell)
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let destination = self.viewModel.shouldPerformSegue(byItemOn: indexPath) else {
            return
        }
        self.coordinator.go(to: destination, creating: ServiceLevelViewController.self)
    }
}


