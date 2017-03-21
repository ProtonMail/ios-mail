//
//  LabelsViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import CoreData

protocol LablesViewControllerDelegate {
    func dismissed()
}

class LablesViewController : UIViewController {
    
    var viewModel : LabelViewModel!
    
    let kToFolderManager : String = "toFolderManagerSegue"
    let kToLableManager : String = "toLabelManagerSegue"
    
    
    private var selected : NSIndexPath?
    
    private var archiveMessage = false;
    
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
    //
    var delegate : LablesViewControllerDelegate?
    var applyButtonText : String!
    
    //
    private var fetchedLabels: NSFetchedResultsController?
    var tempSelected : LabelMessageModel? = nil
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.layer.cornerRadius = 4;

        self.setupFetchedResultsController()
        titleLabel.text = viewModel.getTitle()
        if viewModel.showArchiveOption() {
            archiveView.hidden = false
            archiveConstrains.constant = 45.0
        } else {
            archiveView.hidden = true
            archiveConstrains.constant = 0
        }
        
        tableView.allowsSelection = true
        
        switch viewModel.getFetchType() {
        case .all:
            middleLineConstraint.priority = 1000
            addFolderCenterConstraint.priority = 750
            addLabelCenterConstraint.priority = 750
            addLabelButton.hidden = false
            addFolderButton.hidden = false
        case .label:
            middleLineConstraint.priority = 750
            addFolderCenterConstraint.priority = 750
            addLabelCenterConstraint.priority = 1000
            addLabelButton.hidden = false
            addFolderButton.hidden = true
        case .folder:
            middleLineConstraint.priority = 750
            addFolderCenterConstraint.priority = 1000
            addLabelCenterConstraint.priority = 750
            addLabelButton.hidden = true
            addFolderButton.hidden = false
        }
        
        applyButtonText = viewModel.getApplyButtonText()
        applyButton.setTitle(applyButtonText, forState: UIControlState.Normal)
        cancelButton.setTitle(viewModel.getCancelButtonText(), forState: UIControlState.Normal)
        
        tableView.noSeparatorsBelowFooter()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    @IBAction func archiveSelectAction(sender: UIButton) {
        archiveMessage = !archiveMessage
        if archiveMessage {
            archiveSelectButton.setImage(UIImage(named: "mail_check-active"), forState: UIControlState.Normal)
        } else {
            archiveSelectButton.setImage(UIImage(named: "mail_check"), forState: UIControlState.Normal)
        }
    }
    @IBAction func addFolder(sender: AnyObject) {
        performSegueWithIdentifier(kToFolderManager, sender: self)
    }
    
    @IBAction func addLabel(sender: AnyObject) {
        performSegueWithIdentifier(kToLableManager, sender: self)
    }
    
    @IBAction func applyAction(sender: AnyObject) {
        self.viewModel.apply(archiveMessage)
        self.dismissViewControllerAnimated(true, completion: nil)
        delegate?.dismissed()
    }
    
    @IBAction func cancelAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        delegate?.dismissed()
    }
    
    private func setupFetchedResultsController() {
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
    
    override func viewWillDisappear(animated: Bool) {
        self.fetchedLabels?.delegate = nil
    }
    
    override func viewWillAppear(animated: Bool) {
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == kToFolderManager {
            let popup = segue.destinationViewController as! LableEditViewController
            popup.viewModel = FolderCreatingViewModelImple()
        } else if segue.identifier == kToLableManager {
            let popup = segue.destinationViewController as! LableEditViewController
            popup.viewModel = LabelCreatingViewModelImple()
        }
    }
}

// MARK: - UITableViewDataSource

extension LablesViewController: UITableViewDataSource {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if (self.tableView.respondsToSelector(Selector("setSeparatorInset:"))) {
            self.tableView.separatorInset = UIEdgeInsetsZero
        }
        
        if (self.tableView.respondsToSelector(Selector("setLayoutMargins:"))) {
            self.tableView.layoutMargins = UIEdgeInsetsZero
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let labelCell = tableView.dequeueReusableCellWithIdentifier("labelApplyCell", forIndexPath: indexPath) as! LabelTableViewCell
        if let label = fetchedLabels?.objectAtIndexPath(indexPath) as? Label {
            let lm = viewModel.getLabelMessage(label)
            labelCell.ConfigCell(lm, showIcon: viewModel.getFetchType() == .all, vc: self)
        }
        return labelCell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = fetchedLabels?.numberOfRowsInSection(section) ?? 0
        return count
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if (cell.respondsToSelector(Selector("setSeparatorInset:"))) {
            cell.separatorInset = UIEdgeInsetsZero
        }
        
        if (cell.respondsToSelector(Selector("setLayoutMargins:"))) {
            cell.layoutMargins = UIEdgeInsetsZero
        }
    }
}

// MARK: - UITableViewDelegate

extension LablesViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 45.0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // verify whether the user is checking messages or not
        if let label = fetchedLabels?.objectAtIndexPath(indexPath) as? Label {
            viewModel.cellClicked(label)
            switch viewModel.getFetchType()
            {
            case .all, .label:
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                break;
            case .folder:
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
                    tableView.reloadData()
                }
            }
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension LablesViewController : NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch(type) {
        case .Delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch(type) {
        case .Delete:
            if let indexPath = indexPath {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            }
        case .Insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            }
        case .Update:
            if let _ = indexPath {
                //TODO:: need check here
                //if let cell = tableView.cellForRowAtIndexPath(indexPath) as? MailboxTableViewCell {
                //configureCell(cell, atIndexPath: indexPath)
                //}
            }
        default:
            return
        }
    }
}

