//
//  ViewModelServiceImpl+Share.swift
//  ProtonMail - Created on 7/19/17.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
