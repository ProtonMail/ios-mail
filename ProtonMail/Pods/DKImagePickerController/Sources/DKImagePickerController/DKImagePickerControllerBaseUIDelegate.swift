//
//  DKImagePickerControllerBaseUIDelegate.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 16/3/7.
//  Copyright © 2016年 ZhangAo. All rights reserved.
//

import UIKit

@objc
public enum DKImagePickerGroupListPresentationStyle: Int {
    case popover
    case presented
}

@objc
public protocol DKImagePickerControllerUIDelegate {

    /**
     The picker calls -prepareLayout once at its first layout as the first message to the UIDelegate instance.
     */
    func prepareLayout(_ imagePickerController: DKImagePickerController, vc: UIViewController)

    /**
     The layout is to provide information about the position and visual state of items in the collection view.
     */
    func layoutForImagePickerController(_ imagePickerController: DKImagePickerController) -> UICollectionViewLayout.Type

    /**
     Called when the user needs to show the cancel button.
     */
    func imagePickerController(_ imagePickerController: DKImagePickerController, showsCancelButtonForVC vc: UIViewController)

    /**
     Called when the user needs to hide the cancel button.
     */
    func imagePickerController(_ imagePickerController: DKImagePickerController, hidesCancelButtonForVC vc: UIViewController)

    /**
     Called after the user changes the selection.
     */
    func imagePickerController(_ imagePickerController: DKImagePickerController, didSelectAssets: [DKAsset])

    /**
     Called after the user changes the selection.
     */
    func imagePickerController(_ imagePickerController: DKImagePickerController, didDeselectAssets: [DKAsset])

    /**
     Called when the count of the selectedAssets did reach `maxSelectableCount`.
     */
    func imagePickerControllerDidReachMaxLimit(_ imagePickerController: DKImagePickerController)

    /**
     Accessory view below content. default is nil.
     */
    func imagePickerControllerFooterView(_ imagePickerController: DKImagePickerController) -> UIView?

    /**
     Accessory view above content. default is nil.
     */
    func imagePickerControllerHeaderView(_ imagePickerController: DKImagePickerController) -> UIView?

    /**
     Set the color of the background of the collection view.
     */
    func imagePickerControllerCollectionViewBackgroundColor() -> UIColor

    func imagePickerControllerCollectionImageCell() -> DKAssetGroupDetailBaseCell.Type

    func imagePickerControllerCollectionCameraCell() -> DKAssetGroupDetailBaseCell.Type

    func imagePickerControllerCollectionVideoCell() -> DKAssetGroupDetailBaseCell.Type

    func imagePickerControllerGroupCell() -> DKAssetGroupCellType.Type

    /**
      Provide a custom button to be used as the titleView for imagePickerController's navigationItem.
    */
    func imagePickerControllerSelectGroupButton(_ imagePickerController: DKImagePickerController, selectedGroup: DKAssetGroup) -> UIButton

    /**
      Specify how asset group list view controller should be presented, default is .popover
    */
    func imagePickerControllerGroupListPresentationStyle() -> DKImagePickerGroupListPresentationStyle

    /**
      Use to customize the group list table view controller before presentation.
    */
    func imagePickerControllerPrepareGroupListViewController(_ listViewController: UITableViewController)
}

////////////////////////////////////////////////////////////////////////////////////////////////////

@objc
open class DKImagePickerControllerBaseUIDelegate: NSObject, DKImagePickerControllerUIDelegate {

    open weak var imagePickerController: DKImagePickerController!

    open var doneButton: UIButton?
    open var selectGroupButton: UIButton?

    open func createDoneButtonIfNeeded() -> UIButton {
        if self.doneButton == nil {
            let button = UIButton(type: UIButton.ButtonType.custom)
            button.setTitleColor(UINavigationBar.appearance().tintColor ?? self.imagePickerController.navigationBar.tintColor, for: .normal)
            self.updateDoneButtonTitle(button)
            self.doneButton = button
        }

        return self.doneButton!
    }

