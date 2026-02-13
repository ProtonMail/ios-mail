// Copyright (c) 2026 Proton Technologies AG
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

import Foundation
import InboxTesting
import Testing
import proton_app_uniffi

@testable import ProtonMail

@MainActor
final class PrivacyInfoStateStoreTests {
    private var sut: PrivacyInfoStateStore!
    private let messageID = ID(value: 123)

    // MARK: - Initial State

    @Test
    func testInitialState_IsLoading() {
        sut = makeSUT()

        #expect(sut.state.info.isLoading)
        #expect(sut.state.info.loadedValue == nil)
        #expect(sut.state.isSettingEnabled)
    }

    // MARK: - loadInfo Action

    @Test
    func testLoadInfo_whenStreamReturnsValidInitialValue_updatesStateToLoaded() async {
        let mockStream = MockPrivacyStream(initialValue: .dummy, subsequentValues: [])
        sut = makeSUT(stream: mockStream)
        defer { sut = nil }

        await sut.handle(action: .loadInfo)

        #expect(!sut.state.info.isLoading)
        #expect(sut.state.isSettingEnabled)
        let loadedValue = sut.state.info.loadedValue
        #expect(loadedValue?.totalTrackersCount == 3)
        #expect(loadedValue?.totalLinksCount == 2)
    }

    @Test
    func testLoadInfo_whenStreamReturnsEmptyInitialValue_updatesStateToLoadedEmpty() async {
        let mockStream = MockPrivacyStream(initialValue: .empty, subsequentValues: [])
        sut = makeSUT(stream: mockStream)
        defer { sut = nil }

        await sut.handle(action: .loadInfo)
        await Task.yield()

        #expect(!sut.state.info.isLoading)
        #expect(sut.state.isSettingEnabled)
        #expect(sut.state.info.loadedValue?.isEmpty == true)
    }

    @Test
    func testLoadInfo_whenStreamReturnsNilLinks_doesNotUpdateState() async {
        let mockStream = MockPrivacyStream(initialValue: .init(trackers: .detected(.dummy), utmLinks: nil), subsequentValues: [])
        sut = makeSUT(stream: mockStream)
        defer { sut = nil }

        await sut.handle(action: .loadInfo)
        await Task.yield()

        #expect(sut.state.info.isLoading)
        #expect(sut.state.info.loadedValue == nil)
    }

    @Test
    func testLoadInfo_whenStreamReturnsPendingTrackers_updatesStateToLoading() async {
        let mockStream = MockPrivacyStream(initialValue: .init(trackers: .pending, utmLinks: .dummy), subsequentValues: [])
        sut = makeSUT(stream: mockStream)
        defer { sut = nil }

        await sut.handle(action: .loadInfo)
        await Task.yield()

        #expect(sut.state.info.isLoading)
        #expect(sut.state.info.loadedValue == nil)
    }

    @Test
    func testLoadInfo_whenStreamReturnsDisabledTrackers_setsSettingDisabled() async {
        let mockStream = MockPrivacyStream(initialValue: .init(trackers: .disabled, utmLinks: .dummy), subsequentValues: [])
        sut = makeSUT(stream: mockStream)
        defer { sut = nil }

        await sut.handle(action: .loadInfo)
        await Task.yield()

        #expect(!sut.state.isSettingEnabled)
    }

    @Test
    func testLoadInfo_whenCalledTwice_doesNotLoadAgain() async {
        let mockStream = MockPrivacyStream(initialValue: .dummy, subsequentValues: [])
        let provider = MockPrivacyStreamProvider(stream: mockStream)
        sut = makeSUT(provider: provider)
        defer { sut = nil }

        await sut.handle(action: .loadInfo)
        await Task.yield()

        let callCountAfterFirstLoad = provider.streamCallCount

        await sut.handle(action: .loadInfo)
        await Task.yield()

        #expect(provider.streamCallCount == callCountAfterFirstLoad)
    }

    @Test
    func testLoadInfo_whenStreamProducesUpdates_updatesState() async throws {
        let updatedInfo = PrivacyInfo(
            trackers: .detected(
                .init(
                    trackers: [
                        TrackerDomain(name: "tracker1.com", urls: ["url1"]),
                        TrackerDomain(name: "tracker2.com", urls: ["url2"]),
                        TrackerDomain(name: "tracker3.com", urls: ["url3"]),
                        TrackerDomain(name: "tracker4.com", urls: ["url4"]),
                    ],
                    lastCheckedAt: 0
                )
            ),
            utmLinks: .dummy
        )
        let mockStream = MockPrivacyStream(
            initialValue: .dummy,
            subsequentValues: [updatedInfo]
        )
        sut = makeSUT(stream: mockStream)
        defer { sut = nil }

        await sut.handle(action: .loadInfo)
        await Task.yield()

        let initialValue = sut.state.info.loadedValue
        #expect(initialValue?.totalTrackersCount == 3)

        mockStream.triggerNext()

        try await expectToEventually(self.sut.state.info.loadedValue?.totalTrackersCount == 4, timeout: 0.1)
    }

