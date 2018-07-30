//
//  ViewModelServiceImpl+Share.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/19/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation

//keep this unique
let sharedVMService : ViewModelService = ViewModelServiceShareImpl()
final class ViewModelServiceShareImpl: ViewModelService {
    private weak var latestComposerViewModel : ComposeViewModel?
    
    override func buildComposer<T: ViewModelProtocolNew>(_ vmp: T, subject: String, content: String, files: [FileData]) {
        let viewModel = ComposeViewModelImpl(subject: subject, body: content, files: files, action: .newDraftFromShare)
        vmp.setModel(vm: viewModel)
        self.latestComposerViewModel = viewModel
    }
}
