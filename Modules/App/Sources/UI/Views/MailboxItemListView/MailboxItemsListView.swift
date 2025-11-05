// Copyright (c) 2024 Proton Technologies AG
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

import Combine
import InboxCoreUI
import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

struct MailboxItemsListView<EmptyView: View>: View {
    @EnvironmentObject var toastStateStore: ToastStateStore
    let config: MailboxItemsListViewConfiguration
    @ViewBuilder let emptyView: EmptyView
    @ObservedObject private(set) var selectionState: SelectionModeState
    private let mailUserSession: MailUserSession
    @Binding var emptyFolderBanner: EmptyFolderBanner?
    @State var isScrollingDisabled = false
    let mailbox: Mailbox?

    // pull to refresh
    @State private var listPullOffset: CurrentValueSubject<CGFloat, Never> = .init(0.0)
    private var listPullOffsetPublisher: AnyPublisher<CGFloat, Never> {
        listPullOffset.eraseToAnyPublisher()
    }

    init(
        config: MailboxItemsListViewConfiguration,
        @ViewBuilder emptyView: () -> EmptyView,
        emptyFolderBanner: Binding<EmptyFolderBanner?>,
        mailUserSession: MailUserSession,
        mailbox: Mailbox?
    ) {
        self.config = config
        self.emptyView = emptyView()
        self.selectionState = config.selectionState
        self.mailUserSession = mailUserSession
        _emptyFolderBanner = emptyFolderBanner
        self.mailbox = mailbox
    }

    var body: some View {
        if let mailbox {
            listView
                .onChange(of: selectionState.hasItems) { _, shouldShowToolbar in
                    toastStateStore.state.bottomBar.isVisible = shouldShowToolbar
                }
                .animation(.none, value: selectionState.hasItems)
                .toolbar(selectionState.hasItems ? .visible : .hidden, for: .bottomBar)
                .animation(.default, value: selectionState.hasItems)
                .listActionsToolbar(
                    initialState: .initial,
                    availableActions: .productionInstance,
                    itemTypeForActionBar: config.itemTypeForActionBar,
                    mailUserSession: mailUserSession,
                    selectedItems: config.selectionState.selectedItemIDsReadOnlyBinding
                )
                .environmentObject(mailbox)
        } else {
            listView
        }
    }

    private var listView: some View {
        PaginatedListView(
            dataSource: config.dataSource,
            headerView: { headerView },
            emptyListView: { emptyView },
            cellView: { index, item in
                cellView(index: index, item: item)
            },
            onScrollEvent: { event in
                switch event {
                case .onChangeOffset(let offset):
                    self.listPullOffset.send(offset)
                }
            }
        )
        .scrollDisabled(isScrollingDisabled)
        .listStyle(.plain)
        .introspect(.list, on: SupportedIntrospectionPlatforms.list) { collectionView in
            guard
                config.listEventHandler != nil,
                (collectionView.refreshControl as? ProtonRefreshControl) == nil
            else { return }
            let protonRefreshControl = ProtonRefreshControl(listPullOffset: listPullOffsetPublisher) {
                await config.listEventHandler?.pullToRefresh?()
            }
            collectionView.refreshControl = protonRefreshControl
            protonRefreshControl.tintColor = .clear
        }
        .listScrollObservation(onEventAtTopChange: { newValue in
            config.listEventHandler?.listAtTop?(newValue)
        })
        .sensoryFeedback(trigger: selectionState.selectedItems) { oldValue, newValue in
            oldValue.count != newValue.count ? .selection : nil
        }
    }

    private var headerView: EmptyFolderBannerView? {
        guard let emptyFolderBanner, !config.dataSource.state.items.isEmpty else {
            return nil
        }

        return EmptyFolderBannerView(
            model: emptyFolderBanner,
            mailUserSession: mailUserSession,
            wrapper: .productionInstance()
        )
    }

