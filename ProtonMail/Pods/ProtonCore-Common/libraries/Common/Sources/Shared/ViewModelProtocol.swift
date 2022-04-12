//
//  ViewModelProtocol.swift
//  ProtonCore-Common - Created on 1/18/16.
//
//  Copyright (c) 2019 Proton Technologies AG
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

public protocol ViewModelProtocolBase: AnyObject {
    func setModel(viewModel: Any)
    func inactiveViewModel()
}

public protocol ViewModelProtocol: ViewModelProtocolBase {
    /// typedefine - view model -- if the class name defined in set function. the sub class could ignore viewModelType
    associatedtype ViewModelType

    func set(viewModel: ViewModelType)
}

public extension ViewModelProtocol {
    func setModel(viewModel: Any) {
        guard let viewModel = viewModel as? ViewModelType else {
            fatalError("This view model type doesn't match") // this shouldn't happend
        }
        self.set(viewModel: viewModel)
    }
    /// optional
    func inactiveViewModel() {
    }
}
