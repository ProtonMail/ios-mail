//
// Copyright (c) 2025 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Testing
import UniformTypeIdentifiers

@testable import TestableShareExtension

final class SharedItemsParserTests {
    private let sut = SharedItemsParser.self

    @Test
    func testSharingSeveralImagesFromPhotosApp() async throws {
        let extensionItems = emulateSharingSeveralImagesFromPhotosApp(count: 5)

        let sharedContent = try await sut.parse(extensionItems: extensionItems)

        #expect(sharedContent.subject == nil)
        #expect(sharedContent.body == nil)
        #expect(sharedContent.attachments == extensionItems[0].attachments)
    }

    @Test
    func testSharingSeveralImagesAndFilesFromFilesApp() async throws {
        let extensionItems = emulateSharingSeveralImagesAndFilesFromFilesApp(imageCount: 3, fileCount: 2)

        let sharedContent = try await sut.parse(extensionItems: extensionItems)

        #expect(sharedContent.subject == nil)
        #expect(sharedContent.body == nil)
        #expect(sharedContent.attachments == extensionItems[0].attachments)
    }

    @Test(arguments: [false, true])
    func testSharingBrowserPage(fromWithinPage: Bool) async throws {
        let extensionItems = emulateSharingBrowserPage(
            url: URL(string: "https://example.com")!,
            pageTitle: "An example webpage",
            fromWithinPage: fromWithinPage
        )

        let sharedContent = try await sut.parse(extensionItems: extensionItems)

        #expect(sharedContent.subject == "An example webpage")
        #expect(sharedContent.body == #"<a href="https://example.com">https://example.com</a>"#)
        #expect(sharedContent.attachments == [])
    }

    @Test
    func testSharingBrowserPageThatPointsToFile() async throws {
        let extensionItems = emulateSharingBrowserPageThatPointsToFile(
            url: URL(string: "https://example.com")!,
            pageTitle: "An example webpage"
        )

        let sharedContent = try await sut.parse(extensionItems: extensionItems)

        #expect(sharedContent.subject == nil)
        #expect(sharedContent.body == nil)
        #expect(sharedContent.attachments == extensionItems[0].attachments)
    }

    @Test
    func testSharingSelectedText() async throws {
        let extensionItems = emulateSharing(selectedText: "Lorem ipsum")

        let sharedContent = try await sut.parse(extensionItems: extensionItems)

        #expect(sharedContent.subject == nil)
        #expect(sharedContent.body == "Lorem ipsum")
        #expect(sharedContent.attachments == [])
    }

    // MARK: realistic scenarios

    private func emulateSharingSeveralImagesFromPhotosApp(count: UInt) -> [NSExtensionItem] {
        let extensionItem = NSExtensionItem()
        extensionItem.attachments = TestDataFactory.makeItemProviders(types: [.jpeg, .heic], count: count)
        return [extensionItem]
    }

    private func emulateSharingSeveralImagesAndFilesFromFilesApp(imageCount: UInt, fileCount: UInt) -> [NSExtensionItem] {
        let images = TestDataFactory.makeItemProviders(types: [.heic, .fileURL], count: imageCount)
        let files = TestDataFactory.makeItemProviders(types: [.plainText, .fileURL], count: fileCount)

        let extensionItem = NSExtensionItem()
        extensionItem.attachments = images + files
        return [extensionItem]
    }

    private func emulateSharingBrowserPage(url: URL, pageTitle: String, fromWithinPage: Bool) -> [NSExtensionItem] {
        let extensionItem = NSExtensionItem()
        extensionItem.attributedContentText = .init(string: pageTitle)
        extensionItem.attachments = [
            .init(item: url as NSSecureCoding, typeIdentifier: UTType.url.identifier)
        ]

        if fromWithinPage {
            extensionItem.attachments!
                .insert(
                    .init(item: "irrelevant" as NSSecureCoding, typeIdentifier: UTType.plainText.identifier),
                    at: 0
                )
        }

        return [extensionItem]
    }

    private func emulateSharingBrowserPageThatPointsToFile(url: URL, pageTitle: String) -> [NSExtensionItem] {
        let fileExtensionItem = NSExtensionItem()
        fileExtensionItem.attributedContentText = .init(string: pageTitle)
        fileExtensionItem.attachments = [
            TestDataFactory.makeItemProviders(types: [.pdf], count: 1)[0]
        ]

        let pageExtensionItem = NSExtensionItem()
        pageExtensionItem.attributedContentText = .init(string: pageTitle)
        pageExtensionItem.attachments = [
            .init(item: url as NSSecureCoding, typeIdentifier: UTType.url.identifier)
        ]

        return [fileExtensionItem, pageExtensionItem]
    }

    private func emulateSharing(selectedText: String) -> [NSExtensionItem] {
        let extensionItem = NSExtensionItem()
        extensionItem.attributedContentText = .init(string: selectedText)
        extensionItem.attachments = [
            .init(item: "this is irrelevant" as NSSecureCoding, typeIdentifier: UTType.plainText.identifier)
        ]
        return [extensionItem]
    }
}
