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
import SwiftUI

final class LabelPickerModel: ObservableObject {
    typealias OnDoneTap = (_ selectedLabelIds: Set<PMLocalLabelId>, _ alsoArchive: Bool) -> Void

    @Published private(set) var labels: [CustomLabelUIModel]

    private let model: CustomLabelModel
    private var selectedLabelIds: [PMLocalLabelId: Quantifier]
    private let onDone: OnDoneTap
    private var cancellables = Set<AnyCancellable>()

    init(
        model: CustomLabelModel,
        labels: [CustomLabelUIModel] = [],
        labelIdsByItem: [Set<PMLocalLabelId>] = [],
        onDoneTap: @escaping OnDoneTap
    ) {
        self.model = model
        self.labels = labels
        self.selectedLabelIds = [:]
        self.onDone = onDoneTap
        initialiseSelectedLabelIds(labelIdsByItem: labelIdsByItem)
        setUpObservers()
    }

    private func initialiseSelectedLabelIds(labelIdsByItem: [Set<PMLocalLabelId>]) {
        selectedLabelIds = labelIdsByItem
            .reduce([PMLocalLabelId: Int](), { partialResult, currentItem in
                var newPartialResult = partialResult
                currentItem.forEach { labelId in
                    if let count = newPartialResult[labelId] {
                        newPartialResult[labelId] = count + 1
                    } else {
                        newPartialResult[labelId] = 1
                    }
                }
                return newPartialResult
            })
            .mapValues {
                $0 == labelIdsByItem.count ? .all : .some
            }
    }

    private func setUpObservers() {
        model
            .labelsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] customLabels in
                guard let self else { return }
                let selectedIds = selectedLabelIds
                self.labels = customLabels.map {
                    $0.toCustomLabelUIModel(selectedIds: selectedIds)
                }
            }
            .store(in: &cancellables)
    }

    func fetchLabels() async {
        await model.fetchLabels()
    }

    func onLabelTap(labelId: PMLocalLabelId) async {
        if selectedLabelIds.keys.contains(labelId) {
            selectedLabelIds.removeValue(forKey: labelId)
        } else {
            selectedLabelIds.updateValue(.all, forKey: labelId)
        }
        await fetchLabels()
    }

    func onDoneTap(alsoArchive: Bool) async {
        onDone(Set(selectedLabelIds.keys), alsoArchive)
    }
}
