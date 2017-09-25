//
//  AttachmentsTableViewController.swift
//
//
//  Created by Yanfeng Zhang on 10/16/15.
//
//

import UIKit
import AssetsLibrary
import Photos

protocol AttachmentsTableViewControllerDelegate {
    
    func attachments(_ attViewController: AttachmentsTableViewController, didFinishPickingAttachments: [Any]) -> Void
    
    func attachments(_ attViewController: AttachmentsTableViewController, didPickedAttachment: Attachment) -> Void
    
    func attachments(_ attViewController: AttachmentsTableViewController, didDeletedAttachment: Attachment) -> Void
    
    func attachments(_ attViewController: AttachmentsTableViewController, didReachedSizeLimitation: Int) -> Void
    
    func attachments(_ attViewController: AttachmentsTableViewController, error: String) -> Void
}

public enum AttachmentSections: Int {
    case normal = 1
    case inline = 2
    
    public var actionTitle : String {
        get {
            switch(self) {
            case .normal:
                return NSLocalizedString("normal attachments", comment: "Title")
            case .inline:
                return NSLocalizedString("inline attachments", comment: "Title")
            }
        }
    }
}

class AttachmentsTableViewController: UITableViewController {
    fileprivate let kDefaultAttachmentFileSize : Int = 25 * 1000 * 1000
    
    fileprivate var currentAttachmentSize : Int = 0
    
    
    fileprivate var doneButton: UIBarButtonItem!
    
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
            attachmentSections.append(.normal)
        }
        
        if inlineAttachments.count > 0 {
            attachmentSections.append(.inline)
        }
    }
    
    var message: Message!
    
    var delegate: AttachmentsTableViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.doneButton = UIBarButtonItem(title:NSLocalizedString("Done", comment: "Action"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(AttachmentsTableViewController.doneAction(_:)))
        self.navigationItem.leftBarButtonItem = doneButton
        
        self.tableView.register(UINib(nibName: "AttachmentTableViewCell", bundle: nil), forCellReuseIdentifier: AttachmentTableViewCell.Constant.identifier)
        self.tableView.separatorStyle = .none
        
        if let navigationController = navigationController {
            configureNavigationBar(navigationController)
            setNeedsStatusBarAppearanceUpdate()
        }
        
        self.clearsSelectionOnViewWillAppear = false
    }
    
    func configureNavigationBar(_ navigationController: UINavigationController) {
        navigationController.navigationBar.barStyle = UIBarStyle.black
        navigationController.navigationBar.barTintColor = UIColor.ProtonMail.Nav_Bar_Background;
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.tintColor = UIColor.white
        
        let navigationBarTitleFont = UIFont.robotoLight(size: UIFont.Size.h2)
        navigationController.navigationBar.titleTextAttributes = [
            NSAttributedStringKey.foregroundColor: UIColor.white,
            NSAttributedStringKey.font: navigationBarTitleFont
        ]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.updateAttachmentSize()
    }
    
    override var shouldAutorotate : Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    internal func updateAttachmentSize () {
        self.currentAttachmentSize = 0
        for att in attachments {
            let fileSize = att.fileSize.intValue
            if fileSize > 0 {
                self.currentAttachmentSize =  self.currentAttachmentSize + fileSize
            }
        }
    }
    
    @IBAction func doneAction(_ sender: AnyObject) {
        self.delegate?.attachments(self, didFinishPickingAttachments: attachments)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addAction(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Photo Library", comment: "Title"), style: UIAlertActionStyle.default, handler: { (action) -> Void in
            let picker: UIImagePickerController = PMImagePickerController()
            picker.delegate = self
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            picker.mediaTypes = [kUTTypeMovie as String, kUTTypeVideo as String, kUTTypeImage as String]
            
            self.present(picker, animated: true, completion: nil)
        }))
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Take a Photo", comment: "Title"), style: UIAlertActionStyle.default, handler: { (action) -> Void in
            if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
                let picker: UIImagePickerController = UIImagePickerController()
                picker.delegate = self
                picker.sourceType = UIImagePickerControllerSourceType.camera
                self.present(picker, animated: true, completion: nil)
            }
        }))
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Import File From...", comment: "Title"), style: UIAlertActionStyle.default, handler: { (action) -> Void in
            let types = [
                kUTTypeMovie as String,
                kUTTypeImage as String,
                kUTTypeText as String,
                kUTTypePDF as String,
                kUTTypeGNUZipArchive as String,
                kUTTypeBzip2Archive as String,
                kUTTypeZipArchive as String,
                kUTTypeData as String
//                "rar",
//                "RAR"
            ]
            let importMenu = UIDocumentMenuViewController(documentTypes: types, in: .import)
            importMenu.delegate = self
            importMenu.popoverPresentationController?.barButtonItem = sender
            importMenu.popoverPresentationController?.sourceRect = self.view.frame
            // importMenu.addOptionWithTitle("Create New Document", image: nil, order: .First, handler: { println("New Doc Requested") })
            self.present(importMenu, animated: true, completion: nil)
        }))
        
        alertController.popoverPresentationController?.barButtonItem = sender
        alertController.popoverPresentationController?.sourceRect = self.view.frame
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Action"), style: UIAlertActionStyle.cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func showSizeErrorAlert( _ didReachedSizeLimitation: Int) {
        //TODO::Fix later