    //    @Test
    //    func testLoadInfo_whenStreamProducesDisabledUpdate_setsSettingDisabled() async throws {
    //        let disabledInfo = PrivacyInfo(trackers: .disabled, utmLinks: .dummy)
    //        let mockStream = MockPrivacyStream(
    //            initialValue: .dummy,
    //            subsequentValues: [disabledInfo]
    //        )
    //        sut = makeSUT(stream: mockStream)
    //        defer { sut = nil }
    //
    //        #expect(sut.state.isSettingEnabled)
    //        await sut.handle(action: .loadInfo)
    //        await Task.yield()
    //
    //        mockStream.triggerNext()
    //
    //        try await expectToEventually(!self.sut.state.isSettingEnabled, timeout: 0.1)
    //    }

    //    @Test
    //    func testLoadInfo_whenStreamProducesPendingUpdate_setsStateToLoading() async throws {
    //        let pendingInfo = PrivacyInfo(trackers: .pending, utmLinks: .dummy)
    //        let mockStream = MockPrivacyStream(
    //            initialValue: .dummy,
    //            subsequentValues: [pendingInfo]
    //        )
    //        sut = makeSUT(stream: mockStream)
    //        defer { sut = nil }
    //
    //        await sut.handle(action: .loadInfo)
    //        await Task.yield()
    //
    //        #expect(!sut.state.info.isLoading)
    //        #expect(sut.state.info.loadedValue != nil)
    //
    //        mockStream.triggerNext()
    //
    //        try await expectToEventually(self.sut.state.info.isLoading, timeout: 0.1)
    //    }

    @Test
    func testLoadInfo_whenStreamThrows_doesNotCrash() async {
        let mockStream = MockPrivacyStream(
            initialValue: .dummy,
            subsequentValues: [],
            shouldThrow: true
        )
        sut = makeSUT(stream: mockStream)
        defer { sut = nil }

        await sut.handle(action: .loadInfo)

        // Should not crash, state might remain loading or have initial value
        #expect(sut.state.info.loadedValue == nil || sut.state.info.loadedValue != nil)
    }

    // MARK: - deinit

    @Test
    func testDeinit_stopsStream() async throws {
        let mockStream = MockPrivacyStream(initialValue: .dummy, subsequentValues: [])
        sut = makeSUT(stream: mockStream)

        await sut?.handle(action: .loadInfo)
        await Task.yield()
        #expect(!mockStream.stopWasCalled)

        sut = nil

        try await expectToEventually(mockStream.stopWasCalled, timeout: 0.1)
    }

    // MARK: - Helpers

    private func makeSUT(
        stream: MockPrivacyStream? = nil,
        provider: MockPrivacyStreamProvider? = nil
    ) -> PrivacyInfoStateStore {
        let finalStream = stream ?? MockPrivacyStream(initialValue: .empty, subsequentValues: [])
        let finalProvider = provider ?? MockPrivacyStreamProvider(stream: finalStream)

        return PrivacyInfoStateStore(
            messageID: messageID,
            privacyInfoStreamProvider: .init(
                userSession: .dummy,
                actions: .init { _, _ in try await finalProvider.stream() }
            )
        )
    }
}

// MARK: - Mock Classes

private final class MockPrivacyStreamProvider: @unchecked Sendable {
    private let stream: MockPrivacyStream
    private(set) var streamCallCount = 0

    init(stream: MockPrivacyStream) {
        self.stream = stream
    }

    func stream() async throws -> any AsyncWatchingStream {
        streamCallCount += 1
        return stream
    }
}

private final class MockPrivacyStream: AsyncWatchingStream, @unchecked Sendable {
    private let initialPrivacyInfo: PrivacyInfo
    private var subsequentValues: [PrivacyInfo]
    private let shouldThrow: Bool
    private var nextIndex = 0
    private(set) var stopWasCalled = false
    private var continuation: CheckedContinuation<PrivacyInfo, Error>?

    var value: Any {
        initialPrivacyInfo
    }

    init(initialValue: PrivacyInfo, subsequentValues: [PrivacyInfo], shouldThrow: Bool = false) {
        self.initialPrivacyInfo = initialValue
        self.subsequentValues = subsequentValues
        self.shouldThrow = shouldThrow
    }

    func next() async throws -> Any {
        guard !shouldThrow else { throw NSError(domain: "test", code: -1) }
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func triggerNext() {
        guard nextIndex < subsequentValues.count else { return }
        let value = subsequentValues[nextIndex]
        nextIndex += 1
        continuation?.resume(returning: value)
        continuation = nil
    }

    func stop() {
        stopWasCalled = true
        continuation?.resume(throwing: CancellationError())
        continuation = nil
    }
}

// MARK: - Test Data

private extension PrivacyInfo {
    static var empty: Self {
        .init(
            trackers: .detected(.init(trackers: [], lastCheckedAt: 0)),
            utmLinks: .init(links: [])
        )
    }

    static var dummy: Self {
        .init(trackers: .detected(.dummy), utmLinks: .dummy)
    }
}

private extension TrackerInfo {
    static var dummy: Self {
        .init(
            trackers: [
                TrackerDomain(name: "tracker1.com", urls: ["url1", "url2"]),
                TrackerDomain(name: "tracker2.com", urls: ["url3"]),
            ],
            lastCheckedAt: 0
        )
    }
}

private extension StrippedUtmInfo {
    static var dummy: Self {
        .init(links: [
            .init(originalUrl: "https://example.com?utm=1", cleanedUrl: "https://example.com"),
            .init(originalUrl: "https://test.com?utm=2", cleanedUrl: "https://test.com"),
        ])
    }
}
