//
//  DKAssetGroupDetailVC.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 15/8/10.
//  Copyright (c) 2015年 ZhangAo. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

private extension UICollectionView {
    
    func indexPathsForElements(in rect: CGRect, _ hidesCamera: Bool) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        
        if hidesCamera {
            return allLayoutAttributes.map { $0.indexPath }
        } else {
            #if swift(>=4.1)
            return allLayoutAttributes.compactMap { $0.indexPath.item == 0 ? nil : IndexPath(item: $0.indexPath.item - 1, section: $0.indexPath.section) }
            #else
            return allLayoutAttributes.flatMap { $0.indexPath.item == 0 ? nil : IndexPath(item: $0.indexPath.item - 1, section: $0.indexPath.section) }
            #endif
        }
    }
    
}

////////////////////////////////////////////////////////////

// Show all images in the asset group
open class DKAssetGroupDetailVC: UIViewController,
    UIGestureRecognizerDelegate,
    UICollectionViewDelegate, UICollectionViewDataSource, DKImageGroupDataManagerObserver, DKImagePickerControllerObserver {
    	
    public lazy var selectGroupButton: UIButton = {
        let button = UIButton()
		
        #if swift(>=4.0)
        let globalTitleColor = UINavigationBar.appearance().titleTextAttributes?[NSAttributedStringKey.foregroundColor] as? UIColor
        let globalTitleFont = UINavigationBar.appearance().titleTextAttributes?[NSAttributedStringKey.font] as? UIFont
        #else
        let globalTitleColor = UINavigationBar.appearance().titleTextAttributes?[NSForegroundColorAttributeName] as? UIColor
        let globalTitleFont = UINavigationBar.appearance().titleTextAttributes?[NSFontAttributeName] as? UIFont
        #endif
        
        button.setTitleColor(globalTitleColor ?? UIColor.black, for: .normal)
		button.titleLabel!.font = globalTitleFont ?? UIFont.boldSystemFont(ofSize: 18.0)
		
		button.addTarget(self, action: #selector(DKAssetGroupDetailVC.showGroupSelector), for: .touchUpInside)
        return button
    }()
		
    public var selectedGroupId: String?
    internal var collectionView: UICollectionView!
    internal weak var imagePickerController: DKImagePickerController!
    private var groupListVC: DKAssetGroupListVC!
    private var hidesCamera: Bool = false
    private var footerView: UIView?
    private var headerView: UIView?
    private var currentViewSize: CGSize!
    private var registeredCellIdentifiers = Set<String>()
    private var thumbnailSize = CGSize.zero
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.imagePickerController.add(observer: self)
		
		let layout = self.imagePickerController.UIDelegate.layoutForImagePickerController(self.imagePickerController).init()
		self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        self.collectionView.backgroundColor = self.imagePickerController.UIDelegate.imagePickerControllerCollectionViewBackgroundColor()
        self.collectionView.allowsMultipleSelection = true
		self.collectionView.delegate = self
		self.collectionView.dataSource = self
		self.view.addSubview(self.collectionView)
		
		self.footerView = self.imagePickerController.UIDelegate.imagePickerControllerFooterView(self.imagePickerController)
		if let footerView = self.footerView {
			self.view.addSubview(footerView)
		}
      
    self.headerView = self.imagePickerController.UIDelegate.imagePickerControllerHeaderView(self.imagePickerController)
    if let headerView = self.headerView {
      self.view.addSubview(headerView)
    }
		
		self.hidesCamera = self.imagePickerController.sourceType == .photo
		self.checkPhotoPermission()
        
        if self.imagePickerController.allowSwipeToSelect && !self.imagePickerController.singleSelect {
            let swipeOutGesture: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.swiping(gesture:)))
            swipeOutGesture.delegate = self
            self.collectionView.panGestureRecognizer.require(toFail: swipeOutGesture)
            self.collectionView.addGestureRecognizer(swipeOutGesture)
        }
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.updateCachedAssets()
    }
    
    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if let currentViewSize = self.currentViewSize, currentViewSize.equalTo(self.view.bounds.size) {
            return
        } else {
            currentViewSize = self.view.bounds.size
        }
        
        self.collectionView?.collectionViewLayout.invalidateLayout()
    }
	
	override open func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
    configureAccessoryViews()
  }
  
  func configureAccessoryViews() {
    var footerViewFrame = CGRect.zero
    var headerViewFrame = CGRect.zero
    if let footerView = self.footerView {
      footerViewFrame = CGRect(x: 0,
                               y: self.view.bounds.height - footerView.bounds.height,
                               width: self.view.bounds.width,
                               height: footerView.bounds.height)
      footerView.frame = footerViewFrame
    }
    if let headerView = self.headerView  {
      if #available(iOS 11.0, *) {
        headerViewFrame = CGRect(x: 0,
                                 y: self.view.safeAreaInsets.top,
                                 width: self.view.bounds.width,
                                 height: headerView.bounds.height)
      } else {
        headerViewFrame = CGRect(x: 0,
                                 y: 0,
                                 width: self.view.bounds.width,
                                 height: headerView.bounds.height)
      }
      headerView.frame = headerViewFrame
    }
    
    if #available(iOS 11.0, *) {
      // Handling Safe Areas for iOS 11
      self.collectionView.frame = CGRect(x: 0,
                                         y: self.view.safeAreaInsets.top + headerViewFrame.height,
                                         width: self.view.bounds.width,
                                         height: self.view.bounds.height - footerViewFrame.height - headerViewFrame.height - self.view.safeAreaInsets.top)
    } else {
      self.collectionView.frame = CGRect(x: 0,
                                         y: headerViewFrame.height,
                                         width: self.view.bounds.width,
                                         height: self.view.bounds.height - footerViewFrame.height - headerViewFrame.height)
    }
  }
	
	internal func checkPhotoPermission() {
		func photoDenied() {
            let permissionColors = self.imagePickerController.permissionViewColors
            self.view.addSubview(DKPermissionView.permissionView(.photo, withColors: permissionColors))
            self.view.backgroundColor = permissionColors.backgroundColor
			self.collectionView?.isHidden = true
		}
        
        func setup() {
            self.resetCachedAssets()
            self.imagePickerController.groupDataManager.add(observer: self)
            self.groupListVC = DKAssetGroupListVC(groupDataManager: self.imagePickerController.groupDataManager,
                                                  defaultAssetGroup: self.imagePickerController.defaultAssetGroup,
                                                  selectedGroupDidChangeBlock: { [unowned self] (groupId) in
                                                    self.selectAssetGroup(groupId)
            })
            self.groupListVC.showsEmptyAlbums = self.imagePickerController.showsEmptyAlbums
            self.groupListVC.loadGroups()
        }
        
		DKImageDataManager.checkPhotoPermission { granted in
			granted ? setup() : photoDenied()
		}
	}
	
    func selectAssetGroup(_ groupId: String?) {
        if self.selectedGroupId == groupId {
            self.updateTitleView()
            return
        }
        
        self.selectedGroupId = groupId
		self.updateTitleView()
		self.collectionView!.reloadData()
    }
    
	open func updateTitleView() {
        guard let selectedGroupId = self.selectedGroupId else { return }
        
		let group = self.imagePickerController.groupDataManager.fetchGroupWithGroupId(selectedGroupId)
		self.title = group.groupName
		
		let groupsCount = self.imagePickerController.groupDataManager.groupIds?.count ?? 0
		self.selectGroupButton.setTitle(group.groupName + (groupsCount > 1 ? "  \u{25be}" : "" ), for: .normal)
		self.selectGroupButton.sizeToFit()
		self.selectGroupButton.isEnabled = groupsCount > 1
		
		self.navigationItem.titleView = self.selectGroupButton
	}
    
    @objc func showGroupSelector() {
        DKPopoverViewController.popoverViewController(self.groupListVC, fromView: self.selectGroupButton)
    }
    
    func fetchAsset(for index: Int) -> DKAsset? {
        guard let selectedGroupId = self.selectedGroupId else { return nil }
        
        var assetIndex = index
        
        if !self.hidesCamera && index == 0 {
            return nil
        }
        assetIndex = (index - (self.hidesCamera ? 0 : 1))
        
        let group = self.imagePickerController.groupDataManager.fetchGroupWithGroupId(selectedGroupId)
        return self.imagePickerController.groupDataManager.fetchAsset(group, index: assetIndex)
    }
    
    // select an asset at a specific index
    public func selectAsset(atIndex indexPath: IndexPath) {
        guard let cell = self.collectionView.cellForItem(at: indexPath) as? DKAssetGroupDetailBaseCell
            , let asset = cell.asset else {
            return
        }
        
        if !self.imagePickerController.contains(asset: asset) {
            self.imagePickerController.select(asset: asset)
        }
    }
    
    public func deselectAsset(atIndex indexPath: IndexPath) {
        guard let cell = self.collectionView.cellForItem(at: indexPath) as? DKAssetGroupDetailBaseCell
            , let asset = cell.asset else {
                return
        }

        self.imagePickerController.deselect(asset: asset)
    }
    
    public func adjustAssetIndex(_ index: Int) -> Int {
        if self.hidesCamera {
            return index
        } else {
            return index + 1
        }
    }
    
    public func scrollIndexPathToVisible(_ indexPath: IndexPath) {
        if let cellFrame = self.collectionView.collectionViewLayout.layoutAttributesForItem(at: indexPath)?.frame {
            self.collectionView.scrollRectToVisible(cellFrame, animated: false)
        }
    }
    
    public func thumbnailImageView(for indexPath: IndexPath) -> UIImageView? {
        if let cell = self.collectionView.cellForItem(at: indexPath) as? DKAssetGroupDetailBaseCell {
            return cell.thumbnailImageView
        } else {
            self.collectionView.reloadItems(at: [indexPath])
            
            return (self.collectionView.cellForItem(at: indexPath) as? DKAssetGroupDetailBaseCell)?
                .thumbnailImageView
        }
    }

    func isCameraCell(indexPath: IndexPath) -> Bool {
        return indexPath.row == 0 && !self.hidesCamera
    }

    // MARK: - Swiping
    
    private var fromIndexPath: IndexPath? = nil
    private var swipingIndexPathes = Set<Int>()
    private var swipingToSelect = true
    
    // use the swiping gesture to select the currently swiping cell.
    @objc private func swiping(gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self.collectionView)
        
        switch gesture.state {
        case .possible:
            break
        case .began:
            if let indexPath = self.collectionView.indexPathForItem(at: location)
                , let cell = self.collectionView.cellForItem(at: indexPath) {
                self.fromIndexPath = indexPath
                self.swipingToSelect = !cell.isSelected
            }
        case .changed:
            if let toIndexPath = self.collectionView.indexPathForItem(at: location)
                , let fromIndexPath = self.fromIndexPath {
                let begin = min(fromIndexPath.row, toIndexPath.row)
                let end = max(fromIndexPath.row, toIndexPath.row)
                
                var currentSwipingIndexPathes = Set<Int>()
                for i in begin...end {
                    currentSwipingIndexPathes.insert(i)
                    self.swipingIndexPathes.remove(i)
                    
                    if self.swipingToSelect {
                        self.selectAsset(atIndex: IndexPath(row: i, section: 0))
                    } else {
                        self.deselectAsset(atIndex: IndexPath(row: i, section: 0))
                    }
                }
                
                for i in self.swipingIndexPathes {
                    if self.swipingToSelect {
                        self.deselectAsset(atIndex: IndexPath(row: i, section: 0))
                    } else {
                        self.selectAsset(atIndex: IndexPath(row: i, section: 0))
                    }
                }
                self.swipingIndexPathes = currentSwipingIndexPathes
            }
        case .ended:
            self.swipingIndexPathes.removeAll()
            self.fromIndexPath = nil
        case .cancelled:
            self.swipingIndexPathes.removeAll()
            self.fromIndexPath = nil
        case .failed:
            self.swipingIndexPathes.removeAll()
            self.fromIndexPath = nil
        }
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        
        let locationPoint = panGesture.location(in: self.collectionView)
        if let indexPath = self.collectionView.indexPathForItem(at: locationPoint),
            self.isCameraCell(indexPath: indexPath) {
            return false
        }
        
        let velocityPoint = panGesture.velocity(in: nil)
        let x = abs(velocityPoint.x)
        let y = abs(velocityPoint.y)
        return x > y
    }
    
    // MARK: - Gallery
    
    func showGallery(from cell: DKAssetGroupDetailBaseCell) {
        if let groupId = self.selectedGroupId {
            let presentationIndex = cell.tag - 1 - (self.hidesCamera ? 0 : 1)
            self.imagePickerController.showGallery(with: presentationIndex,
                                                   presentingFromImageView: cell.thumbnailImageView,
                                                   groupId: groupId)
        }
    }
    
    // MARK: - Cells
    
    func registerCellIfNeeded(cellClass: DKAssetGroupDetailBaseCell.Type) {
        let cellReuseIdentifier = cellClass.cellReuseIdentifier()
        
        if !self.registeredCellIdentifiers.contains(cellReuseIdentifier) {
            self.collectionView.register(cellClass, forCellWithReuseIdentifier: cellReuseIdentifier)
            self.registeredCellIdentifiers.insert(cellReuseIdentifier)
        }
    }
    
    func dequeueReusableCell(for indexPath: IndexPath) -> DKAssetGroupDetailBaseCell {
        let asset = self.fetchAsset(for: indexPath.row)!
        
        let cellClass: DKAssetGroupDetailBaseCell.Type!
        if asset.type == .video {
            cellClass = self.imagePickerController.UIDelegate.imagePickerControllerCollectionVideoCell()
        } else {
            cellClass = self.imagePickerController.UIDelegate.imagePickerControllerCollectionImageCell()
        }
        self.registerCellIfNeeded(cellClass: cellClass)
        
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: cellClass.cellReuseIdentifier(), for: indexPath) as! DKAssetGroupDetailBaseCell
        self.setup(assetCell: cell, for: indexPath, with: asset)
        
        return cell
    }
    
    func dequeueReusableCameraCell(for indexPath: IndexPath) -> DKAssetGroupDetailBaseCell {
        let cellClass = self.imagePickerController.UIDelegate.imagePickerControllerCollectionCameraCell()
        self.registerCellIfNeeded(cellClass: cellClass)
        
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: cellClass.cellReuseIdentifier(), for: indexPath)
        return cell as! DKAssetGroupDetailBaseCell
    }
	
    func setup(assetCell cell: DKAssetGroupDetailBaseCell, for indexPath: IndexPath, with asset: DKAsset) {
        cell.asset = asset
		let tag = indexPath.row + 1
		cell.tag = tag
		
        if self.thumbnailSize.equalTo(CGSize.zero) {
            self.thumbnailSize = self.collectionView!.collectionViewLayout.layoutAttributesForItem(at: indexPath)!.size.toPixel()
        }
        
        cell.thumbnailImage = nil
        
        asset.fetchImage(with: self.thumbnailSize, options: nil, contentMode: .aspectFill) { [weak cell] (image, info) in
            if let cell = cell, cell.tag == tag, let image = image {
                cell.thumbnailImage = image
            }
        }
        
        cell.longPressBlock = { [weak self, weak cell] in
            guard let strongSelf = self, let strongCell = cell else { return }
            
            strongSelf.showGallery(from: strongCell)
        }
	}

    // MARK: - UICollectionViewDelegate, UICollectionViewDataSource methods

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		guard let selectedGroupId = self.selectedGroupId else { return 0 }
		
		let group = self.imagePickerController.groupDataManager.fetchGroupWithGroupId(selectedGroupId)
        return group.totalCount + (self.hidesCamera ? 0 : 1)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: DKAssetGroupDetailBaseCell!
        if self.isCameraCell(indexPath: indexPath) {
            cell = self.dequeueReusableCameraCell(for: indexPath)
        } else {
            cell = self.dequeueReusableCell(for: indexPath)
        }
        
        if cell.imagePickerController == nil {
            cell.imagePickerController = self.imagePickerController
        }
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let assetCell = cell as? DKAssetGroupDetailBaseCell, let asset = assetCell.asset else { return }
        
        if let selectedIndex = self.imagePickerController.index(of: asset) {
            assetCell.isSelected = true
            assetCell.selectedIndex = selectedIndex
            self.collectionView!.selectItem(at: indexPath, animated: false, scrollPosition: [])
        } else {
            assetCell.isSelected = false
            self.collectionView!.deselectItem(at: indexPath, animated: false)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let asset = (collectionView.cellForItem(at: indexPath) as? DKAssetGroupDetailBaseCell)?.asset {
            return self.imagePickerController.canSelect(asset: asset)
        } else {
            return true
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.isCameraCell(indexPath: indexPath) {
            collectionView .deselectItem(at: indexPath, animated: false)
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                self.imagePickerController.presentCamera()
            }
        } else {
            self.selectAsset(atIndex: indexPath)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.deselectAsset(atIndex: indexPath)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.updateCachedAssets()
    }
    
    // MARK: - Asset Caching
    
    open func enableCaching() -> Bool {
        return true
    }
    
    var previousPreheatRect = CGRect.zero
    
    func resetCachedAssets() {
        guard enableCaching() else { return }

        getImageDataManager().stopCachingForAllAssets()
        self.previousPreheatRect = .zero
    }

    func updateCachedAssets() {
        guard enableCaching(), let selectedGroupId = self.selectedGroupId else { return }
        
        // Update only if the view is visible.
        guard isViewLoaded && view.window != nil && self.selectedGroupId != nil else { return }
        
        // The preheat window is twice the height of the visible rect.
        let preheatRect = view!.bounds.insetBy(dx: 0, dy: -0.5 * view!.bounds.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - self.previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        let group = self.imagePickerController.groupDataManager.fetchGroupWithGroupId(selectedGroupId)
        
        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = self.differencesBetweenRects(self.previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in self.collectionView!.indexPathsForElements(in: rect, self.hidesCamera) }
            .map { indexPath in self.imagePickerController.groupDataManager.fetchPHAsset(group, index: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in self.collectionView!.indexPathsForElements(in: rect, self.hidesCamera) }
            .map { indexPath in self.imagePickerController.groupDataManager.fetchPHAsset(group, index: indexPath.item) }
        
        // Update the assets the PHCachingImageManager is caching.
        getImageDataManager().startCachingAssets(for: addedAssets,
                                             targetSize: self.thumbnailSize, contentMode: .aspectFill, options: nil)
        getImageDataManager().stopCachingAssets(for: removedAssets,
                                            targetSize: self.thumbnailSize, contentMode: .aspectFill, options: nil)
        
        // Store the preheat rect to compare against in the future.
        self.previousPreheatRect = preheatRect
    }
    
    func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
    
    // MARK: - DKImagePickerControllerObserver
    
    func imagePickerControllerDidSelect(assets: [DKAsset]) {
        if assets.count > 1 {
            self.collectionView.reloadData()
        } else {
            let asset = assets.first!
            
            for indexPathForVisible in self.collectionView.indexPathsForVisibleItems {
                if let cell = self.collectionView.cellForItem(at: indexPathForVisible) as? DKAssetGroupDetailBaseCell {
                    if cell.asset == asset {
                        let selectedIndex = self.imagePickerController.selectedAssetIdentifiers.count - 1
                        cell.selectedIndex = selectedIndex
                        
                        if !cell.isSelected {
                            self.collectionView.selectItem(at: indexPathForVisible, animated: true, scrollPosition: [])
                        }
                        
                        break
                    }
                }
            }
        }
    }
    
    func imagePickerControllerDidDeselect(assets: [DKAsset]) {
        if assets.count > 1 {
            self.collectionView.reloadData()
        } else {
            for indexPathForVisible in self.collectionView.indexPathsForVisibleItems {
                if let cell = (self.collectionView.cellForItem(at: indexPathForVisible) as? DKAssetGroupDetailBaseCell),
                    let asset = cell.asset, cell.isSelected {
                    if let selectedIndex = self.imagePickerController.index(of: asset) {
                        cell.selectedIndex = selectedIndex
                    } else if cell.isSelected {
                        self.collectionView.deselectItem(at: indexPathForVisible, animated: true)
                    }
                }
            }
        }
    }
    
	// MARK: - DKImageGroupDataManagerObserver
	
	func groupDidUpdate(groupId: String) {
		if self.selectedGroupId == groupId {
			self.updateTitleView()
		}
	}
	
	func group(groupId: String, didRemoveAssets assets: [DKAsset]) {
        for removedAsset in assets {
            if self.imagePickerController.contains(asset: removedAsset) {
                self.imagePickerController.deselect(asset: removedAsset)
            }
        }
	}
    
    func groupDidUpdateComplete(groupId: String) {
        if self.selectedGroupId == groupId {
            self.resetCachedAssets()
            self.collectionView?.reloadData()
        }
    }

}