    private func cellView(index: Int, item: MailboxItemCellUIModel) -> some View {
        VStack {
            SwipeableView(
                leftAction: config.swipeActions.left.swipeActionModel(for: item),
                rightAction: config.swipeActions.right.swipeActionModel(for: item),
                onLeftAction: {
                    config.cellEventHandler?.onSwipeAction?(config.swipeActions.left.swipeActionContext(for: item))
                },
                onRightAction: {
                    config.cellEventHandler?.onSwipeAction?(config.swipeActions.right.swipeActionContext(for: item))
                },
                isEnabled: areSwipeActionsEnabled,
                isScrollingDisabled: $isScrollingDisabled
            ) {
                MailboxItemCell(
                    uiModel: item,
                    isParentListSelectionEmpty: !selectionState.hasItems,
                    isSending: config.isOutboxLocation,
                    onEvent: { config.cellEventHandler?.onCellEvent($0, item) }
                )
                .accessibilityElementGroupedVoiceOver(value: voiceOverValue(for: item))
                .accessibilityIdentifier("\(MailboxListViewIdentifiers.listCell)\(index)")
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(
            .init(top: DS.Spacing.tiny, leading: .zero, bottom: DS.Spacing.tiny, trailing: .zero)
        )
        .listRowSeparator(.hidden)
        .compositingGroup()
        .clipShape(
            .rect(
                topLeadingRadius: config.selectionState.hasItems ? 20 : 0,
                bottomLeadingRadius: config.selectionState.hasItems ? 20 : 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            )
        )
        .background(DS.Color.Background.norm)  // cell background color after clipping
    }

    private func voiceOverValue(for item: MailboxItemCellUIModel) -> String {
        let unread = item.isRead ? "" : L10n.Mailbox.VoiceOver.unread.string
        let expiration = item.expirationDate?.toExpirationDateUIModel?.text.string ?? ""
        let attachments =
            item.attachments.previewables.count > 0
            ? L10n.Mailbox.VoiceOver.attachments(count: item.attachments.previewables.count).string
            : ""
        let value: String = """
            \(unread)
            \(item.emails).
            \(item.subject).
            \(item.date.mailboxVoiceOverSupport()).
            \(expiration).
            \(item.snoozeDate ?? "").
            \(attachments)
            """
        return value
    }

    private var areSwipeActionsEnabled: Bool {
        selectionState.hasItems == false && config.isOutboxLocation == false
    }
}

private struct MailboxListViewIdentifiers {
    static let listCell = "mailbox.list.cell"
}

private extension SelectionModeState {

    var selectedItemIDsReadOnlyBinding: Binding<Set<MailboxSelectedItem>> {
        .readonly(get: { [weak self] in self?.selectedItems ?? [] })
    }

}

#Preview {

    @MainActor
    final class Model: ObservableObject {
        var currentPage = 0
        let pageSize = 20
        let subject: PassthroughSubject<PaginatedListUpdate<MailboxItemCellUIModel>, Never> = .init()

        lazy var dataSource = PaginatedListDataSource<MailboxItemCellUIModel>(
            fetchMore: { [weak self] isFirstPage in
                Task { await self?.nextPage(isFirstPage: isFirstPage) }
            }
        )

        private func nextPage(isFirstPage: Bool) async {
            try? await Task.sleep(for: .seconds(2))
            let items = MailboxItemCellUIModel.testData()
            let isLastPage = (currentPage + 1) * pageSize > items.count
            let range = currentPage * pageSize..<min(items.count, (currentPage + 1) * pageSize)
            let itemsToAppend = Array(items[range])
            subject.send(.init(isLastPage: isLastPage, value: .append(items: itemsToAppend)))
            currentPage += 1
        }
    }

    struct Container: View {
        @StateObject var model: Model

        init() {
            self._model = StateObject(wrappedValue: Model())
        }

        var body: some View {
            MailboxItemsListView(
                config: makeConfiguration(),
                emptyView: { Text("MAILBOX IS EMPTY".notLocalized) },
                emptyFolderBanner: .constant(nil),
                mailUserSession: .dummy,
                mailbox: .dummy
            )
            .task {
                model.dataSource.fetchInitialPage()
            }
        }

        func makeConfiguration() -> MailboxItemsListViewConfiguration {
            let selectionState = SelectionModeState()
            return .init(
                dataSource: model.dataSource,
                selectionState: selectionState,
                itemTypeForActionBar: .conversation,
                isOutboxLocation: false,
                swipeActions: .init(
                    left: .toggleRead,
                    right: .moveTo(.moveToSystemLabel(label: .trash, id: .init(value: 0)))
                )
            )
        }
    }
    return Container()
}

import SwiftUI
import UIKit

struct AnimatableXTransformModifier: ViewModifier, Animatable {
    var x: CGFloat

