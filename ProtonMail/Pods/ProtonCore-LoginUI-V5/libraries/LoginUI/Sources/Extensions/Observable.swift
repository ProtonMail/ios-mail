//
//  Observable.swift
//  ProtonCore-Login - Created on 26.11.2020.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

final class Observable<T> {
    var value: T {
        didSet {
            executeOnMainThread {
                self.listener?(self.value)
            }
        }
    }

    private var listener: ((T) -> Void)?

    init(_ value: T) {
        self.value = value
    }

    func bind(_ closure: @escaping (T) -> Void) {
        executeOnMainThread {
            closure(self.value)
        }
        assert(listener == nil, "Binding already used")
        listener = closure
    }
}

final class Publisher<T> {
    func publish(_ value: T) {
        executeOnMainThread {
            self.listener?(value)
        }
    }

    private var listener: ((T) -> Void)?

    func bind(_ closure: @escaping (T) -> Void) {
        assert(listener == nil, "Binding already used")
        listener = closure
    }
}

func executeOnMainThread(closure: @escaping () -> Void) {
    if Thread.isMainThread {
        closure()
    } else {
        DispatchQueue.main.async {
            closure()
        }
    }
}
