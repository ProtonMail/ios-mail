//
//  ElementsProtocol+iOSExtension.swift
//  pmtest
//
//  Created by Robert Patchett on 18.10.22.
//

import Foundation

public extension ElementsProtocol {

    /**
     UiDevice instance which can be used to invoke device functions.
     */
    func device() -> UIDevice {
        // swiftlint:disable discouraged_direct_init
        return UIDevice()
    }
}
