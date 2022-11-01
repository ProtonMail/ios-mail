//
//  ContactGroupSelectColorViewController.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations
import UIKit

final class ContactGroupSelectColorViewController: UIViewController {
    private let viewModel: ContactGroupSelectColorViewModel
    private var collectionView: UICollectionView?
    private var doneButton: UIBarButtonItem?

    init(viewModel: ContactGroupSelectColorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorProvider.BackgroundNorm
        title = LocalString._contact_groups_edit_avartar

        setupCollectionView()

        doneButton = UIBarButtonItem(title: LocalString._general_done_button,
                                     style: UIBarButtonItem.Style.plain,
                                     target: self, action: #selector(didTapDoneButton))
        let attributes = FontManager.DefaultStrong.foregroundColor(ColorProvider.InteractionNorm)
        doneButton?.setTitleTextAttributes(attributes, for: .normal)
        navigationItem.rightBarButtonItem = doneButton

        navigationItem.leftBarButtonItem = UIBarButtonItem.backBarButtonItem(target: self, action: #selector(didTapCancelButton(_:)))
    }

    private func setupCollectionView() {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        view.addSubview(collectionView)
        [
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        ].activate()
        self.collectionView = collectionView
        self.collectionView?.backgroundColor = ColorProvider.BackgroundNorm
        self.collectionView?.delegate = self
        self.collectionView?.dataSource = self
        self.collectionView?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "ContactGroupColorSelectionCell")
    }

    @objc
    private func didTapCancelButton(_ sender: UIBarButtonItem) {
        if viewModel.havingUnsavedChanges {
            let alertController = UIAlertController(title: LocalString._warning,
                                                    message: LocalString._changes_will_discarded,
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: LocalString._general_discard, style: .destructive, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
            present(alertController, animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc
    private func didTapDoneButton() {
        viewModel.save()
        navigationController?.popViewController(animated: true)
    }
}

extension ContactGroupSelectColorViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets
    {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return CGSize(width: 34, height: 34)
    }
}

extension ContactGroupSelectColorViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.getTotalColors()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContactGroupColorSelectionCell",
                                                      for: indexPath)

        let color = viewModel.getColor(at: indexPath)
        cell.backgroundColor = UIColor(hexString: color, alpha: 1.0)
        cell.layer.cornerRadius = 17

        if viewModel.isSelectedColor(at: indexPath) {
            cell.layer.borderWidth = 4
            cell.layer.borderColor = UIColor.darkGray.cgColor
        }

        return cell
    }
}

extension ContactGroupSelectColorViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // deselect
        let currentColorIndex = viewModel.getCurrentColorIndex()
        var cell = collectionView.cellForItem(at: IndexPath(row: currentColorIndex, section: 0))
        cell?.layer.borderWidth = 0

        // select the new color
        cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.borderWidth = 4
        cell?.layer.borderColor = UIColor.darkGray.cgColor
        viewModel.updateCurrentColor(to: indexPath)
    }
}
