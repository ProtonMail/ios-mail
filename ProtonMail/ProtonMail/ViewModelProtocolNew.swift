//
//  ViewModelProtocal.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/12/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation



//Notes for refactor later:
// view model need based on ViewModelBase
// view model factory control the view model impls
// view model impl control viewmodel navigate
// View model service tracking the ui flows

protocol ViewModelProtocolBase {
    func setModel(vm: Any)
}

protocol ViewModelProtocolNew : ViewModelProtocolBase {
    associatedtype argType
    func setViewModel(_ vm: argType) -> Void
    func inactiveViewModel() -> Void
}


extension ViewModelProtocolNew {
    func setModel(vm: Any) {
        guard let viewModel = vm as? argType else {
            fatalError("This view model type doesn't match") //this shouldn't happend
        }
        self.setViewModel(viewModel)
    }
}