    var animatableData: CGFloat {
        get { x }
        set { x = newValue }
    }

    func body(content: Content) -> some View {
        content
            .transformEffect(.init(translationX: x, y: 0))
    }
}

extension View {
    func animatableXTransform(x: CGFloat = 0) -> some View {
        modifier(AnimatableXTransformModifier(x: x))
    }
}

struct SwipeActionModel: Equatable {
    let image: Image
    let color: Color
    let isDesctructive: Bool
}

struct SwipeableView<Content: View>: View {
    private struct ActiveAction: Equatable {
        let side: ActionSide
        let model: SwipeActionModel
    }

    private enum ActionSide: Equatable {
        case right, left

        var actionAligment: Alignment {
            switch self {
            case .right:
                .leading
            case .left:
                .trailing
            }
        }
    }

    private enum AxisLock: Equatable {
        case none, horizontal, vertical
    }

    private let content: () -> Content
    private let leftAction: SwipeActionModel?
    private let rightAction: SwipeActionModel?
    private let onLeftAction: (() -> Void)?
    private let onRightAction: (() -> Void)?
    private let isEnabled: Bool
    private let animationDuration = 0.25

    @Binding private var isScrollingDisabled: Bool

    @State private var swipeOffset: CGFloat = .zero
    @State private var initialSwipeTriggerOffset: CGFloat = .zero
    @State private var activeAction: ActiveAction?
    @State private var axisLock: AxisLock = .none
    @State private var rowWidth: CGFloat = .zero
    @State private var isSwiping: Bool = false
    @State private var isFinishingSwipeWithAnimation = false

    private let triggerFactor: CGFloat = 0.20

    private var didCrossThreshold: Bool {
        abs(swipeOffset) > rowWidth * triggerFactor
    }

    init(
        leftAction: SwipeActionModel?,
        rightAction: SwipeActionModel?,
        onLeftAction: (() -> Void)?,
        onRightAction: (() -> Void)?,
        isEnabled: Bool,
        isScrollingDisabled: Binding<Bool>,
        content: @escaping () -> Content
    ) {
        self.leftAction = leftAction
        self.rightAction = rightAction
        self.onLeftAction = onLeftAction
        self.onRightAction = onRightAction
        self.isEnabled = isEnabled
        self._isScrollingDisabled = isScrollingDisabled
        self.content = content
    }

    var body: some View {
        ZStack {
            if let activeAction {
                actionView(activeAction)
            }

            content()
                .disabled(isSwiping)
                .overlay(
                    RoundedRectangle(cornerRadius: isSwiping ? DS.Spacing.small : .zero)
                        .stroke(DS.Color.Border.light, lineWidth: isSwiping ? 2 : .zero)
                )
                .clipShape(RoundedRectangle(cornerRadius: isSwiping ? DS.Spacing.small : .zero))
                .animatableXTransform(x: swipeOffset)
                .animation(.linear(duration: animationDuration), value: isSwiping)
                .sensoryFeedback(.impact, trigger: didCrossThreshold, condition: { _, _ in !isFinishingSwipeWithAnimation })
                .onGeometryChange(
                    for: CGFloat.self,
                    of: { geometry in geometry.size.width },
                    action: { value in rowWidth = value }
                )
                .swipeActionGesture(
                    isEnabled: isEnabled && !isFinishingSwipeWithAnimation,
                    DragGesture(minimumDistance: 4)
                        .onChanged(onDragChanged)
                        .onEnded(onDragEnded)
                )
                .onChange(of: isSwiping) { _, isSwiping in
                    isScrollingDisabled = isSwiping
                }
        }
    }

