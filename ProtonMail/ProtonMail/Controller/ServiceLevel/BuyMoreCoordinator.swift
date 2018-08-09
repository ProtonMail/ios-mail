//
//  BuyMoreCoordinator.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 09/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class BuyMoreCoordinator: Coordinator {
    func make<SomeCoordinator: Coordinator>(coordinatorFor next: Never) -> SomeCoordinator {
        fatalError()
    }
    
    weak var controller: UIViewController! = UIStoryboard(name: "ServiceLevel", bundle: .main).make(BuyMoreViewController.self)
    
    typealias Destination = Never
}
