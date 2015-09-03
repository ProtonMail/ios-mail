//
//  AttachmentsViewController.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation
import AssetsLibrary

protocol AttachmentsViewControllerDelegate {
    func attachmentsViewController(attachmentsViewController: AttachmentsViewController, didFinishPickingAttachments: [AnyObject]) -> Void
    
    func attachmentsViewController(attachmentsViewController: AttachmentsViewController, didPickedAttachment: UIImage, fileName:String, type:String) -> Void
}


class AttachmentsViewController: UICollectionViewController {
    private let attachmentCellIdentifier = "AttachmentCell"
    private let cutSelector: Selector = "cut:"
    private let attachmentIcon = "attached_compose"
    
    var attachments: [AnyObject] = [] {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    var delegate: AttachmentsViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let navigationController = navigationController {
            configureNavigationBar(navigationController)
            setNeedsStatusBarAppearanceUpdate()
        }
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func configureNavigationBar(navigationController: UINavigationController) {
        navigationController.navigationBar.barStyle = UIBarStyle.Black
        navigationController.navigationBar.barTintColor = UIColor.ProtonMail.Blue_475F77
        navigationController.navigationBar.translucent = false
        navigationController.navigationBar.tintColor = UIColor.whiteColor()
        
        let navigationBarTitleFont = UIFont.robotoLight(size: UIFont.Size.h2)
        navigationController.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSFontAttributeName: navigationBarTitleFont
        ]
    }
    
    func attachmentForIndexPath(indexPath: NSIndexPath) -> AnyObject? {
        return attachments[indexPath.row]
    }

    // MARK: - Actions
    
    @IBAction func addAction(sender: AnyObject) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Photo Library"), style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            let picker: UIImagePickerController = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            self.presentViewController(picker, animated: true, completion: nil)
        }))
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Take a Photo"), style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)) {
                let picker: UIImagePickerController = UIImagePickerController()
                picker.delegate = self
                picker.sourceType = UIImagePickerControllerSourceType.Camera
                self.presentViewController(picker, animated: true, completion: nil)
            }
        }))
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: UIAlertActionStyle.Cancel, handler: nil))
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func doneAction(sender: AnyObject) {
        delegate?.attachmentsViewController(self, didFinishPickingAttachments: attachments)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - UICollectionViewDataSource
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(attachmentCellIdentifier, forIndexPath: indexPath) as! AttachmentCollectionViewCell
        
        if let attachment = attachmentForIndexPath(indexPath) as? UIImage {
            cell.imageView.image = attachment
        } else {
            cell.imageView.image = UIImage(named: attachmentIcon)
        }
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return attachments.count
    }
    
    // MARK: - UICollectionViewDelegate
    
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject!) -> Bool {
        return action == cutSelector
    }
    
    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject!) {
        if action == cutSelector {
            attachments.removeAtIndex(indexPath.row)
            collectionView.reloadData()
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension AttachmentsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        
        let tempImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        let type = info[UIImagePickerControllerMediaType] as? String
        let url = info[UIImagePickerControllerReferenceURL] as? NSURL
        let img_jpg = UIImage(data:UIImageJPEGRepresentation(tempImage, 1.0))!
        
        let library = ALAssetsLibrary()
        library.assetForURL(url, resultBlock:
            { (asset: ALAsset!) -> Void in
                if asset != nil {
                    var fileName = asset.defaultRepresentation().filename()
                    let mimeType = asset.defaultRepresentation().UTI()
                    self.attachments.append(img_jpg)
                    self.delegate?.attachmentsViewController(self, didPickedAttachment: img_jpg, fileName: fileName, type: mimeType)
                    picker.dismissViewControllerAnimated(true, completion: nil)
                } else {
                    var fileName = "\(NSUUID().UUIDString).jpg"
                    let mimeType = "image/jpg"
                    self.attachments.append(img_jpg)
                    self.delegate?.attachmentsViewController(self, didPickedAttachment: img_jpg, fileName: fileName, type: mimeType)
                    picker.dismissViewControllerAnimated(true, completion: nil)
                }
            })  { (error:NSError!) -> Void in
                var fileName = "\(NSUUID().UUIDString).jpg"
                let mimeType = "image/jpg"
                self.attachments.append(img_jpg)
                self.delegate?.attachmentsViewController(self, didPickedAttachment: img_jpg, fileName: fileName, type: mimeType)
                picker.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    
//    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
//        //let img_jpg = UIImage(data:UIImageJPEGRepresentation(image, 1.0))!
//        attachments.append(image)
//        delegate?.attachmentsViewController(self, didPickedAttachment: image)
//        //delegate?.attachmentsViewController(self, didFinishPickingAttachments: attachments)
//        picker.dismissViewControllerAnimated(true, completion: nil)
//    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
        configureNavigationBar(navigationController)
    }
}
