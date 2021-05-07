//
//  PMActionSheetHeaderModel.swift
//  PMUIFoundations
//
//  Created by Aaron Huánuco on 20/08/2020.
//

public struct PMActionSheetHeaderModel {
    public let title: String
    public let subtitle: String?
    public let leftItem: PMActionSheetPlainItem?
    public let rightItem: PMActionSheetPlainItem?
    public let hasSeparator: Bool

    public init(title: String, subtitle: String?, leftItem: PMActionSheetPlainItem?, rightItem: PMActionSheetPlainItem?, hasSeparator: Bool) {
        self.title = title
        self.subtitle = subtitle
        self.leftItem = leftItem
        self.rightItem = rightItem
        self.hasSeparator = hasSeparator
    }
}

extension PMActionSheetHeaderModel {
    public static func makeView(from model: PMActionSheetHeaderModel?) -> PMActionSheetHeaderView? {
        guard let model = model else { return nil }
        return PMActionSheetHeaderView(title: model.title, subtitle: model.subtitle, leftItem: model.leftItem, rightItem: model.rightItem, hasSeparator: model.hasSeparator)
    }
}
