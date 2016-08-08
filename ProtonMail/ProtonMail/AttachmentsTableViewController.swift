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

public enum AttachmentSections: Int {
    case Normal = 1
    case Inline = 2
    
    public var actionTitle : String {
        get {
            switch(self) {
            case Normal:
                return NSLocalizedString("normal attachments")
            case Inline:
                return NSLocalizedString("inline attachments")
            }
        }
    }
}

class AttachmentsTableViewController: UITableViewController {
    private let kDefaultAttachmentFileSize : Int = 25 * 1000 * 1000
    
    private var currentAttachmentSize : Int = 0
    
    var attachments: [Attachment] = [] {
        didSet {
            buildAttachments()
            tableView?.reloadData()
        }
    }
    
    var normalAttachments: [Attachment] = []
    
    var inlineAttachments: [Attachment] = []
    
    var attachmentSections : [AttachmentSections] = []
    
    func buildAttachments () {
        normalAttachments.removeAll()
        inlineAttachments.removeAll()
        for att in attachments {
            if att.isInline() {
                inlineAttachments.append(att)
            } else {
                normalAttachments.append(att)
            }
        }
        attachmentSections.removeAll()
        
        if normalAttachments.count > 0 {
            attachmentSections.append(.Normal)
        }
        
        if inlineAttachments.count > 0 {
            attachmentSections.append(.Inline)
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
            picker.mediaTypes = [kUTTypeMovie as String, kUTTypeVideo as String, kUTTypeImage as String]
            
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
                kUTTypeMovie as String,
                kUTTypeImage as String,
                kUTTypeText as String,
                kUTTypePDF as String,
                kUTTypeGNUZipArchive as String,
                kUTTypeBzip2Archive as String,
                kUTTypeZipArchive as String,
            ]
            let importMenu = UIDocumentMenuViewController(documentTypes: types, inMode: .Import)
            importMenu.delegate = self
            importMenu.popoverPresentationController?.barButtonItem = sender
            importMenu.popoverPresentationController?.sourceRect = self.view.frame
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
        
        return attachmentSections.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = attachmentSections[section]
        switch section {
        case .Normal:
            return normalAttachments.count
        case .Inline:
            return inlineAttachments.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(AttachmentTableViewCell.Constant.identifier, forIndexPath: indexPath) as! AttachmentTableViewCell
        
        let section = attachmentSections[indexPath.section]
        var attachment : Attachment?
        switch section {
        case .Normal:
            attachment = normalAttachments[indexPath.row] as Attachment
            
        case .Inline:
            attachment = inlineAttachments[indexPath.row] as Attachment
        }
        
        if let att = attachment {
            PMLog.D("\(att)")
            PMLog.D("\(att.fileName)")
            cell.configCell(att.fileName ?? "unknow file", fileSize:  Int(att.fileSize ?? 0), showDownload: false)
            
            let crossView = UILabel();
            crossView.text = NSLocalizedString("Remove")
            crossView.sizeToFit()
            crossView.textColor = UIColor.whiteColor()
            cell.defaultColor = UIColor.lightGrayColor()
            cell.setSwipeGestureWithView(crossView, color: UIColor.ProtonMail.MessageActionTintColor, mode: MCSwipeTableViewCellMode.Exit, state: MCSwipeTableViewCellState.State3  ) { (cell, state, mode) -> Void in
                if let indexp = self.tableView.indexPathForCell(cell) {
                    let section = self.attachmentSections[indexp.section]
                    var cellAtt : Attachment?
                    switch section {
                    case .Normal:
                        cellAtt = self.normalAttachments[indexp.row] as Attachment
                    case .Inline:
                        cellAtt = self.inlineAttachments[indexp.row] as Attachment
                    }
                    
                    if let att = cellAtt {
                        if att.attachmentID != "0" {
                            self.delegate?.attachments(self, didDeletedAttachment: att)
                            if let index = self.attachments.indexOf(att) {
                                self.attachments.removeAtIndex(index)
                            }
                            
                            self.buildAttachments()
                            self.tableView.reloadData()
                        } else {
                            cell.swipeToOriginWithCompletion(nil)
                        }
                    } else {
                        cell.swipeToOriginWithCompletion(nil)
                    }
                } else {
                    
                    self.buildAttachments()
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
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = attachmentSections[section]
        return section.actionTitle
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = UIFont.systemFontOfSize(12)
        header.textLabel?.textColor = UIColor.grayColor()
    }
}

extension AttachmentsTableViewController : UIDocumentMenuDelegate {
    
    func documentMenu(documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.FormSheet
        self.presentViewController(documentPicker, animated: true, completion: nil)
    }
}

extension AttachmentsTableViewController: UIDocumentPickerDelegate {
    
    func documentPicker(controller: UIDocumentPickerViewController, didPickDocumentAtURL url: NSURL) {
        let coordinator : NSFileCoordinator = NSFileCoordinator(filePresenter: nil)
        var error : NSError?
        coordinator.coordinateReadingItemAtURL(url, options: NSFileCoordinatorReadingOptions(), error: &error) { (new_url) -> Void in
            if let data = NSData(contentsOfURL: url) {
                if data.length <= ( self.kDefaultAttachmentFileSize - self.currentAttachmentSize ) {
                    let fileName = url.lastPathComponent ?? "\(NSUUID().UUIDString)"
                    let attachment = data.toAttachment(self.message, fileName: fileName, type: "application/binary")
                    self.attachments.append(attachment!)
                    self.delegate?.attachments(self, didPickedAttachment: attachment!)
                    self.updateAttachmentSize()
                    self.buildAttachments()
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
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let url = info[UIImagePickerControllerReferenceURL] as? NSURL {
            let library = ALAssetsLibrary()
            library.assetForURL(url, resultBlock:
                { (asset: ALAsset!) -> Void in
                    let rep = asset.defaultRepresentation()
                    let length = Int(rep.size())
                    if length <= ( self.kDefaultAttachmentFileSize - self.currentAttachmentSize ) {
                        var error: NSError?
                        let from = Int64(0)
                        let data = NSMutableData(length: length)!
                        let numRead = rep.getBytes(UnsafeMutablePointer(data.mutableBytes), fromOffset: from, length: length, error: &error)
                        
                        dispatch_async(dispatch_get_main_queue()) {
                           picker.dismissViewControllerAnimated(true, completion: nil)
                        }
                            
                        if let er = error {
                            self.showErrorAlert("Can't copy the file")
                            self.delegate?.attachments(self, error:"Can't copy the file")
                            PMLog.D(" Error during copying \(er)")
                        } else {
                            if numRead > 0 {
                                let fileName = rep.filename()
                                let mimeType = rep.UTI()
                                if self.message.managedObjectContext != nil {
                                    let attachment = data.toAttachment(self.message, fileName: fileName, type: mimeType)
                                    self.attachments.append(attachment!)
                                    self.delegate?.attachments(self, didPickedAttachment: attachment!)
                                } else {
                                    PMLog.D(" Error during copying size incorrect")
                                    self.showErrorAlert("Can't copy the file")
                                    self.delegate?.attachments(self, error:"Can't copy the file")
                                }
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
                    
                    self.buildAttachments()
                    self.tableView.reloadData()
            })  { (error:NSError!) -> Void in
                picker.dismissViewControllerAnimated(true, completion: nil)
                self.showErrorAlert("Can't copy the file")
                self.delegate?.attachments(self, error:"Can't copy the file")
                PMLog.D(" Error during open file \(error)")
                
                self.buildAttachments()
                self.tableView.reloadData()
            }
        }else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            picker.dismissViewControllerAnimated(true, completion: nil)
            //let type = info[UIImagePickerControllerMediaType] as? String
            //let url = info[UIImagePickerControllerReferenceURL] as? NSURL
            let fileName = "\(NSUUID().UUIDString).PNG"
            let mimeType = "image/png"
            let attachment = originalImage.toAttachment(self.message, fileName: fileName, type: mimeType)
            self.attachments.append(attachment!)
            self.delegate?.attachments(self, didPickedAttachment: attachment!)
            
            self.buildAttachments()
            self.tableView.reloadData()
        } else {
            picker.dismissViewControllerAnimated(true, completion: nil)
            self.showErrorAlert("Can't copy the file")
            self.delegate?.attachments(self, error:"Can't copy the file")
            //PMLog.D(" Error during open file \(error)")
            
            self.buildAttachments()
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

