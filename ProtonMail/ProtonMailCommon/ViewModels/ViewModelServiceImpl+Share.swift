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
    
    private weak var latestComposerViewModel : ComposeViewModel? // FIXME: why do we need it at all?
    
    override func buildComposer<T>(_ vmp: T, subject: String, content: String, files: [FileData]) where T : ViewModelProtocolNew {
        let viewModel = ComposeViewModelImpl(subject: subject, body: content, files: files, action: .newDraftFromShare)
        vmp.setModel(vm: viewModel)
        self.latestComposerViewModel = viewModel
    }
    
//    override func newShareDraftViewModel(_ vmp : ViewModelProtocol, subject: String, content: String, files : [FileData]) {
//        latestComposerViewModel = ComposeViewModelImpl(subject: subject, body: content, files: files, action: .newDraftFromShare);
//        vmp.setViewModel(latestComposerViewModel!)
//    }
}