    open func createSelectGroupButtonIfNeeded() -> UIButton {
        if self.selectGroupButton == nil {
            let button = UIButton()

            #if swift(>=4.0)
            let globalTitleColor = UINavigationBar.appearance()
                .titleTextAttributes?[NSAttributedString.Key.foregroundColor] as? UIColor
            let globalTitleFont = UINavigationBar.appearance()
                .titleTextAttributes?[NSAttributedString.Key.font] as? UIFont
            #else
            let globalTitleColor = UINavigationBar.appearance()
                .titleTextAttributes?[NSForegroundColorAttributeName] as? UIColor
            let globalTitleFont = UINavigationBar.appearance()
                .titleTextAttributes?[NSFontAttributeName] as? UIFont
            #endif

            var defaultColor = UIColor.black
            if #available(iOS 13, *) {
                defaultColor = UIColor.label
            }
            button.setTitleColor(globalTitleColor ?? defaultColor, for: .normal)
            button.titleLabel!.font = globalTitleFont ?? UIFont.boldSystemFont(ofSize: 18.0)

            self.selectGroupButton = button
        }

        return self.selectGroupButton!
    }

    open func updateDoneButtonTitle(_ button: UIButton) {
        button.removeTarget(nil, action: nil, for: .allEvents)
        if self.imagePickerController.allowSelectAll {
            if self.imagePickerController.selectedAssetIdentifiers.count == 0 {
                button.setTitle(DKImagePickerControllerResource.localizedStringWithKey("picker.select.all.title"), for: .normal)
                button.addTarget(self.imagePickerController, action: #selector(DKImagePickerController.handleSelectAll), for: .touchUpInside)
            } else {
                button.setTitle(String(format: DKImagePickerControllerResource.localizedStringWithKey("picker.select.done.title") + "(%@)",
                                        selectedAssetsCount() ?? self.imagePickerController.selectedAssetIdentifiers.count), for: .normal)
                button.addTarget(self.imagePickerController, action: #selector(DKImagePickerController.done), for: .touchUpInside)
            }
        } else {
            button.addTarget(self.imagePickerController, action: #selector(DKImagePickerController.done), for: .touchUpInside)
            if self.imagePickerController.selectedAssetIdentifiers.count > 0 {
                button.setTitle(String(format: DKImagePickerControllerResource.localizedStringWithKey("picker.select.title"),
                                        selectedAssetsCount() ?? self.imagePickerController.selectedAssetIdentifiers.count), for: .normal)
            } else {
                button.setTitle(DKImagePickerControllerResource.localizedStringWithKey("picker.select.done.title"), for: .normal)
            }
        }
        button.sizeToFit()
        handleBarButtonBug(button: button)
    }

    private func handleBarButtonBug(button: UIButton) {
        if #available(iOS 11.0, *) { // Handle iOS 11 BarButtonItems bug
            if button.constraints.count == 0 {
                button.widthAnchor.constraint(equalToConstant: button.bounds.width).isActive = true
                button.heightAnchor.constraint(equalToConstant: button.bounds.height).isActive = true
            } else {
                for constraint in button.constraints {
                    if constraint.firstAttribute == .width {
                        constraint.constant = button.bounds.width
                    } else if constraint.firstAttribute == .height {
                        constraint.constant = button.bounds.height
                    }
                }
            }
        }
    }

    private func selectedAssetsCount() -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: Locale.current.identifier)
        let formattedSelectableCount = formatter.string(from: NSNumber(value: self.imagePickerController.selectedAssetIdentifiers.count))
        return formattedSelectableCount
    }

    // Delegate methods...

    open func prepareLayout(_ imagePickerController: DKImagePickerController, vc: UIViewController) {
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.createDoneButtonIfNeeded())
    }

    open func layoutForImagePickerController(_ imagePickerController: DKImagePickerController) -> UICollectionViewLayout.Type {
        return DKAssetGroupGridLayout.self
    }

    open func imagePickerController(_ imagePickerController: DKImagePickerController,
                                    showsCancelButtonForVC vc: UIViewController) {
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                              target: imagePickerController,
                                                              action: #selector(imagePickerController.dismiss as () -> Void))
    }

    open func imagePickerController(_ imagePickerController: DKImagePickerController,
                                    hidesCancelButtonForVC vc: UIViewController) {
        vc.navigationItem.leftBarButtonItem = nil
    }

    open func imagePickerController(_ imagePickerController: DKImagePickerController, didSelectAssets: [DKAsset]) {
        self.updateDoneButtonTitle(self.createDoneButtonIfNeeded())
    }

    open func imagePickerController(_ imagePickerController: DKImagePickerController, didDeselectAssets: [DKAsset]) {
        self.updateDoneButtonTitle(self.createDoneButtonIfNeeded())
    }

    open var isMaxLimitAlertDisplayed: Bool {
        return imagePickerController.visibleViewController?.isKind(of: UIAlertController.self) ?? false
    }

    open func imagePickerControllerDidReachMaxLimit(_ imagePickerController: DKImagePickerController) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: Locale.current.identifier)

        let formattedMaxSelectableCount = formatter.string(from: NSNumber(value: imagePickerController.maxSelectableCount))

        let alert = UIAlertController(title: DKImagePickerControllerResource.localizedStringWithKey("picker.select.maxLimitReached.error.title"), message: nil, preferredStyle: .alert)

        alert.message = String(format: DKImagePickerControllerResource.localizedStringWithKey("picker.select.maxLimitReached.error.message"), formattedMaxSelectableCount ?? imagePickerController.maxSelectableCount)

        alert.addAction(UIAlertAction(title: DKImagePickerControllerResource.localizedStringWithKey("picker.alert.ok"), style: .cancel) { _ in })

        imagePickerController.present(alert, animated: true)
    }

    open func imagePickerControllerFooterView(_ imagePickerController: DKImagePickerController) -> UIView? {
        return nil
    }

    open func imagePickerControllerHeaderView(_ imagePickerController: DKImagePickerController) -> UIView? {
        return nil
    }

    open func imagePickerControllerCollectionViewBackgroundColor() -> UIColor {
        return UIColor.white
    }

    open func imagePickerControllerCollectionImageCell() -> DKAssetGroupDetailBaseCell.Type {
        return DKAssetGroupDetailImageCell.self
    }

    open func imagePickerControllerCollectionCameraCell() -> DKAssetGroupDetailBaseCell.Type {
        return DKAssetGroupDetailCameraCell.self
    }

    open func imagePickerControllerCollectionVideoCell() -> DKAssetGroupDetailBaseCell.Type {
        return DKAssetGroupDetailVideoCell.self
    }

    open func imagePickerControllerGroupCell() -> DKAssetGroupCellType.Type {
        return DKAssetGroupCell.self
    }

    open func needsToShowPreviewOnLongPress() -> Bool {
        return true
    }

    open func imagePickerControllerSelectGroupButton(_ imagePickerController: DKImagePickerController, selectedGroup: DKAssetGroup) -> UIButton {
        let button = self.createSelectGroupButtonIfNeeded()
        let groupsCount = self.imagePickerController.groupDataManager.groupIds?.count ?? 0
        button.setTitle((selectedGroup.groupName ?? "") + (groupsCount > 1 ? "  \u{25be}" : "" ), for: .normal)
        button.sizeToFit()
        button.isEnabled = groupsCount > 1
        return button
    }

    open func imagePickerControllerGroupListPresentationStyle() -> DKImagePickerGroupListPresentationStyle {
        return .popover
    }

    open func imagePickerControllerPrepareGroupListViewController(_ listViewController: UITableViewController) {
        // nothing by default, override in subclasses to customize group list table view
    }
}

