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
    

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.coordinator.go(to: .buyMore, creating: BuyMoreViewController.self)
    }
}
