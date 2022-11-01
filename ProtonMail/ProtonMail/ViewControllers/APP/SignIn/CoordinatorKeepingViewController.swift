//
//  CoordinatorKeepingViewController.swift
//  Proton Mail
//
//  Created by Krzysztof Siejkowski on 30/04/2021.
//  Copyright © 2021 Proton Mail. All rights reserved.
//

import UIKit

final class CoordinatorKeepingViewController<Coordinator>: UIViewController {

    let coordinator: Coordinator
    private let backgroundColor: UIColor

    init(coordinator: Coordinator, backgroundColor: UIColor) {
        self.coordinator = coordinator
        self.backgroundColor = backgroundColor
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = backgroundColor
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
