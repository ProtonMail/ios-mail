//
//  AttachmentsTableViewController.swift
//
//
//  Created by Yanfeng Zhang on 10/16/15.
//
//

import UIKit
import AssetsLibrary


protocol AttachmentsTableViewControllerDelegate {
    
    func attachments(attViewController: AttachmentsTableViewController, didFinishPickingAttachments: [AnyObject]) -> Void
    
    func attachments(attViewController: AttachmentsTableViewController, didPickedAttachment: Attachment) -> Void
    
    func attachments(attViewController: AttachmentsTableViewController, didDeletedAttachment: Attachment) -> Void
    
    func attachments(attViewController: AttachmentsTableViewController, didReachedSizeLimitation: Int) -> Void
    
    func attachments(attViewController: AttachmentsTableViewController, error: String) -> Void
}


class AttachmentsTableViewController: UITableViewController {
    private let kDefaultAttachmentFileSize : Int = 25 * 1000 * 1000
    
    private var currentAttachmentSize : Int = 0
    
    var attachments: [Attachment] = [] {
        didSet {
            tableView?.reloadData()
        }
    }
    
    var message: Message!
    
    var delegate: AttachmentsTableViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerNib(UINib(nibName: "AttachmentTableViewCell", bundle: nil), forCellReuseIdentifier: AttachmentTableViewCell.Constant.identifier)
        self.tableView.separatorStyle = .None
        
        if let navigationController = navigationController {
            configureNavigationBar(navigationController)
            setNeedsStatusBarAppearanceUpdate()
        }
        
        self.clearsSelectionOnViewWillAppear = false
    }
    
    func configureNavigationBar(navigationController: UINavigationController) {
        navigationController.navigationBar.barStyle = UIBarStyle.Black
        navigationController.navigationBar.barTintColor = UIColor.ProtonMail.Nav_Bar_Background;
        navigationController.navigationBar.translucent = false
        navigationController.navigationBar.tintColor = UIColor.whiteColor()
        
        let navigationBarTitleFont = UIFont.robotoLight(size: UIFont.Size.h2)
        navigationController.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSFontAttributeName: navigationBarTitleFont
        ]
    }
    
    override func viewWillAppear(animated: Bool) {
        self.updateAttachmentSize()
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    internal func updateAttachmentSize () {
        self.currentAttachmentSize = 0
        for att in attachments {
            let fileSize = att.fileSize.integerValue
            if fileSize > 0 {
                self.currentAttachmentSize =  self.currentAttachmentSize + fileSize
            }
        }
    }
    
    @IBAction func doneAction(sender: AnyObject) {
        self.delegate?.attachments(self, didFinishPickingAttachments: attachments)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func addAction(sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Photo Library"), style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            let picker: UIImagePickerController = PMImagePickerController()
            picker.delegate = self
            picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            picker.mediaTypes = [kUTTypeMovie, kUTTypeVideo, kUTTypeImage]
            
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
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Import File From..."), style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            let types = [
                kUTTypeMovie,
                kUTTypeImage,
                kUTTypeText,
                kUTTypePDF,
                kUTTypeGNUZipArchive,
                kUTTypeBzip2Archive,
                kUTTypeZipArchive,
            ]
            let importMenu = UIDocumentMenuViewController(documentTypes: types, inMode: .Import)
            importMenu.delegate = self
            // importMenu.addOptionWithTitle("Create New Document", image: nil, order: .First, handler: { println("New Doc Requested") })
            self.presentViewController(importMenu, animated: true, completion: nil)
        }))
        
        alertController.popoverPresentationController?.barButtonItem = sender
        alertController.popoverPresentationController?.sourceRect = self.view.frame
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: UIAlertActionStyle.Cancel, handler: nil))
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func showSizeErrorAlert( didReachedSizeLimitation: Int) {
        let alert = NSLocalizedString("The total attachment size can't be bigger than 25MB").alertController()
        alert.addOKAction()
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func showErrorAlert( error: String) {
        let alert = NSLocalizedString(error).alertController()
        alert.addOKAction()
        presentViewController(alert, animated: true, completion: nil)
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attachments.count;
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(AttachmentTableViewCell.Constant.identifier, forIndexPath: indexPath) as! AttachmentTableViewCell
        if attachments.count > indexPath.row {
            let att = attachments[indexPath.row] as Attachment
            PMLog.D("\(att)")
            PMLog.D("\(att.fileName)")
            cell.configCell(att.fileName ?? "unknow file", fileSize:  Int(att.fileSize ?? 0), showDownload: false)
            
            let crossView = UILabel();
            crossView.text = "Remove"
            crossView.sizeToFit()
            crossView.textColor = UIColor.whiteColor()
            cell.defaultColor = UIColor.lightGrayColor()
            cell.setSwipeGestureWithView(crossView, color: UIColor.ProtonMail.MessageActionTintColor, mode: MCSwipeTableViewCellMode.Exit, state: MCSwipeTableViewCellState.State3  ) { (cell, state, mode) -> Void in
                if let indexp = self.tableView.indexPathForCell(cell) {
                    if self.attachments.count > indexPath.row {
                        let att = self.attachments[indexPath.row] as Attachment
                        if att.attachmentID != "0" {
                            self.delegate?.attachments(self, didDeletedAttachment: att)
                            self.attachments.removeAtIndex(indexPath.row)
                            self.tableView.reloadData()
                        } else {
                            cell.swipeToOriginWithCompletion(nil)
                        }
                    } else {
                        cell.swipeToOriginWithCompletion(nil)
                    }
                } else {
                    self.tableView.reloadData()
                }
            }
        }
        
        cell.selectionStyle = .None;
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44;
    }
}