    @ViewBuilder
    private func actionView(_ action: ActiveAction) -> some View {
        action.model.image
            .foregroundStyle(DS.Color.Icon.inverted)
            .square(size: 16)
            .scaleEffect(didCrossThreshold ? 1.3 : 1)
            .animation(.linear(duration: animationDuration), value: didCrossThreshold)
            .frame(maxWidth: .infinity, alignment: action.side.actionAligment)
            .padding(.horizontal, DS.Spacing.huge)
            .frame(maxHeight: .infinity)
            .background(action.model.color.shadow(DS.Shadows.liftedFull.innerShadowStyle))
    }

    private func onDragChanged(_ value: DragGesture.Value) {
        let lockSlop: CGFloat = 10
        let dx = value.translation.width
        let dy = value.translation.height

        if axisLock == .none {
            if abs(dx) > abs(dy) + lockSlop {
                axisLock = .horizontal
            } else if abs(dy) > abs(dx) + lockSlop {
                axisLock = .vertical
            } else {
                return
            }
        }

        guard axisLock == .horizontal else { return }

        if initialSwipeTriggerOffset == .zero {
            initialSwipeTriggerOffset = dx
        }

        let targetOffset = dx - initialSwipeTriggerOffset

        if targetOffset > .zero {
            activeAction = action(for: .right)
        } else if targetOffset < .zero {
            activeAction = action(for: .left)
        }

        if activeAction != nil {
            swipeOffset = targetOffset
            isSwiping = true
        }
    }

    private func onDragEnded(_ value: DragGesture.Value) {
        defer { axisLock = .none }

        guard axisLock == .horizontal else { return }

        triggerCallbackIfNeeded()

        isFinishingSwipeWithAnimation = true
        withAnimation(.easeOut(duration: animationDuration)) {
            if let activeAction, activeAction.model.isDesctructive, didCrossThreshold {
                swipeOffset = fullSwipeOffset(for: activeAction.side)
            } else {
                swipeOffset = .zero
            }
            isSwiping = false
            initialSwipeTriggerOffset = .zero
        } completion: {
            swipeOffset = .zero
            activeAction = nil
            isFinishingSwipeWithAnimation = false
        }
    }

    private func triggerCallbackIfNeeded() {
        guard let activeAction, didCrossThreshold else { return }
        switch activeAction.side {
        case .left:
            onLeftAction?()
        case .right:
            onRightAction?()
        }
    }

    private func action(for side: ActionSide) -> ActiveAction? {
        switch side {
        case .right:
            rightAction.map { .init(side: side, model: $0) }
        case .left:
            leftAction.map { .init(side: side, model: $0) }
        }
    }

    private func fullSwipeOffset(for side: ActionSide) -> CGFloat {
        switch side {
        case .right:
            rowWidth
        case .left:
            -rowWidth
        }
    }
}

extension AssignedSwipeAction {

    var isDestructive: Bool {
        switch self {
        case .moveTo:
            true
        case .labelAs, .noAction, .toggleStar, .toggleRead:
            false
        }
    }

}

extension AssignedSwipeAction {

    func swipeActionModel(for item: MailboxItemCellUIModel) -> SwipeActionModel? {
        switch self {
        case .noAction:
            nil
        case .labelAs, .toggleStar, .toggleRead, .moveTo:
            SwipeActionModel(
                image: icon(isRead: item.isRead, isStarred: item.isStarred),
                color: color,
                isDesctructive: isDestructive
            )
        }
    }

    func swipeActionContext(for item: MailboxItemCellUIModel) -> SwipeActionContext {
        .init(action: self, itemID: item.id, isItemRead: item.isRead, isItemStarred: item.isStarred)
    }

}

private struct SwipeActionGesture<G: Gesture>: ViewModifier {
    private let isEnabled: Bool
    private let swipeGesture: G

    init(isEnabled: Bool, swipeGesture: G) {
        self.isEnabled = isEnabled
        self.swipeGesture = swipeGesture
    }

    func body(content: Content) -> some View {
        if isEnabled {
            if #available(iOS 18, *) {
                content.simultaneousGesture(swipeGesture)
            } else {
                content.gesture(swipeGesture)
            }
        } else {
            content
        }
    }
}

private extension View {
    func swipeActionGesture<G: Gesture>(isEnabled: Bool, _ gesture: G, ) -> some View {
        modifier(SwipeActionGesture(isEnabled: isEnabled, swipeGesture: gesture))
    }
}
