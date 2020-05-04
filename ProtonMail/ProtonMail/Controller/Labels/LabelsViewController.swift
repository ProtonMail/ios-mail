//
//  LabelsViewController.swift
//  ProtonMail - Created on 8/17/15.
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
import CoreData

protocol LablesViewControllerDelegate {
    func dismissed()
    func apply(type: LabelFetchType)
}

//TODO::fixme coordinator
class LablesViewController : UIViewController {
    
    var viewModel : LabelViewModel!
    
    let kToCreateFolder : String = "toCreateFolderSegue"
    let kToCreateLabel : String = "toCreateLabelSegue"
    let kToEditingFolder : String = "toEditingFolderSegue"
    let kToEditingLabel : String = "toEditingLabelSegue"
    
    fileprivate var selected : IndexPath?
    
    fileprivate var archiveMessage = false
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var applyButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var archiveSelectButton: UIButton!
    
    @IBOutlet weak var archiveView: UIView!
    @IBOutlet weak var archiveConstrains: NSLayoutConstraint!
    
    
    @IBOutlet weak var addFolderCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var addLabelCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var middleLineConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var addLabelButton: UIButton!
    @IBOutlet weak var addFolderButton: UIButton!
    @IBOutlet weak var archiveOptionLabel: UILabel!
    //
    var delegate : LablesViewControllerDelegate?
    var applyButtonText : String!
    
    //
    fileprivate var fetchedLabels: NSFetchedResultsController<NSFetchRequestResult>?
    var tempSelected : LabelMessageModel? = nil
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.layer.cornerRadius = 4
        
        addLabelButton.titleLabel?.numberOfLines = 0
        addLabelButton.titleLabel?.lineBreakMode = .byWordWrapping
        addLabelButton.setTitle(LocalString._labels_add_label_action, for: .normal)
        addFolderButton.titleLabel?.numberOfLines = 0
        addFolderButton.titleLabel?.lineBreakMode = .byWordWrapping
        addFolderButton.setTitle(LocalString._labels_add_folder_action, for: .normal)
        archiveOptionLabel.text = LocalString._labels_apply_archive_check
        
        self.setupFetchedResultsController()
        titleLabel.text = viewModel.getTitle()
        if viewModel.showArchiveOption() {
            archiveView.isHidden = false
            archiveConstrains.constant = 45.0
        } else {
            archiveView.isHidden = true
            archiveConstrains.constant = 0
        }
        
        self.tableView.allowsSelection = true
        self.tableView.estimatedRowHeight = 45.0
        
        switch viewModel.getFetchType() {
        case .all:
            middleLineConstraint.priority = UILayoutPriority(rawValue: 1000)
            addFolderCenterConstraint.priority = UILayoutPriority(rawValue: 750)
            addLabelCenterConstraint.priority = UILayoutPriority(rawValue: 750)
            addLabelButton.isHidden = false
            addFolderButton.isHidden = false
        case .label:
            middleLineConstraint.priority = UILayoutPriority(rawValue: 750)
            addFolderCenterConstraint.priority = UILayoutPriority(rawValue: 750)
            addLabelCenterConstraint.priority = UILayoutPriority(rawValue: 1000)
            addLabelButton.isHidden = false
            addFolderButton.isHidden = true
        case .folder, .folderWithInbox, .folderWithOutbox:
            middleLineConstraint.priority = UILayoutPriority(rawValue: 750)
            addFolderCenterConstraint.priority = UILayoutPriority(rawValue: 1000)
            addLabelCenterConstraint.priority = UILayoutPriority(rawValue: 750)
            addLabelButton.isHidden = true
            addFolderButton.isHidden = false
        case .contactGroup:
            break
        }
        
        applyButtonText = viewModel.getApplyButtonText()
        applyButton.setTitle(applyButtonText, for: UIControl.State())
        cancelButton.setTitle(viewModel.getCancelButtonText(), for: UIControl.State())
        
