//
//  Saver.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 07/11/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class Saver<T> {
    open func get() -> T? {
        fatalError()
    }
    open func set(newValue: T?) {
        fatalError()
    }
}
