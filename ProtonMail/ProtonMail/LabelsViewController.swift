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
    func test()
}

class LablesViewController : UIViewController {
    
    var viewModel : LabelViewModel!
    
    let titles : [String] = ["#7272a7","#cf5858", "#c26cc7", "#7569d1", "#69a9d1", "#5ec7b7", "#72bb75", "#c3d261", "#e6c04c", "#e6984c", "#8989ac", "#cf7e7e", "#c793ca", "#9b94d1", "#a8c4d5", "#97c9c1", "#9db99f", "#c6cd97", "#e7d292", "#dfb286"]
    
    private var selected : NSIndexPath?
    private var isCreateView: Bool = false
    private var archiveMessage = false;
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var inputContentView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var applyButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var newLabelInput: UITextField!
    
    @IBOutlet weak var archiveSelectButton: UIButton!
    
    @IBOutlet weak var archiveView: UIView!
    @IBOutlet weak var archiveConstrains: NSLayoutConstraint!
    
    var delegate : LablesViewControllerDelegate?
    var applyButtonText : String!
    
    //
    private var fetchedLabels: NSFetchedResultsController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.layer.cornerRadius = 4;
        inputContentView.layer.cornerRadius = 4;
        inputContentView.layer.borderColor = UIColor(hexColorCode: "#DADEE8").CGColor
        inputContentView.layer.borderWidth = 1.0
        newLabelInput.delegate = self
        self.setupFetchedResultsController()
        titleLabel.text = viewModel.getTitle()
        if viewModel.showArchiveOption() {
            archiveView.hidden = false
            archiveConstrains.constant = 45.0
        } else {
            archiveView.hidden = true
            archiveConstrains.constant = 0
        }
        applyButtonText = viewModel.getApplyButtonText()
        applyButton.setTitle(applyButtonText, forState: UIControlState.Normal)
        cancelButton.setTitle(viewModel.getCancelButtonText(), forState: UIControlState.Normal)
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
    
    @IBAction func applyAction(sender: AnyObject) {
        if isCreateView {
            // start
            viewModel.createLabel(newLabelInput.text!, color: titles[selected?.row ?? 0], error: { (code, errorMessage) -> Void in
                if code == 14005 {
                    let alert = NSLocalizedString("The maximum number of labels is 20.").alertController()
                    alert.addOKAction()
                    self.presentViewController(alert, animated: true, completion: nil)
                } else if code == 14002 {
                    let alert = NSLocalizedString("The label name is duplicate").alertController()
                    alert.addOKAction()
                    self.presentViewController(alert, animated: true, completion: nil)
                } else {
                    let alert = errorMessage.alertController()
                    alert.addOKAction()
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                }, complete: { () -> Void in
                    //ok
            })
            
            newLabelInput.text = ""
            tableView.hidden = false;
            isCreateView = false
            collectionView.hidden = true;
            applyButton.setTitle(applyButtonText, forState: UIControlState.Normal)
        } else {
            self.viewModel.apply(archiveMessage)
            self.dismissViewControllerAnimated(true, completion: nil)
            delegate?.dismissed()
        }
    }
    
    @IBAction func cancelAction(sender: AnyObject) {
        performSegueWithIdentifier("toLabelManagerSegue", sender: self)
        
        
        return
        if isCreateView {
            newLabelInput.text = ""
            tableView.hidden = false;
            isCreateView = false
            collectionView.hidden = true;
            applyButton.setTitle(applyButtonText, forState: UIControlState.Normal)
        } else {
            viewModel.cancel();
            self.dismissViewControllerAnimated(true, completion: nil)
            delegate?.dismissed()
        }
    }
    
    private func setupFetchedResultsController() {
        self.fetchedLabels = sharedLabelsDataService.fetchedResultsController()
        self.fetchedLabels?.delegate = self
//        if let fetchedResultsController = fetchedLabels {
//            do {
//                try fetchedResultsController.performFetch()
//            } catch let ex as NSError {
//                PMLog.D("error: \(ex)")
//            }
//        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.fetchedLabels?.delegate = nil
    }
    
    override func viewWillAppear(animated: Bool) {
        
    }
    
    func dismissKeyboard() {
        if (self.newLabelInput != nil) {
            newLabelInput.resignFirstResponder()
        }
    }
    
    @IBAction func startEditing(sender: AnyObject) {
        tableView.hidden = true;
        isCreateView = true
        collectionView.hidden = false;
        applyButton.setTitle("Add", forState: UIControlState.Normal)
    }
    
    @IBAction func endEditing(sender: UITextField) {
        if  sender.text!.isEmpty {
            tableView.hidden = false;
            isCreateView = false
            collectionView.hidden = true;
            applyButton.setTitle(applyButtonText, forState: UIControlState.Normal)
        }
    }
    
    @IBAction func valueChanged(sender: UITextField) {
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
            labelCell.ConfigCell(viewModel.getLabelMessage(label), vc: self)
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
    }
}


extension LablesViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        dismissKeyboard()
        return false
    }
}




extension LablesViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    //    let sectionInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 20
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("labelColorCell", forIndexPath: indexPath)
        let color = titles[indexPath.row]
        cell.backgroundColor = UIColor(hexString: color, alpha: 1.0)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let index = selected {
            let oldCell = collectionView.cellForItemAtIndexPath(index)
            oldCell?.layer.borderWidth = 0
        }
        
        let newCell = collectionView.cellForItemAtIndexPath(indexPath)
        newCell?.layer.borderWidth = 4
        newCell?.layer.borderColor = UIColor.whiteColor().CGColor
        self.selected = indexPath
        
        self.dismissKeyboard()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, 0, 0, 0);
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        return CGSize(width: collectionView.frame.size.width/2, height: 30)
    }
}


// MARK: - NSFetchedResultsControllerDelegate

extension LablesViewController : NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
        // selectMessageIDIfNeeded()
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