//        let alert = NSLocalizedString("The total attachment size can't be bigger than 25MB", comment: "Description").alertController()
//        alert.addOKAction()
//        present(alert, animated: true, completion: nil)
    }
    
    func showErrorAlert( _ error: String) {
        //TODO::Fix later
//        let alert = NSLocalizedString(error, comment: "").alertController()
//        alert.addOKAction()
//        present(alert, animated: true, completion: nil)
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return attachmentSections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = attachmentSections[section]
        switch section {
        case .normal:
            return normalAttachments.count
        case .inline:
            return inlineAttachments.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AttachmentTableViewCell.Constant.identifier, for: indexPath) as! AttachmentTableViewCell
        
        let section = attachmentSections[indexPath.section]
        var attachment : Attachment?
        switch section {
        case .normal:
            attachment = normalAttachments[indexPath.row] as Attachment
            
        case .inline:
            attachment = inlineAttachments[indexPath.row] as Attachment
        }
        
        if let att = attachment {
            cell.configCell(att.fileName, fileSize:  Int(att.fileSize), showDownload: false)
            let crossView = UILabel();
            crossView.text = NSLocalizedString("Remove", comment: "Action")
            crossView.sizeToFit()
            crossView.textColor = UIColor.white
            cell.defaultColor = UIColor.lightGray
            cell.setSwipeGestureWith(crossView, color: UIColor.ProtonMail.MessageActionTintColor, mode: MCSwipeTableViewCellMode.exit, state: MCSwipeTableViewCellState.state3  ) { (cell, state, mode) -> Void in
                if let indexp = self.tableView.indexPath(for: cell!) {
                    let section = self.attachmentSections[indexp.section]
                    var cellAtt : Attachment?
                    switch section {
                    case .normal:
                        cellAtt = self.normalAttachments[indexp.row] as Attachment
                    case .inline:
                        cellAtt = self.inlineAttachments[indexp.row] as Attachment
                    }
                    
                    if let att = cellAtt {
                        if att.attachmentID != "0" {
                            self.delegate?.attachments(self, didDeletedAttachment: att)
                            if let index = self.attachments.index(of: att) {
                                self.attachments.remove(at: index)
                            }
                            
                            self.buildAttachments()
                            self.tableView.reloadData()
                        } else {
                            cell?.swipeToOrigin(completion: nil)
                        }
                    } else {
                        cell?.swipeToOrigin(completion: nil)
                    }
                } else {
                    
                    self.buildAttachments()
                    self.tableView.reloadData()
                }
            }
        }
        
        cell.selectionStyle = .none;
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44;
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = attachmentSections[section]
        return section.actionTitle
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = UIFont.systemFont(ofSize: 12)
        header.textLabel?.textColor = UIColor.gray
    }
}

