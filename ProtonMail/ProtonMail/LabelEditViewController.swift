//
//  LabelManagerViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/1/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation

class LableEditViewController : UIViewController {
    
    var viewModel : LabelEditViewModel!

    
    private var selected : NSIndexPath?
    private var selectedFirstLoad : NSIndexPath?
    
    private var archiveMessage = false;
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var inputContentView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var applyButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var newLabelInput: UITextField!

    var delegate : LablesViewControllerDelegate?
    var applyButtonText : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.layer.cornerRadius = 4;
        newLabelInput.delegate = self
        
        titleLabel.text = viewModel.getTitle()
        newLabelInput.placeholder = viewModel.getPlaceHolder()

        applyButtonText = viewModel.getRightButtonText()
        applyButton.setTitle(applyButtonText, forState: UIControlState.Disabled)
        applyButton.setTitle(applyButtonText, forState: UIControlState.Normal)
        cancelButton.setTitle("Cancel", forState: UIControlState.Normal)
        applyButton.enabled = false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewWillAppear(animated: Bool) {
        newLabelInput.resignFirstResponder()
        selectedFirstLoad = viewModel.getSelectedIndex()
    }
    
    @IBAction func applyAction(sender: AnyObject) {
        // start
        //show loading
        ActivityIndicatorHelper.showActivityIndicatorAtView(view)
        let color = viewModel.getColor(selected?.row ?? 0)
        viewModel.createLabel(newLabelInput.text!, color: color, error: { (code, errorMessage) -> Void in
            ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
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
                self.dismissViewControllerAnimated(true, completion: nil)
                self.delegate?.dismissed()
        })
    }
    
    @IBAction func cancelAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        delegate?.dismissed()
    }
    
    func dismissKeyboard() {
        if (self.newLabelInput != nil) {
            newLabelInput.resignFirstResponder()
        }
    }
}

extension LableEditViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        dismissKeyboard()
        return false
    }
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text! as NSString
        let changedText = text.stringByReplacingCharactersInRange(range, withString: string)
        if changedText.isEmpty {
            applyButton.enabled = false
        } else {
            applyButton.enabled = true
        }
        return true
    }
}

// MARK: UICollectionViewDataSource
extension LableEditViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.getColorCount()
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("labelColorCell", forIndexPath: indexPath)
        let color = viewModel.getColor(indexPath.row)
        cell.backgroundColor = UIColor(hexString: color, alpha: 1.0)
        cell.layer.cornerRadius = 17;
        
        if selected == nil {
            if indexPath.row == selectedFirstLoad?.row {
                cell.layer.borderWidth = 4
                cell.layer.borderColor = UIColor.darkGrayColor().CGColor
                self.selected = indexPath
            }
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let index = selected {
            let oldCell = collectionView.cellForItemAtIndexPath(index)
            oldCell?.layer.borderWidth = 0
        }
        
        let newCell = collectionView.cellForItemAtIndexPath(indexPath)
        newCell?.layer.borderWidth = 4
        newCell?.layer.borderColor = UIColor.darkGrayColor().CGColor
        self.selected = indexPath
        
        self.dismissKeyboard()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0,0,0,0);
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        return CGSize(width: 34, height: 34)
    }
}

