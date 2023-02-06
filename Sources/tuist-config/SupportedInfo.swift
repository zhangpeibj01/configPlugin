//
//  SupportedInfo.swift
//  tuist-config
//
//  Created by zhangpeibj01 on 2022/7/20.
//

import Foundation

struct SupportedInfo: Decodable {
    let name: String
    let valueType: String
    let defaultValue: DefaultValue

    private enum CodingKeys: String, CodingKey {
        case name
        case valueType
        case defaultValue
    }

    enum ValueType: String {
        case bool = "Bool"
        case implictStringList = "ImplictStringList"
    }

    enum DefaultValue: CustomStringConvertible {
        case bool(Bool)
        case implictStringList([String])
        case none

        var description: String {
            switch self {
            case .bool(let value):
                return "\(value)"
            case .implictStringList(let value):
                return "\(value)"
            case .none:
                return "<null>"
            }
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.valueType = try container.decode(String.self, forKey: .valueType)
        let type = ValueType(rawValue: valueType) ?? .implictStringList
        switch type {
        case .bool:
            let value = try container.decodeIfPresent(Bool.self, forKey: .defaultValue)
            if let value = value {
                self.defaultValue = .bool(value)
            } else {
                self.defaultValue = .none
            }
        case .implictStringList:
            if let value = try? container.decodeIfPresent([String].self, forKey: .defaultValue) {
                self.defaultValue = .implictStringList(value)
            } else if let value = try? container.decodeIfPresent(String.self, forKey: .defaultValue) {
                self.defaultValue = .implictStringList([value])
            } else {
                self.defaultValue = .none
            }
        }
    }
}