extension AttachmentsTableViewController : UIDocumentMenuDelegate {
    
    func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.formSheet
        self.present(documentPicker, animated: true, completion: nil)
    }
}

extension AttachmentsTableViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let coordinator : NSFileCoordinator = NSFileCoordinator(filePresenter: nil)
        var error : NSError?
        coordinator.coordinate(readingItemAt: url, options: NSFileCoordinator.ReadingOptions(), error: &error) { (new_url) -> Void in
            if let data = try? Data(contentsOf: url) {
                DispatchQueue.main.async {
                    if data.count <= ( self.kDefaultAttachmentFileSize - self.currentAttachmentSize ) {
                        let ext = url.mimeType()
                        let fileName = url.lastPathComponent
                        let attachment = data.toAttachment(self.message, fileName: fileName, type: ext)
                        self.attachments.append(attachment!)
                        self.delegate?.attachments(self, didPickedAttachment: attachment!)
                        self.updateAttachmentSize()
                        self.buildAttachments()
                        self.tableView.reloadData()
                    } else {
                        self.showSizeErrorAlert(0)
                        self.delegate?.attachments(self, didReachedSizeLimitation:0)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.showErrorAlert(NSLocalizedString("Can't load the file", comment: "Error"))
                    self.delegate?.attachments(self, error: NSLocalizedString("Can't load the file", comment: "Error"))
                }
            }
        }
        if error != nil {
            DispatchQueue.main.async {
                self.showErrorAlert(NSLocalizedString("Can't copy the file", comment: "Error"))
                self.delegate?.attachments(self, error: NSLocalizedString("Can't copy the file", comment: "Error"))
            }
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        PMLog.D("")
    }
    
}

