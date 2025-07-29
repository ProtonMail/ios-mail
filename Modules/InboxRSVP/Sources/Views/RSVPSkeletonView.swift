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

struct RSVPSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            VStack(alignment: .leading, spacing: DS.Spacing.large) {
                eventHeader
                    .padding(.horizontal, DS.Spacing.extraLarge)
                answerSection
                    .padding(.bottom, DS.Spacing.small)
                    .padding(.horizontal, DS.Spacing.extraLarge)
                eventDetailsSection
                    .padding(.horizontal, DS.Spacing.large)
            }
            .padding(.top, DS.Spacing.extraLarge)
            .padding(.bottom, DS.Spacing.large)
        }
        .background(DS.Color.Background.norm)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.extraLarge))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.extraLarge)
                .stroke(DS.Color.Border.norm, lineWidth: 1)
        )
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DS.Spacing.large)
    }

    private var eventHeader: some View {
        HStack(alignment: .top, spacing: DS.Spacing.medium) {
            VStack(alignment: .leading, spacing: DS.Spacing.standard) {
                rectangleView(height: 20)
                rectangleView(height: 18)
                rectangleView(height: 16)
            }
            Spacer()
            rectangleView(width: 52, height: 52, cornerRadius: DS.Radius.extraLarge)
        }
    }

    private var answerSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.mediumLight) {
            rectangleView(width: 80, height: 16)

            HStack(spacing: DS.Spacing.small) {
                ForEach(0..<3) { _ in
                    rectangleView(height: 40, cornerRadius: DS.Radius.massive)
                }
            }
        }
        .padding(.bottom, DS.Spacing.small)
    }

    private var eventDetailsSection: some View {
        VStack(alignment: .leading, spacing: .zero) {
            ForEach(0..<3) { _ in
                HStack(alignment: .center, spacing: DS.Spacing.medium) {
                    rectangleView(width: 24, height: 20, cornerRadius: DS.Radius.medium)
                    rectangleView(height: 18, cornerRadius: DS.Radius.medium)
                }
                .padding(.vertical, DS.Spacing.standard)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func rectangleView(
        width: CGFloat? = nil,
        height: CGFloat,
        cornerRadius: CGFloat = DS.Radius.large
    ) -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .flashing()
    }
}

private extension View {
    func flashing() -> some View {
        modifier(Flashing())
    }
}

private struct Flashing: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 0.4 : 1.0)
            .onLoad { isAnimating = true }
            .animation(.linear(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
    }
}

#Preview {
    ScrollView(.vertical, showsIndicators: false) {
        VStack(spacing: 16) {
            RSVPSkeletonView()
        }
    }
}
