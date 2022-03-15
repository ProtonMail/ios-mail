//
//  ViewModelProtocal.swift
//  ProtonMail - Created on 3/12/18.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

/// Notes for refactor later:
/// view model need based on ViewModelBase
/// view model factory control the view model impls
/// view model impl control viewmodel navigate
/// View model service tracking the ui flows

protocol ViewModelProtocolBase: AnyObject {
    func setModel(vm: Any)
    func inactiveViewModel()
}

protocol ViewModelProtocol: ViewModelProtocolBase {
    /// typedefine - view model -- if the class name defined in set function. the sub class could ignore viewModelType
    associatedtype viewModelType

    func set(viewModel: viewModelType)
}

extension ViewModelProtocol {
    func setModel(vm: Any) {
        guard let viewModel = vm as? viewModelType else {
            fatalError("This view model type doesn't match") // this shouldn't happend
        }
        self.set(viewModel: viewModel)
    }

    /// optional
    func inactiveViewModel() {

    }
}