extension AttachmentsTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let url = info[UIImagePickerControllerReferenceURL] as? NSURL, let asset = PHAsset.fetchAssets(withALAssetURLs: [url as URL], options: nil).firstObject {
            if asset.mediaType == .video {
                let options = PHVideoRequestOptions()
                PHImageManager.default().requestAVAsset(forVideo: asset, options: options, resultHandler: { (asset: AVAsset?, audioMix: AVAudioMix?, info:[AnyHashable : Any]?) in
                    
                    if let error = info?[PHImageErrorKey] as? NSError {
                        DispatchQueue.main.async() {
                            picker.dismiss(animated: true, completion: nil)
                            self.showErrorAlert(error.debugDescription)
                            self.delegate?.attachments(self, error:error.debugDescription)
                        }
                        return
                    }
                    guard let asset = asset as? AVURLAsset, let image_data = try? Data(contentsOf: asset.url), let info = info, image_data.count > 0 else {
                        DispatchQueue.main.async() {
                            picker.dismiss(animated: true, completion: nil)
                            self.showSizeErrorAlert(0)
                            self.delegate?.attachments(self, didReachedSizeLimitation:0)
                        }
                        return
                    }
                    
                    let video_url = asset.url;
                    var fileName = "\(NSUUID().uuidString).mp4"
                    let url_filename = video_url.lastPathComponent
                    fileName = url_filename
                    
                    let uti = fileName.mimeType()
                    let length = image_data.count
                    if length <= ( self.kDefaultAttachmentFileSize - self.currentAttachmentSize ) {
                        DispatchQueue.main.async() {
                            picker.dismiss(animated: true, completion: nil)
                            if self.message.managedObjectContext != nil {
                                let attachment = image_data.toAttachment(self.message, fileName: fileName, type: uti)
                                self.attachments.append(attachment!)
                                self.delegate?.attachments(self, didPickedAttachment: attachment!)
                            } else {
                                PMLog.D(" Error during copying size incorrect")
                                self.showErrorAlert(NSLocalizedString("System can't copy the file", comment: "Error"))
                                self.delegate?.attachments(self, error: NSLocalizedString("System can't copy the file", comment: "Error"))
                            }
                        }
                    } else {
                        DispatchQueue.main.async() {
                            picker.dismiss(animated: true, completion: nil)
                            self.showSizeErrorAlert(0)
                            self.delegate?.attachments(self, didReachedSizeLimitation:0)
                            PMLog.D(" Size too big Orig: \(length) -- Limit: \(self.kDefaultAttachmentFileSize)")
                        }
                    }
                
                })
            }
            else {
                let options = PHImageRequestOptions()
                PHImageManager.default().requestImageData(for: asset, options: options, resultHandler: { (imagedata: Data?, dataUTI: String?, orientation: UIImageOrientation, info:[AnyHashable : Any]?) in
                    defer {
                        DispatchQueue.main.async() {
                            self.buildAttachments()
                            self.tableView.reloadData()
                        }
                    }
                    guard let image_data = imagedata, /* let _ = dataUTI,*/ let info = info, image_data.count > 0 else {
                        DispatchQueue.main.async() {
                            picker.dismiss(animated: true, completion: nil)
                            self.showErrorAlert(NSLocalizedString("Can't open the file", comment: "Error"))
                            self.delegate?.attachments(self, error: NSLocalizedString("Can't open the file", comment: "Error"))
                        }
                        return
                    }
                    var fileName = "\(NSUUID().uuidString).jpg"
                    if let url = info["PHImageFileURLKey"] as? NSURL, let url_filename = url.lastPathComponent {
                        fileName = url_filename
                    }
                    let uti = fileName.mimeType()
                    let length = image_data.count
                    if length <= ( self.kDefaultAttachmentFileSize - self.currentAttachmentSize ) {
                        DispatchQueue.main.async() {
                            picker.dismiss(animated: true, completion: nil)
                            if self.message.managedObjectContext != nil {
                                let attachment = image_data.toAttachment(self.message, fileName: fileName, type: uti)
                                self.attachments.append(attachment!)
                                self.delegate?.attachments(self, didPickedAttachment: attachment!)
                            } else {
                                PMLog.D(" Error during copying size incorrect")
                                self.showErrorAlert(NSLocalizedString("Can't copy the file", comment: "Error"))
                                self.delegate?.attachments(self, error: NSLocalizedString("Can't copy the file", comment: "Error"))
                            }
                        }
                    } else {
                        DispatchQueue.main.async() {
                            picker.dismiss(animated: true, completion: nil)
                            self.showSizeErrorAlert(0)
                            self.delegate?.attachments(self, didReachedSizeLimitation:0)
                            PMLog.D(" Size too big Orig: \(length) -- Limit: \(self.kDefaultAttachmentFileSize)")
                        }
                    }
                })
            }
        } else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {//edge case here, may never go here
            picker.dismiss(animated: true, completion: nil)
            let fileName = "\(NSUUID().uuidString).PNG"
            let mimeType = "image/png"
            let attachment = originalImage.toAttachment(self.message, fileName: fileName, type: mimeType)
            let length = attachment?.fileSize.intValue ?? 0
            if length <= ( self.kDefaultAttachmentFileSize - self.currentAttachmentSize ) {
                if let att = attachment, self.message.managedObjectContext != nil {
                    self.attachments.append(att)
                    self.delegate?.attachments(self, didPickedAttachment: att)
                } else {
                    PMLog.D(" Error during copying size incorrect")
                    self.showErrorAlert(NSLocalizedString("Can't copy the file", comment: "Error"))
                    self.delegate?.attachments(self, error: NSLocalizedString("Can't copy the file", comment: "Error"))
                }
            } else {
                self.showSizeErrorAlert(0)
                self.delegate?.attachments(self, didReachedSizeLimitation:0)
                PMLog.D(" Size too big Orig: \(length) -- Limit: \(self.kDefaultAttachmentFileSize)")
            }
            self.buildAttachments()
            self.tableView.reloadData()
        } else {
            picker.dismiss(animated: true, completion: nil)
            self.showErrorAlert(NSLocalizedString("Can't copy the file", comment: "Error"))
            self.delegate?.attachments(self, error: NSLocalizedString("Can't copy the file", comment: "Error"))
            self.buildAttachments()
            self.tableView.reloadData()
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        //TODO::Fix later
//        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent, animated: false)
        configureNavigationBar(navigationController)
    }
}

