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

import InboxCoreUI
import SwiftUI
import SwiftUIIntrospect

struct ListScrollObservation: ViewModifier {
    @StateObject private var model: ListScrollObservationModel

    init(onEventAtTopChange: @escaping (Bool) -> Void) {
        self._model = StateObject(wrappedValue: ListScrollObservationModel(onEventAtTopChange: onEventAtTopChange))
    }

    func body(content: Content) -> some View {
        content
            .introspect(.list, on: SupportedIntrospectionPlatforms.list) { collectionView in

                model.observation = collectionView.observe(\.contentOffset, options: [.new, .old]) { view, change in
                    guard let newValueY = change.newValue?.y, let oldValueY = change.oldValue?.y else { return }
                    DispatchQueue.main.async {
                        model.listOffsetUpdate(
                            verticalAdjustedContentInset: view.adjustedContentInset.top,
                            oldOffsetY: oldValueY,
                            newOffsetY: newValueY
                        )
                    }
                }
            }
    }
}

final class ListScrollObservationModel: ObservableObject {
    let sensitivityThreshold: CGFloat = 50
    private let onEventAtTopChange: (Bool) -> Void
    private var isAtTop: Bool = true {
        didSet {
            if oldValue != isAtTop {
                onEventAtTopChange(isAtTop)
            }
        }
    }

    var observation: NSKeyValueObservation? = nil

    init(onEventAtTopChange: @escaping (Bool) -> Void) {
        self.onEventAtTopChange = onEventAtTopChange
    }

    @MainActor
    func listOffsetUpdate(verticalAdjustedContentInset: CGFloat, oldOffsetY: CGFloat, newOffsetY: CGFloat) {
        guard newOffsetY != oldOffsetY else { return }
        isAtTop = (newOffsetY - verticalAdjustedContentInset) <= sensitivityThreshold
    }
}

extension View {
    func listScrollObservation(onEventAtTopChange: @escaping (Bool) -> Void) -> some View {
        modifier(ListScrollObservation(onEventAtTopChange: onEventAtTopChange))
    }
}

#Preview {
    struct Container: View {
        @State var expand: Bool = true

        var body: some View {
            ZStack(alignment: .bottomTrailing) {
                List(0..<60) {
                    Text("item \($0)".notLocalized)
                }
                .listScrollObservation {
                    expand = $0
                }

                ComposeButtonView(text: "Compose", isExpanded: $expand) {}
                    .padding(.trailing, 16)
            }
        }
    }

    return Container()
}
