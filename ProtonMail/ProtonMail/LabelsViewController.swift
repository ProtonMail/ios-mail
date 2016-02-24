//
//  LabelsViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

protocol LablesViewControllerDelegate {
    func dismissed();
}

class LablesViewController : UIViewController {
    
    var viewModel : LabelViewModel!
    
    let titles : [String] = ["#7272a7","#cf5858", "#c26cc7", "#7569d1", "#69a9d1", "#5ec7b7", "#72bb75", "#c3d261", "#e6c04c", "#e6984c", "#8989ac", "#cf7e7e", "#c793ca", "#9b94d1", "#a8c4d5", "#97c9c1", "#9db99f", "#c6cd97", "#e7d292", "#dfb286"]
    
    private var selected : NSIndexPath?
    private var isCreateView: Bool = false
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
    
    private var archiveMessage = false;
    
    var delegate : LablesViewControllerDelegate?

    //
    private var fetchedLabels: NSFetchedResultsController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.layer.cornerRadius = 4;
        inputContentView.layer.cornerRadius = 4;
        inputContentView.layer.borderColor = UIColor(hexColorCode: "#DADEE8").CGColor!
        inputContentView.layer.borderWidth = 1.0
        self.setupFetchedResultsController()
        //var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        // self.view.addGestureRecognizer(tapGestureRecognizer)
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
            viewModel.createLabel(newLabelInput.text, color: titles[selected?.row ?? 0], error: { (code, errorMessage) -> Void in
                if code == 14005 {
                    var alert = "The maximum number of labels is 20.".alertController()
                    alert.addOKAction()
                    self.presentViewController(alert, animated: true, completion: nil)
                } else if code == 14002 {
                    var alert = "The label name is duplicate".alertController()
                    alert.addOKAction()
                    self.presentViewController(alert, animated: true, completion: nil)
                } else {
                    var alert = errorMessage.alertController()
                    alert.addOKAction()
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                }, complete: { () -> Void in
                    //ok
            })
            
            //viewModel.createLabel(newLabelInput.text, titles[selected!.row], error)
            // viewModel.createLabel() {
            newLabelInput.text = ""
            tableView.hidden = false;
            isCreateView = false
            collectionView.hidden = true;
            applyButton.setTitle("Apply", forState: UIControlState.Normal)
            //            } else {
            //
            //                // show alert
            //            }
        } else {
            self.viewModel.apply(archiveMessage)
            self.dismissViewControllerAnimated(true, completion: nil)
            delegate?.dismissed()
        }
    }
    
    @IBAction func cancelAction(sender: AnyObject) {
        if isCreateView {
            newLabelInput.text = ""
            tableView.hidden = false;
            isCreateView = false
            collectionView.hidden = true;
            applyButton.setTitle("Apply", forState: UIControlState.Normal)
        } else {
            viewModel.cancel();
            self.dismissViewControllerAnimated(true, completion: nil)
            delegate?.dismissed()
        }
    }
    
    private func setupFetchedResultsController() {
        self.fetchedLabels = sharedLabelsDataService.fetchedResultsController()
        self.fetchedLabels?.delegate = self
        if let fetchedResultsController = fetchedLabels {
            var error: NSError?
            if !fetchedResultsController.performFetch(&error) {
                NSLog("\(__FUNCTION__) error: \(error)")
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.fetchedLabels?.delegate = nil
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
        if sender.text.isEmpty {
            tableView.hidden = false;
            isCreateView = false
            collectionView.hidden = true;
            applyButton.setTitle("Apply", forState: UIControlState.Normal)
        }
    }
    
    @IBAction func valueChanged(sender: UITextField) {
    }
}

// MARK: - UITableViewDataSource

extension LablesViewController: UITableViewDataSource {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if (self.tableView.respondsToSelector("setSeparatorInset:")) {
            self.tableView.separatorInset = UIEdgeInsetsZero
        }
        
        if (self.tableView.respondsToSelector("setLayoutMargins:")) {
            self.tableView.layoutMargins = UIEdgeInsetsZero
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var labelCell = tableView.dequeueReusableCellWithIdentifier("labelApplyCell", forIndexPath: indexPath) as! LabelTableViewCell
        if let label = fetchedLabels?.objectAtIndexPath(indexPath) as? Label {
            labelCell.ConfigCell(viewModel.getLabelMessage(label), vc: self)
        }
        return labelCell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == .Delete) {
            // deleteMessageForIndexPath(indexPath)
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = fetchedLabels?.numberOfRowsInSection(section) ?? 0
        return count
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if (cell.respondsToSelector("setSeparatorInset:")) {
            cell.separatorInset = UIEdgeInsetsZero
        }
        
        if (cell.respondsToSelector("setLayoutMargins:")) {
            cell.layoutMargins = UIEdgeInsetsZero
        }
        
        //fetchMessagesIfNeededForIndexPath(indexPath)
    }
}

// MARK: - UITableViewDelegate

extension LablesViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 45.0
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let trashed: UITableViewRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: title) { (rowAction, indexPath) -> Void in
            //self.deleteMessageForIndexPath(indexPath)
        }
        trashed.backgroundColor = UIColor.ProtonMail.Red_D74B4B
        return [trashed]
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // verify whether the user is checking messages or not
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
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("labelColorCell", forIndexPath: indexPath) as! UICollectionViewCell
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
            if let indexPath = indexPath {
                //if let cell = tableView.cellForRowAtIndexPath(indexPath) as? MailboxTableViewCell {
                //configureCell(cell, atIndexPath: indexPath)
                //}
            }
        default:
            return
        }
    }
}

