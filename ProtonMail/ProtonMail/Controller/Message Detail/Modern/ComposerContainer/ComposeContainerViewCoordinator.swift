//
//  ComposeContainerViewCoordinator.swift
//  ProtonMail - Created on 15/04/2019.
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

class ComposeContainerViewCoordinator: TableContainerViewCoordinator {
    private weak var controller: ComposeContainerViewController!
    private var header: ComposeHeaderViewController!
    private var editor: EditorViewController!
    
    init(controller: ComposeContainerViewController) {
        self.controller = controller
        super.init()
    }
    
    internal func cancelAction(_ sender: UIBarButtonItem) {
        // FIXME
        self.editor.cancelAction(sender)
    }
    
    internal func createEditor(_ childViewModel: EditorViewModel) {
        let prechild = UIStoryboard(name: "Composer", bundle: nil).make(ComposeViewController.self)
        object_setClass(prechild, EditorViewController.self)
        guard let child = prechild as? EditorViewController else {
            fatalError()
        }
        child.injectHeader(self.header)
        child.enclosingScroller = self.controller
        
        let vmService = sharedServices.get() as ViewModelService
        vmService.newDraft(vmp: child)
        let coordinator = ComposeCoordinator(vc: child, vm: childViewModel, services: sharedServices)
        coordinator.start()
        self.editor = child
    }
    
    internal func createHeader() -> ComposeHeaderViewController {
        self.header = ComposeHeaderViewController(nibName: String(describing: ComposeHeaderViewController.self), bundle: nil)
        return self.header
    }
    
    override func embedChild(indexPath: IndexPath, onto cell: UITableViewCell) {
        switch indexPath.row {
        case 0: self.embed(self.header, onto: cell.contentView, ownedBy: self.controller)
        case 1: self.embed(self.editor, onto: cell.contentView, ownedBy: self.controller)
        default:
            assert(false, "Children number misalignment")
            return
        }
    }
}
