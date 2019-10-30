//
//  DKPhotoGallery.swift
//  DKPhotoGallery
//
//  Created by ZhangAo on 15/7/20.
//  Copyright (c) 2015年 ZhangAo. All rights reserved.
//

import UIKit

@objc
public protocol DKPhotoGalleryDelegate : NSObjectProtocol {
    
    /// Called by the gallery just after it shows the index.
    @objc optional func photoGallery(_ gallery: DKPhotoGallery, didShow index: Int)
    
}

@objc
public protocol DKPhotoGalleryIncrementalDataSource : NSObjectProtocol {
    
    @objc optional func numberOfItems(in gallery: DKPhotoGallery) -> Int
    
    // Return 'nil' to indicate that no more items can be made in the given direction.
    @objc func photoGallery(_ gallery: DKPhotoGallery,
                            itemsBefore item: DKPhotoGalleryItem?,
                            resultHandler: @escaping ((_ items: [DKPhotoGalleryItem]?, _ error: Error?) -> Void))
    
    @objc func photoGallery(_ gallery: DKPhotoGallery,
                            itemsAfter item: DKPhotoGalleryItem?,
                            resultHandler: @escaping ((_ items: [DKPhotoGalleryItem]?, _ error: Error?) -> Void))
    
}

@objc
public enum DKPhotoGallerySingleTapMode : Int {
    case
    dismiss, // Dismiss DKPhotoGallery when user tap on the screen.
    toggleControlView
}

