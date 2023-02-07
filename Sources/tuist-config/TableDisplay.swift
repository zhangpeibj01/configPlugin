//
//  TableDisplay.swift
//  tuist-config
//
//  Created by zhangpeibj01 on 2022/7/20.
//

import Foundation
import SwiftyTextTable

struct SupportedConfig {
    let name: String
    let value: String
    let defaultValue: String
}

extension SupportedConfig: TextTableRepresentable {
    static var columnHeaders: [String] {
        return ["key", "value", "defaultValue"]
    }

    var tableValues: [CustomStringConvertible] {
        return [name, value, defaultValue]
    }

    static var tableHeader: String? {
      return "current supported config"
    }
}

struct NotSupportedConfig {
    let name: String
    let value: String
}

extension NotSupportedConfig: TextTableRepresentable {
    static var columnHeaders: [String] {
        return ["key", "value"]
    }

    var tableValues: [CustomStringConvertible] {
        return [name, value]
    }

    static var tableHeader: String? {
      return "others"
    }
}

struct FocusState {
    let focus: String
    let state: Bool
}

extension FocusState: TextTableRepresentable {
    static var columnHeaders: [String] {
        return ["moduleName", "isFocus"]
    }

    var tableValues: [CustomStringConvertible] {
        return [focus, state ? "✔️" : "✖️"]
    }

    static var tableHeader: String? {
      return "focusModules"
    }
}


struct NotSupportedFocusState {
    let focus: String
    let state: Bool
}

extension NotSupportedFocusState: TextTableRepresentable {
    static var columnHeaders: [String] {
        return ["moduleName", "isFocus"]
    }

    var tableValues: [CustomStringConvertible] {
        return [focus, state ? "✔️" : "✖️"]
    }

    static var tableHeader: String? {
      return "NotSupportFocusModules"
    }
}
