//
//  SingleMessageViewController+Print.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

extension SingleMessageViewController {

    func presentPrintController() {
        let headerController: Printable = self
        guard let bodyController: Printable = messageBodyViewController,
              let headerPrinter = headerController.printPageRenderer()
                as? HeaderedPrintRenderer.CustomViewPrintRenderer,
              let bodyPrinter = bodyController.printPageRenderer() as? HeaderedPrintRenderer else { return }

        bodyPrinter.header = headerPrinter

        headerController.printingWillStart?(renderer: headerPrinter)
        bodyController.printingWillStart?(renderer: bodyPrinter)

        let printController = UIPrintInteractionController.shared
        printController.printPageRenderer = bodyPrinter
        printController.present(animated: true) { _, _, _ in
            headerController.printingDidFinish?()
            bodyController.printingDidFinish?()
        }
    }

}

extension SingleMessageViewController: Printable {
    typealias Renderer = HeaderedPrintRenderer.CustomViewPrintRenderer

    func printPageRenderer() -> UIPrintPageRenderer {
        let newHeader = EmailHeaderView(frame: .init(x: 0, y: 0, width: 300, height: 300))
        newHeader.inject(recepientDelegate: self)
        newHeader.makeConstraints()
        newHeader.isShowingDetail = false
        newHeader.backgroundColor = .white
        newHeader.updateHeaderData(HeaderData(message: self.viewModel.message))
        newHeader.updateHeaderLayout()
        newHeader.updateShowImageConstraints()
        newHeader.updateSpamScoreConstraints()

        if self.viewModel.isExpanded {
            newHeader.detailsButtonTapped()
        }

        newHeader.layoutIfNeeded()

        return Renderer(newHeader)
    }

    func printingWillStart(renderer: UIPrintPageRenderer) {
        guard let renderer = renderer as? Renderer, let newHeader = renderer.view as? EmailHeaderView else { return }
        newHeader.prepareForPrinting(true)
        newHeader.frame = .init(x: 18, y: 39, width: 560, height: newHeader.getHeight())
        newHeader.layoutIfNeeded()

        renderer.updateImage(in: newHeader.frame)
    }

}

extension SingleMessageViewController: RecipientViewDelegate {

    func recipientView(at cell: RecipientCell, arrowClicked arrow: UIButton, model: ContactPickerModelProtocol) {}
    func recipientView(at cell: RecipientCell, lockClicked lock: UIButton, model: ContactPickerModelProtocol) {}

    func recipientView(lockCheck model: ContactPickerModelProtocol,
                       progress: () -> Void,
                       complete: LockCheckComplete?) {
        self.viewModel.nonExapndedHeaderViewModel?.lockIcon(complete: complete)
    }

}