        tableView.noSeparatorsBelowFooter()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    @IBAction func archiveSelectAction(_ sender: UIButton) {
        archiveMessage = !archiveMessage
        if archiveMessage {
            archiveSelectButton.setImage(UIImage(named: "mail_check-active"), for: UIControl.State())
        } else {
            archiveSelectButton.setImage(UIImage(named: "mail_check"), for: UIControl.State())
        }
    }
    @IBAction func addFolder(_ sender: AnyObject) {
        performSegue(withIdentifier: kToCreateFolder, sender: self)
    }
    
    @IBAction func addLabel(_ sender: AnyObject) {
        performSegue(withIdentifier: kToCreateLabel, sender: self)
    }
    
    @IBAction func applyAction(_ sender: AnyObject) {
        let _ = self.viewModel.apply(archiveMessage: archiveMessage)
        self.dismiss(animated: true, completion: nil)
        delegate?.dismissed()
        delegate?.apply(type: viewModel.getFetchType())
    }
    
    @IBAction func cancelAction(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
        delegate?.dismissed()
    }
    
    fileprivate func setupFetchedResultsController() {
        self.fetchedLabels = viewModel.fetchController()
        if let fetchedResultsController = self.fetchedLabels {
            fetchedResultsController.delegate = self
            do {
                try fetchedResultsController.performFetch()
            } catch let ex as NSError {
                PMLog.D("error: \(ex)")
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.fetchedLabels?.delegate = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let apiService = self.viewModel.apiService
        let labelService = self.viewModel.labelService
        
        if segue.identifier == kToCreateFolder {
            let popup = segue.destination as! LableEditViewController
            popup.viewModel = FolderCreatingViewModelImple(apiService: apiService, labelService: labelService)
        } else if segue.identifier == kToCreateLabel {
            let popup = segue.destination as! LableEditViewController
            popup.viewModel = LabelCreatingViewModelImple(apiService: apiService, labelService: labelService)
        } else if segue.identifier == kToEditingLabel {
            let popup = segue.destination as! LableEditViewController
            popup.viewModel = LabelEditingViewModelImple(label: sender as! Label, apiService: apiService, labelService: labelService)
        } else if segue.identifier == kToEditingFolder {
            let popup = segue.destination as! LableEditViewController
            popup.viewModel = FolderEditingViewModelImple(label: sender as! Label, apiService: apiService, labelService: labelService)
        }
    }
}

// MARK: - UITableViewDataSource

extension LablesViewController: UITableViewDataSource {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.zeroMargin()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let labelCell = tableView.dequeueReusableCell(withIdentifier: "labelApplyCell", for: indexPath) as! LabelTableViewCell
        if let label = fetchedLabels?.object(at: indexPath) as? Label {
            let lm = viewModel.getLabelMessage(label)
            let showEdit = viewModel.getFetchType() == .all
            labelCell.ConfigCell(model: lm,
                                 showIcon: viewModel.getFetchType() == .all,
                                 showEdit: showEdit,
                                 editAction: { [weak self, weak labelCell] (sender) in
                guard let self = self else { return }
                if labelCell == sender, let editlabel = self.fetchedLabels?.object(at: indexPath) as? Label {
                    if editlabel.exclusive {
                        self.performSegue(withIdentifier: self.kToEditingFolder, sender: editlabel)
                    } else {
                        self.performSegue(withIdentifier: self.kToEditingLabel, sender: editlabel)
                    }
                }
            })
        }
        return labelCell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = fetchedLabels?.numberOfRows(in: section) ?? 0
        return count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.zeroMargin()
    }
}

// MARK: - UITableViewDelegate

extension LablesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // verify whether the user is checking messages or not
        if let label = fetchedLabels?.object(at: indexPath) as? Label {
            viewModel.cellClicked(label)
            switch viewModel.getFetchType()
            {
            case .all, .label:
                tableView.reloadRows(at: [indexPath], with: .automatic)
            case .folder, .folderWithInbox, .folderWithOutbox:
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) { () -> Void in
                    tableView.reloadData()
                }
            case .contactGroup:
                break
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension LablesViewController : NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch(type) {
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch(type) {
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.fade)
            }
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: UITableView.RowAnimation.fade)
            }
        case .update:
            if let index = indexPath {
                tableView.reloadRows(at: [index], with: UITableView.RowAnimation.automatic)
            }
        default:
            return
        }
    }
}