extension AttachmentsTableViewController : UIDocumentMenuDelegate {
    
    func documentMenu(documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        let types = [
            kUTTypeMovie,
            kUTTypeImage,
            kUTTypeText,
            kUTTypePDF,
            //                kUTTypeGNUZipArchive,
            //                kUTTypeBzip2Archive,
            //                kUTTypeZipArchive
        ]
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.FormSheet
        self.presentViewController(documentPicker, animated: true, completion: nil)
    }
    
}

extension AttachmentsTableViewController: UIDocumentPickerDelegate {
    
    func documentPicker(controller: UIDocumentPickerViewController, didPickDocumentAtURL url: NSURL) {
        let coordinator : NSFileCoordinator = NSFileCoordinator(filePresenter: nil)
        var error : NSError?
        coordinator.coordinateReadingItemAtURL(url, options: NSFileCoordinatorReadingOptions.allZeros, error: &error) { (new_url) -> Void in
            if let data = NSData(contentsOfURL: url) {
                if data.length <= ( self.kDefaultAttachmentFileSize - self.currentAttachmentSize ) {
                    var fileName = url.lastPathComponent ?? "\(NSUUID().UUIDString)"
                    let attachment = data.toAttachment(self.message, fileName: fileName, type: "application/binary")
                    self.attachments.append(attachment!)
                    self.delegate?.attachments(self, didPickedAttachment: attachment!)
                    self.updateAttachmentSize()
                    self.tableView.reloadData()
                } else {
                    self.showSizeErrorAlert(0)
                    self.delegate?.attachments(self, didReachedSizeLimitation:0)
                }
            } else {
                self.showErrorAlert("Can't load the file")
                self.delegate?.attachments(self, error:"Can't load the file")
            }
        }
        if error != nil {
            self.showErrorAlert("Can't copy the file")
            self.delegate?.attachments(self, error:"Can't copy the file")
        }
    }
    
    func documentPickerWasCancelled(controller: UIDocumentPickerViewController) {
        PMLog.D("")
    }
    
}

extension AttachmentsTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        let url = info[UIImagePickerControllerReferenceURL] as? NSURL
        let library = ALAssetsLibrary()
        library.assetForURL(url, resultBlock:
            { (asset: ALAsset!) -> Void in
                var rep = asset.defaultRepresentation()
                let length = Int(rep.size())
                if length <= ( self.kDefaultAttachmentFileSize - self.currentAttachmentSize ) {
                    var error: NSError?
                    let from = Int64(0)
                    let data = NSMutableData(length: length)!
                    let numRead = rep.getBytes(UnsafeMutablePointer(data.mutableBytes), fromOffset: from, length: length, error: &error)
                    
                    picker.dismissViewControllerAnimated(true, completion: nil)
                    
                    if let er = error {
                        self.showErrorAlert("Can't copy the file")
                        self.delegate?.attachments(self, error:"Can't copy the file")
                        PMLog.D(" Error during copying \(er)")
                    } else {
                        if numRead > 0 {
                            var fileName = rep.filename()
                            let mimeType = rep.UTI()
                            
                            let attachment = data.toAttachment(self.message, fileName: fileName, type: mimeType)
                            self.attachments.append(attachment!)
                            self.delegate?.attachments(self, didPickedAttachment: attachment!)
                        } else {
                            PMLog.D(" Error during copying size incorrect")
                            self.showErrorAlert("Can't copy the file")
                            self.delegate?.attachments(self, error:"Can't copy the file")
                        }
                    }
                    
                } else {
                    picker.dismissViewControllerAnimated(true, completion: nil)
                    self.showSizeErrorAlert(0)
                    self.delegate?.attachments(self, didReachedSizeLimitation:0)
                    PMLog.D(" Size too big Orig: \(length) -- Limit: \(self.kDefaultAttachmentFileSize)")
                }
                self.tableView.reloadData()
            })  { (error:NSError!) -> Void in
                picker.dismissViewControllerAnimated(true, completion: nil)
                self.showErrorAlert("Can't copy the file")
                self.delegate?.attachments(self, error:"Can't copy the file")
                PMLog.D(" Error during open file \(error)")
                self.tableView.reloadData()
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
        configureNavigationBar(navigationController)
    }
}

