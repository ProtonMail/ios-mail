//
//  LabelManagerViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/1/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation



//protocol LablesViewControllerDelegate {
//    func dismissed()
//    func test()
//}

class LableManagerViewController : UIViewController {
    
    //var viewModel : LabelViewModel!
    
    let titles : [String] = ["#7272a7","#cf5858", "#c26cc7", "#7569d1", "#69a9d1", "#5ec7b7", "#72bb75", "#c3d261", "#e6c04c", "#e6984c", "#8989ac", "#cf7e7e", "#c793ca", "#9b94d1", "#a8c4d5", "#97c9c1", "#9db99f", "#c6cd97", "#e7d292", "#dfb286"]
    
    private var selected : NSIndexPath?
    private var isCreateView: Bool = false
    private var archiveMessage = false;
    
    @IBOutlet weak var backgroundImageView: UIImageView!
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
        inputContentView.layer.cornerRadius = 4;
        inputContentView.layer.borderColor = UIColor(hexColorCode: "#DADEE8").CGColor
        inputContentView.layer.borderWidth = 1.0
        newLabelInput.delegate = self
        
//        titleLabel.text = viewModel.getTitle()

//        applyButtonText = viewModel.getApplyButtonText()
        applyButton.setTitle(applyButtonText, forState: UIControlState.Normal)
//        cancelButton.setTitle(viewModel.getCancelButtonText(), forState: UIControlState.Normal)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    
    @IBAction func applyAction(sender: AnyObject) {
//        if isCreateView {
//            // start
//            viewModel.createLabel(newLabelInput.text!, color: titles[selected?.row ?? 0], error: { (code, errorMessage) -> Void in
//                if code == 14005 {
//                    let alert = NSLocalizedString("The maximum number of labels is 20.").alertController()
//                    alert.addOKAction()
//                    self.presentViewController(alert, animated: true, completion: nil)
//                } else if code == 14002 {
//                    let alert = NSLocalizedString("The label name is duplicate").alertController()
//                    alert.addOKAction()
//                    self.presentViewController(alert, animated: true, completion: nil)
//                } else {
//                    let alert = errorMessage.alertController()
//                    alert.addOKAction()
//                    self.presentViewController(alert, animated: true, completion: nil)
//                }
//                }, complete: { () -> Void in
//                    //ok
//            })
//            
//            newLabelInput.text = ""
//            tableView.hidden = false;
//            isCreateView = false
//            collectionView.hidden = true;
//            applyButton.setTitle(applyButtonText, forState: UIControlState.Normal)
//        } else {
//            self.viewModel.apply(archiveMessage)
//            self.dismissViewControllerAnimated(true, completion: nil)
//            delegate?.dismissed()
//        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let popup = segue.destinationViewController as! LablesViewController
        popup.viewModel = LabelViewModelImpl(msg: [])
    }
    
    @IBAction func cancelAction(sender: AnyObject) {
//        if isCreateView {
//            newLabelInput.text = ""
//            isCreateView = false
//            collectionView.hidden = true;
//            applyButton.setTitle(applyButtonText, forState: UIControlState.Normal)
//        } else {
//            viewModel.cancel();
//            self.dismissViewControllerAnimated(true, completion: nil)
//            delegate?.dismissed()
//        }
        self.dismissViewControllerAnimated(true, completion: nil)
        delegate?.dismissed()
    }
    
    override func viewWillAppear(animated: Bool) {
        
    }
    
    func dismissKeyboard() {
        if (self.newLabelInput != nil) {
            newLabelInput.resignFirstResponder()
        }
    }
    
    @IBAction func startEditing(sender: AnyObject) {
        isCreateView = true
        collectionView.hidden = false;
        applyButton.setTitle("Add", forState: UIControlState.Normal)
    }
    
    @IBAction func endEditing(sender: UITextField) {
        if  sender.text!.isEmpty {
            isCreateView = false
            collectionView.hidden = false;
            applyButton.setTitle(applyButtonText, forState: UIControlState.Normal)
        }
    }
    
    @IBAction func valueChanged(sender: UITextField) {
    }
}

extension LableManagerViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        dismissKeyboard()
        return false
    }
}


// MARK: UICollectionViewDataSource
extension LableManagerViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

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
        cell.layer.cornerRadius = 17;
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

