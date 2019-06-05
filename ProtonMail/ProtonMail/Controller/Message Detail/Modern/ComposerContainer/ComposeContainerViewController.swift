//
//  ComposingViewController.swift
//  ProtonMail - Created on 12/04/2019.
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
    

import UIKit

class ComposeContainerViewController: TableContainerViewController<ComposeContainerViewModel, ComposeContainerViewCoordinator>, NSNotificationCenterKeyboardObserverProtocol, UITableViewDropDelegate
{
    private var childrenHeightObservations: [NSKeyValueObservation]!
    private var cancelButton: UIBarButtonItem! //cancel button.
    @IBOutlet private var sendButton: UIBarButtonItem! //cancel button.
    private var bottomPadding: NSLayoutConstraint!
    private var dropLandingZone: UIView? // drag and drop session items dropped on this view will be added as attachments
    
    deinit {
        self.childrenHeightObservations = []
        NotificationCenter.default.removeKeyboardObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            self.tableView.dropDelegate = self
        }
        
        NotificationCenter.default.addKeyboardObserver(self)
        
        self.tableView.cellLayoutMarginsFollowReadableWidth = true
        
        self.bottomPadding = self.view.bottomAnchor.constraint(equalTo: self.tableView.bottomAnchor)
        self.bottomPadding.constant = 0.0
        self.bottomPadding.isActive = true
        
        self.cancelButton = UIBarButtonItem(title: LocalString._general_cancel_button, style: .plain, target: self, action: #selector(cancelAction))
        self.navigationItem.leftBarButtonItem = cancelButton
        self.configureNavigationBar()
        
        let childViewModel = self.viewModel.childViewModel
        let header = self.coordinator.createHeader(childViewModel)
        self.coordinator.createEditor(childViewModel)
        
        self.childrenHeightObservations = [
            childViewModel.observe(\.contentHeight) { [weak self] _, _ in
                UIView.animate(withDuration: 0.001, animations: {
                    self?.saveOffset()
                    self?.tableView.beginUpdates()
                    self?.tableView.endUpdates()
                    self?.restoreOffset()
                })
            },
            header.observe(\.size) { [weak self] _, _ in
                self?.tableView.beginUpdates()
                self?.tableView.endUpdates()
            },
            childViewModel.observe(\.showExpirationPicker) { [weak self] viewModel, _ in
                // TODO: this index is hardcoded position of expiration view, not flexible approach. Fix when decoupling Header and ExpirationPicker from old ComposeViewController
                self?.tableView.reloadRows(at: [IndexPath.init(row: 1, section: 0)], with: .fade)
            }
        ]
        
        // accessibility
        self.sendButton.accessibilityLabel = LocalString._general_send_action
    }
    
    @objc func cancelAction(_ sender: UIBarButtonItem) {
        // FIXME: that logic should be in VM of EditorViewController
        self.coordinator.cancelAction(sender)
    }
    @IBAction func sendAction(_ sender: UIBarButtonItem) {
        // FIXME: that logic should be in VM of EditorViewController
        self.coordinator.sendAction(sender)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override func configureNavigationBar() {
        super.configureNavigationBar()
        
        self.navigationController?.navigationBar.barStyle = UIBarStyle.black
        self.navigationController?.navigationBar.barTintColor = UIColor.ProtonMail.Nav_Bar_Background
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        let navigationBarTitleFont = Fonts.h2.light
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: navigationBarTitleFont
        ]
        
        self.navigationItem.leftBarButtonItem?.title = LocalString._general_cancel_button
        cancelButton.title = LocalString._general_cancel_button
    }
    
    // tableView
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard self.viewModel.childViewModel.showExpirationPicker && indexPath.row == 1 else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ExpirationPickerCell.self), for: indexPath) as? ExpirationPickerCell else {
            assert(false, "Broken expiration cell")
            return UITableViewCell()
        }
        
        self.coordinator.inject(cell.picker)
        return cell
    }
    
    // keyboard
    
    func keyboardWillHideNotification(_ notification: Notification) {
        self.bottomPadding.constant = 0.0
    }
    
    func keyboardWillShowNotification(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            self.bottomPadding.constant = keyboardFrame.cgRectValue.height
        }
    }

    // drag and drop
    
    private func error(_ description: String) {
        let alert = description.alertController()
        alert.addOKAction()
        self.present(alert, animated: true, completion: nil)
    }
    
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView,
                   canHandle session: UIDropSession) -> Bool
    {
        // return true only if all the files are supported
        let itemProviders = session.items.map { $0.itemProvider }
        return self.viewModel.filesAreSupported(from: itemProviders)
    }
    
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView,
                   dropSessionDidUpdate session: UIDropSession,
                   withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal
    {
        return UITableViewDropProposal(operation: .copy, intent: .insertIntoDestinationIndexPath)
    }
    
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, dropSessionDidEnter session: UIDropSession) {
        if self.dropLandingZone == nil {
            var dropFrame = self.tableView.frame
            dropFrame.size.height = self.coordinator.headerFrame().size.height
            let dropZone = DropLandingZone(frame: dropFrame)
            dropZone.alpha = 0.0
            self.tableView.addSubview(dropZone)
            self.dropLandingZone = dropZone
        }
        
        UIView.animate(withDuration: 0.3) {
            self.dropLandingZone?.alpha = 1.0
        }
    }
    
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, dropSessionDidExit session: UIDropSession) {
        UIView.animate(withDuration: 0.3, animations: {
            self.dropLandingZone?.alpha = 0.0
        })
    }
    
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, dropSessionDidEnd session: UIDropSession) {
        UIView.animate(withDuration: 0.3, animations: {
            self.dropLandingZone?.alpha = 0.0
        }) { _ in
            self.dropLandingZone?.removeFromSuperview()
            self.dropLandingZone = nil
        }
    }
    
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView,
                   performDropWith coordinator: UITableViewDropCoordinator)
    {
        DispatchQueue.main.async {
            LocalString._importing_drop.alertToastBottom()
        }
        
        let itemProviders = coordinator.items.map { $0.dragItem.itemProvider }
        self.viewModel.importFiles(from: itemProviders, errorHandler: self.error) {
            DispatchQueue.main.async {
                LocalString._drop_finished.alertToastBottom()
            }
        }
    }
}


class ExpirationPickerCell: UITableViewCell {
    @IBOutlet weak var picker: UIPickerView!
}
