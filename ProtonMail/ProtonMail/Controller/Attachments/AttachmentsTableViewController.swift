//
//  AttachmentsTableViewController.swift
//
//
//  Created by Yanfeng Zhang on 10/16/15.
//
//

import UIKit
import Photos
import AssetsLibrary
import MCSwipeTableViewCell

protocol AttachmentsTableViewControllerDelegate {
    func attachments(_ attViewController: AttachmentsTableViewController, didFinishPickingAttachments: [Any]) -> Void
    func attachments(_ attViewController: AttachmentsTableViewController, didPickedAttachment: Attachment) -> Void
    func attachments(_ attViewController: AttachmentsTableViewController, didDeletedAttachment: Attachment) -> Void
    func attachments(_ attViewController: AttachmentsTableViewController, didReachedSizeLimitation: Int) -> Void
    func attachments(_ attViewController: AttachmentsTableViewController, error: String) -> Void
}

public enum AttachmentSections: Int {
    case normal = 1, inline
    
    public var actionTitle : String {
        get {
            switch(self) {
            case .normal: return LocalString._normal_attachments
            case .inline: return LocalString._inline_attachments
            }
        }
    }
}

class AttachmentsTableViewController: UITableViewController, AttachmentController {
    internal let kDefaultAttachmentFileSize : Int = 25 * 1000 * 1000
    internal var currentAttachmentSize : Int = 0
    
    fileprivate var doneButton: UIBarButtonItem!

    var message: Message!
    var delegate: AttachmentsTableViewControllerDelegate?
    
    var normalAttachments: [Attachment] = []
    var inlineAttachments: [Attachment] = []
    var attachmentSections : [AttachmentSections] = []

    var attachments: [Attachment] = [] {
        didSet {
            self.buildAttachments()
            self.updateAttachmentSize()
            self.tableView?.reloadData()
        }
    }
    
    lazy var attachmentProviders: Array<AttachmentProvider> = {
        // There is no access to camera in AppExtensions, so should not include it into menu
        #if APP_EXTENSION
            return [PhotoAttachmentProvider(for: self),
                    DocumentAttachmentProvider(for: self)]
        #else
            return [PhotoAttachmentProvider(for: self),
                    CameraAttachmentProvider(for: self),
                    DocumentAttachmentProvider(for: self)]
        #endif
    }()
    
    func buildAttachments() {
        normalAttachments = attachments.filter { !$0.inline() }
        inlineAttachments = attachments.filter { $0.inline() }

        attachmentSections.removeAll()
        if !normalAttachments.isEmpty {
            attachmentSections.append(.normal)
        }
        if !inlineAttachments.isEmpty {
            attachmentSections.append(.inline)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.doneButton = UIBarButtonItem(title: LocalString._general_done_button, style: UIBarButtonItemStyle.plain, target: self, action: #selector(AttachmentsTableViewController.doneAction(_:)))
        self.navigationItem.leftBarButtonItem = doneButton
        
        self.tableView.register(UINib(nibName: "\(AttachmentTableViewCell.self)", bundle: nil),
                                forCellReuseIdentifier: AttachmentTableViewCell.Constant.identifier)
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
        
        let navigationBarTitleFont = Fonts.h2.light
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

    internal func updateAttachmentSize () {
        self.currentAttachmentSize = self.attachments.reduce(into: 0) {
            $0 += $1.fileSize.intValue
        }
    }
    
    @IBAction func doneAction(_ sender: AnyObject) {
        self.delegate?.attachments(self, didFinishPickingAttachments: attachments)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addAction(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.barButtonItem = sender
        alertController.popoverPresentationController?.sourceRect = self.view.frame
        
        self.attachmentProviders.map{ $0.alertAction }.forEach(alertController.addAction)
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: UIAlertActionStyle.cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func showSizeErrorAlert( _ didReachedSizeLimitation: Int) {
        self.showErrorAlert(LocalString._the_total_attachment_size_cant_be_bigger_than_25mb)
    }
    
    func showErrorAlert( _ error: String) {
        let alert = NSLocalizedString(error, comment: "").alertController()
        alert.addOKAction()
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return attachmentSections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch attachmentSections[section] {
        case .normal: return normalAttachments.count
        case .inline: return inlineAttachments.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AttachmentTableViewCell.Constant.identifier, for: indexPath) as! AttachmentTableViewCell

        var attachment: Attachment?
        switch attachmentSections[indexPath.section] {
        case .normal: attachment = normalAttachments[indexPath.row] as Attachment
        case .inline: attachment = inlineAttachments[indexPath.row] as Attachment
        }
        
        if let att = attachment {
            cell.configCell(att.fileName, fileSize: att.fileSize.intValue, showDownload: false)
            let crossView = UILabel();
            crossView.text = LocalString._general_remove_button
            crossView.sizeToFit()
            crossView.textColor = UIColor.white
            cell.defaultColor = UIColor.lightGray
            cell.setSwipeGestureWith(crossView, color: .red, mode: MCSwipeTableViewCellMode.exit, state: MCSwipeTableViewCellState.state3  ) { [weak self] (cell, state, mode) -> Void in
                guard let `self` = self else { return }
                guard let cell = cell, let indexp = self.tableView.indexPath(for: cell) else {
                    return
                }
                
                var att: Attachment!
                switch self.attachmentSections[indexp.section] {
                case .normal:
                    att = self.normalAttachments[indexp.row] as Attachment
                case .inline:
                    att = self.inlineAttachments[indexp.row] as Attachment
                }
                
                self.delegate?.attachments(self, didDeletedAttachment: att)
                if let index = self.attachments.index(of: att) {
                    self.attachments.remove(at: index)
                }
            }
        }
        
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44;
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return attachmentSections[section].actionTitle
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = Fonts.h6.regular
        header.textLabel?.textColor = UIColor.gray
    }
}

extension AttachmentsTableViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        configureNavigationBar(navigationController)
    }
}
