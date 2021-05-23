//
//  ForceUpgradeTypes.swift
//  ProtonCore
//
//  Created by Krzysztof Siejkowski on 11/05/2021.
//

import Foundation

public protocol ForceUpgradeDelegate: AnyObject {
    func onForceUpgrade(message: String)
}

public protocol ForceUpgradeResponseDelegate: AnyObject {
    func onQuitButtonPressed()
    func onUpdateButtonPressed()
}