@objc
open class DKPhotoGallery: UINavigationController, UIViewControllerTransitioningDelegate,
DKPhotoGalleryContentDataSource, DKPhotoGalleryContentDelegate {
	
    @objc open var items: [DKPhotoGalleryItem]?
    @objc open var incrementalDataSource: DKPhotoGalleryIncrementalDataSource?
    
    @objc open var finishedBlock: ((_ index: Int, _ item: DKPhotoGalleryItem) -> UIImageView?)?
    
    @objc open var presentingFromImageView: UIImageView?
    @objc open var presentationIndex = 0
    
    @objc open var singleTapMode = DKPhotoGallerySingleTapMode.toggleControlView
    
    @objc weak open var galleryDelegate: DKPhotoGalleryDelegate?
    
    @objc open var customLongPressActions: [UIAlertAction]?
    @objc open var customPreviewActions: [Any]? // [UIPreviewActionItem]
    
    @objc open var footerView: UIView? {
        didSet {
            self.contentVC?.footerView = self.footerView
            self.updateFooterView()
        }
    }
    
    open var transitionController: DKPhotoGalleryTransitionController?
    
    internal var statusBar: UIView?
    internal weak var contentVC: DKPhotoGalleryContentVC?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black
        
        self.navigationBar.tintColor = UIColor.darkGray
        self.navigationBar.isTranslucent = true
        
        let contentVC = DKPhotoGalleryContentVC()
        self.contentVC = contentVC
        self.viewControllers = [contentVC]
        
        contentVC.prepareToShow = { [weak self] previewVC in
            self?.setup(previewVC: previewVC)
        }
        
        contentVC.pageChangeBlock = { [weak self] index in
            guard let strongSelf = self else { return }
            
            strongSelf.updateNavigation()
            strongSelf.galleryDelegate?.photoGallery?(strongSelf, didShow: index)
        }
        
        #if swift(>=4.2)
        contentVC.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel,
                                                                     target: self,
                                                                     action: #selector(DKPhotoGallery.dismissGallery))
        #else
        contentVC.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel,
                                                                     target: self,
                                                                     action: #selector(DKPhotoGallery.dismissGallery))
        #endif
        
        contentVC.dataSource = self
        contentVC.delegate = self
        contentVC.currentIndex = min(self.presentationIndex, self.numberOfItems() - 1)
        
        contentVC.footerView = self.footerView
        
        if #available(iOS 13.0, *) {} else {
            let keyData = Data([0x73, 0x74, 0x61, 0x74, 0x75, 0x73, 0x42, 0x61, 0x72])
            let key = String(data: keyData, encoding: String.Encoding.ascii)!
            if let statusBar = UIApplication.shared.value(forKey: key) as? UIView {
                self.statusBar = statusBar
            }            
        }
    }
    
    private lazy var doSetupOnce: () -> Void = {
        self.isNavigationBarHidden = true
        self.setFooterViewHidden(true, animated: false)
        
        if self.singleTapMode == .toggleControlView {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                self.setNavigationBarHidden(false, animated: true)
                self.setFooterViewHidden(false, animated: true)
                self.showsControlView()
            })
            self.statusBar?.alpha = 1
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: {
                self.setFooterViewHidden(false, animated: true)
            })
            self.statusBar?.alpha = 0
        }

        return {}
    }()
    
    private let defaultStatusBarStyle = UIApplication.shared.statusBarStyle
    private static var _preferredStatusBarStyle = UIStatusBarStyle.default
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.doSetupOnce()
        
        UIApplication.shared.statusBarStyle = DKPhotoGallery._preferredStatusBarStyle
        
        self.modalPresentationCapturesStatusBarAppearance = true
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.shared.statusBarStyle = self.defaultStatusBarStyle
        
        self.modalPresentationCapturesStatusBarAppearance = false
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.statusBar?.alpha = 1
    }
    
    @objc open func dismissGallery() {
        self.dismiss(animated: true) {
            if self.view.window == nil {
                self.transitionController = nil
            }
        }
    }
    
    @objc open func currentContentView() -> UIView {
        return self.contentVC!.currentContentView
    }
    
    @objc open func currentContentVC() -> DKPhotoBasePreviewVC {
        return self.contentVC!.currentVC
    }
    
    @objc open func currentIndex() -> Int {
        return self.contentVC!.currentIndex
    }
    
    @objc open func updateNavigation() {
        self.contentVC!.navigationItem.title = "\(self.contentVC!.currentIndex + 1)/\(self.numberOfItems())"
    }
    
    @objc open func handleSingleTap() {
        switch self.singleTapMode {
        case .toggleControlView:
            self.toggleControlView()
        case .dismiss:
            self.dismissGallery()
        }
    }
    
    @objc open func toggleControlView() {
        if self.isNavigationBarHidden {
            self.showsControlView()
        } else {
            self.hidesControlView()
        }
    }
    
    @objc open func showsControlView () {
        self.isNavigationBarHidden = false
        self.statusBar?.alpha = 1
        self.contentVC?.setFooterViewHidden(false, animated: false)
        
        if let videoPreviewVCs = self.contentVC?.filterVisibleVCs(with: DKPhotoPlayerPreviewVC.self) {
            let _ = videoPreviewVCs.map { $0.isControlHidden = false }
        }
    }
    
    @objc open func hidesControlView () {
        self.isNavigationBarHidden = true
        self.statusBar?.alpha = 0
        self.contentVC?.setFooterViewHidden(true, animated: false)
        
        if let videoPreviewVCs = self.contentVC?.filterVisibleVCs(with: DKPhotoPlayerPreviewVC.self) {
            let _ = videoPreviewVCs.map { $0.isControlHidden = true }
        }
    }
    
    @available(iOS 9.0, *)
    open override var previewActionItems: [UIPreviewActionItem] {
        return self.contentVC!.currentVC.previewActionItems
    }
    
    // MARK: - Private, internal
    
    private func updateFooterView() {
        if self.footerView != nil {
            if self.singleTapMode == .toggleControlView && self.isNavigationBarHidden {
                self.contentVC?.setFooterViewHidden(true, animated: false)
            }
        }
    }
    
    private func setup(previewVC: DKPhotoBasePreviewVC) {
        previewVC.customLongPressActions = self.customLongPressActions
        previewVC.customPreviewActions = self.customPreviewActions
        previewVC.singleTapBlock = { [weak self] in
            self?.handleSingleTap()
        }
        
        if previewVC.previewType == .video, let videoPreviewVC = previewVC as? DKPhotoPlayerPreviewVC {
            if self.singleTapMode == .dismiss {
                videoPreviewVC.closeBlock = { [weak self] in
                    self?.dismissGallery()
                }
                videoPreviewVC.isControlHidden = true
                videoPreviewVC.autoHidesControlView = true
                videoPreviewVC.tapToToggleControlView = true
            } else {
                videoPreviewVC.isControlHidden = self.isNavigationBarHidden
                videoPreviewVC.autoHidesControlView = false
                videoPreviewVC.tapToToggleControlView = false
                
                videoPreviewVC.beginPlayBlock = { [weak self] in
                    self?.hidesControlView()
                }
            }
        }
    }
    
    internal func updateContextBackground(alpha: CGFloat, animated: Bool) {
        let block = {
            self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: alpha)
            self.currentContentVC().view.superview?.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: alpha)

            if self.isNavigationBarHidden {
                self.statusBar?.alpha = 1 - alpha
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.1, animations: block)
        } else {
            block()
        }
    }
    
    internal func setFooterViewHidden(_ hidden: Bool, animated: Bool) {
        self.contentVC?.setFooterViewHidden(hidden, animated: animated)
    }
    
    // MARK: - DKPhotoGalleryContentDataSource
    
    internal func numberOfItems() -> Int {
        if let items = self.items, items.count > 0 {
            return items.count
        } else {
            fatalError("Please add at least one item.")
        }
    }
    
    internal func item(for index: Int) -> DKPhotoGalleryItem {
        if let items = self.items {
            return items[index]
        } else {
            fatalError("Please add at least one item.")
        }
    }
    
    private var hasMoreForLeft = true
    internal func hasIncrementalDataForLeft() -> Bool {
        if let _ = self.incrementalDataSource {
            return self.hasMoreForLeft
        } else {
            return false
        }
    }
    
    internal func incrementalItemsForLeft(resultHandler: @escaping ((Int) -> Void)) {
        guard let incrementalDataSource = self.incrementalDataSource else { return }
        
        incrementalDataSource.photoGallery(self, itemsBefore: self.items?.first) { [weak self] (items, error) in
            guard let strongSelf = self else { return }
            
            if let _ = error {
                resultHandler(0)
            } else {
                if let items = items, items.count > 0 {
                    strongSelf.items = items + (strongSelf.items ?? [])
                } else {
                    strongSelf.hasMoreForLeft = false
                }
                resultHandler(items?.count ?? 0)
            }
        }
    }
    
    private var hasMoreForRight = true
    internal func hasIncrementalDataForRight() -> Bool {
        if let _ = self.incrementalDataSource {
            return self.hasMoreForRight
        } else {
            return false
        }
    }
    
    internal func incrementalItemsForRight(resultHandler: @escaping ((Int) -> Void)) {
        guard let incrementalDataSource = self.incrementalDataSource else { return }
        
        incrementalDataSource.photoGallery(self, itemsAfter: self.items?.last) { [weak self] (items, error) in
            guard let strongSelf = self else { return }
            
            if let _ = error {
                resultHandler(0)
            } else {
                if let items = items, items.count > 0 {
                    strongSelf.items = (strongSelf.items ?? []) + items
                } else {
                    strongSelf.hasMoreForRight = false
                }
                resultHandler(items?.count ?? 0)
            }
        }
    }
    
    // MARK: - DKPhotoGalleryContentDelegate
    
    internal func contentVCCanScrollToPreviousOrNext(_ contentVC: DKPhotoGalleryContentVC) -> Bool {
        if let isInteracting = self.transitionController?.interactiveController?.isInteracting, isInteracting {
            return !isInteracting
        } else {
            return true
        }
    }
    
    // MARK: - UINavigationController
    
    private var _isNavigationBarHidden: Bool = false
    open override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
        
        if self.viewControllers.count == 2 {
            if self.isNavigationBarHidden {
                self._isNavigationBarHidden = true
                
                self.setNavigationBarHidden(false, animated: true)
                
                UIView.animate(withDuration: 0.1, animations: {
                    self.statusBar?.alpha = 1
                })
            }
        }
    }
    
    open override func popViewController(animated: Bool) -> UIViewController? {
        let vc = super.popViewController(animated: animated)
        
        if self.viewControllers.count == 1 {
            if self._isNavigationBarHidden {
                self._isNavigationBarHidden = false
                
                self.setNavigationBarHidden(true, animated: true)
                
                UIView.animate(withDuration: 0.1, animations: {
                    self.statusBar?.alpha = 0
                })
            }
        }
        
        return vc
    }
    
    // MARK: - Utilities
        
    internal class func imageFromColor(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        
        // create a 1 by 1 pixel context
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        
        color.setFill()
        UIRectFill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    public class func setPreferredStatusBarStyle(statusBarStyle: UIStatusBarStyle) {
        _preferredStatusBarStyle = statusBarStyle
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return DKPhotoGallery._preferredStatusBarStyle
    }

}

//////////////////////////////////////////////////////////////////////////////////////////

public extension UIViewController {
    
    @objc public func present(photoGallery gallery: DKPhotoGallery, completion: (() -> Swift.Void)? = nil) {
        gallery.modalPresentationStyle = .custom
        
        gallery.transitionController = DKPhotoGalleryTransitionController(gallery: gallery,
                                                                          presentedViewController: gallery,
                                                                          presenting: self)
        gallery.transitioningDelegate = gallery.transitionController
        
        gallery.transitionController!.prepareInteractiveGesture()
        
        self.present(gallery, animated: true, completion: completion)
    }
}
