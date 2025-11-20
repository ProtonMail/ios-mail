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

import InboxDesignSystem
import SwiftUI
import proton_app_uniffi

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
    @State private var initialSwipeOffset: CGFloat = .zero
    @State private var activeAction: ActiveAction?
    @State private var axisLock: AxisLock = .none
    @State private var rowWidth: CGFloat = .zero
    @State private var isSwiping: Bool = false
    @State private var isFinishingSwipeWithAnimation = false

    private let actionTriggerThreshold: CGFloat = 0.20

    private var didCrossActionThreshold: Bool {
        abs(swipeOffset) > rowWidth * actionTriggerThreshold
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
                        .stroke(DS.Color.Border.light, lineWidth: isSwiping ? DS.Spacing.tiny : .zero)
                )
                .clipShape(RoundedRectangle(cornerRadius: isSwiping ? DS.Spacing.small : .zero))
                .animatableXTransform(x: swipeOffset)
                .animation(.linear(duration: animationDuration), value: isSwiping)
                .sensoryFeedback(.impact, trigger: didCrossActionThreshold, condition: { _, _ in !isFinishingSwipeWithAnimation })
                .onGeometryChange(for: CGFloat.self, of: \.size.width, action: { value in rowWidth = value })
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
            .scaleEffect(didCrossActionThreshold ? 1.3 : 1)
            .animation(.linear(duration: animationDuration), value: didCrossActionThreshold)
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

        if initialSwipeOffset == .zero {
            initialSwipeOffset = dx
        }

        let targetOffset = dx - initialSwipeOffset

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
            if let activeAction, activeAction.model.isDesctructive, didCrossActionThreshold {
                swipeOffset = fullSwipeOffset(for: activeAction.side)
            } else {
                swipeOffset = .zero
            }
            isSwiping = false
            initialSwipeOffset = .zero
        } completion: {
            swipeOffset = .zero
            activeAction = nil
            isFinishingSwipeWithAnimation = false
        }
    }

    private func triggerCallbackIfNeeded() {
        guard let activeAction, didCrossActionThreshold else { return }
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

private struct SwipeActionGesture<SwipeGesture: Gesture>: ViewModifier {
    private let isEnabled: Bool
    private let swipeGesture: SwipeGesture

    init(isEnabled: Bool, swipeGesture: SwipeGesture) {
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

private struct AnimatableXTransformModifier: ViewModifier, Animatable {
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

private extension View {
    func swipeActionGesture<SwipeGesture: Gesture>(isEnabled: Bool, _ gesture: SwipeGesture) -> some View {
        modifier(SwipeActionGesture(isEnabled: isEnabled, swipeGesture: gesture))
    }

    func animatableXTransform(x: CGFloat = 0) -> some View {
        modifier(AnimatableXTransformModifier(x: x))
    }
}
