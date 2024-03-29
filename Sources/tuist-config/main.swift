import Foundation
import ArgumentParser
import SwiftyTextTable

let path = FileManager.default.currentDirectoryPath + "/Tuist/config.json"
let pathURL = URL(fileURLWithPath: path)
var data: Data? { try? Data(contentsOf: pathURL) }

let supportedFilePathURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath + "/Tuist/supportedConfig.json")
var supportedInfoList: [SupportedInfo] {
    if let data = try? Data(contentsOf: supportedFilePathURL) {
        let result = try? JSONDecoder().decode([SupportedInfo].self, from: data)
        return result ?? []
    } else {
        return []
    }
}
var supportedKeyValues: [(String, String)] {
    supportedInfoList.map { info in
        return (info.name, "\(info.defaultValue)")
    }
}

struct ConfigOptions: ParsableArguments {

    @Argument(help: "The key")
    var key: String?

    @Argument(help: "The value")
    var value: String?

    @Option(help: "remove key-value from config.json")
    var remove: String?

    @Flag(help: "help")
    var aid = false

    @Flag(help: "Clear config.json content")
    var clear = false
}

let options = ConfigOptions.parseOrExit()

if options.clear {
    if FileManager.default.fileExists(atPath: pathURL.path) {
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch { print("clear failed!") }
        print("clear succeed")
    } else {
        print("no config file!")
    }
}

if let key = options.key {
    if let value = options.value {
        var json: [String: Any] = {
            if
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            {
                return json
            } else {
                return [String: Any]()
            }
        }()

        if let boolValue = Bool(value) {
            json[key] = boolValue
        } else if let int64Value = Int64(value) {
            json[key] = int64Value
        } else if key == "focusModules" || key == "mockModules" || key == "additionalFocusModules" {
            if value == "[]" {
                json[key] = [String]()
            } else {
                json[key] = String(value).components(separatedBy: ",")
            }
        } else if value.hasPrefix("[") && value.hasSuffix("]") {
            if value.count == 2 {
                json[key] = [String]()
            } else {
                let start = value.index(value.startIndex, offsetBy: 1)
                let end = value.index(value.startIndex, offsetBy: value.count - 2)
                json[key] = String(value[start...end]).replacingOccurrences(of: " ", with: "").components(separatedBy: ",")
            }
        } else {
            json[key] = value
        }

        if let newData = try? JSONSerialization.data(withJSONObject: json) {
            if FileManager.default.fileExists(atPath: pathURL.path) {
                do {
                    try FileManager.default.removeItem(atPath: path)
                } catch { }
            }
            if !FileManager.default.fileExists(atPath: pathURL.path) {
                FileManager.default.createFile(atPath: pathURL.path, contents: newData, attributes: nil)
                print("add config item \(key) succeed")
            } else {
                print("add config item \(key) failed")
            }
        } else {
            print("add config item \(key) failed")
        }
    } else {
        if let data = data {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let value = json[key] {
                    if type(of: value) == type(of: NSNumber(value: true)) {
                        let result = value as? Bool ?? false
                        print("\(result)")
                    } else {
                        print(value)
                    }
                } else {
                    print("no such config item")
                }
            } else {
                print("trans data to json object failed")
            }
        } else {
            print("no config file!")
        }
    }
}

if
    let remove = options.remove,
    let data = data,
    var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
{
    if json[remove] == nil {
        print("no such config item!")
    } else {
        json[remove] = nil
        if let newData = try? JSONSerialization.data(withJSONObject: json) {
            if FileManager.default.fileExists(atPath: pathURL.path) {
                do {
                    try FileManager.default.removeItem(atPath: path)
                } catch { }
            }
            if !FileManager.default.fileExists(atPath: pathURL.path) {
                FileManager.default.createFile(atPath: pathURL.path, contents: newData, attributes: nil)
                print("remove config item \(remove) succeed")
            } else {
                print("remove config item \(remove) failed")
            }
        } else {
            print("remove config item \(remove) failed")
        }
    }
}

if options.aid {
    print("SUBCOMMANDS")
    print("\("key".padding(toLength: 20, withPad: " ", startingAt: 0))the config key")
    print("\("value".padding(toLength: 20, withPad: " ", startingAt: 0))the config value")
    print("\("remove".padding(toLength: 20, withPad: " ", startingAt: 0))remove key-value from config")
    print("\("clear".padding(toLength: 20, withPad: " ", startingAt: 0))clear all configs")
}

let cachePath = NSHomeDirectory().appending("/.tuist/Cache/Manifests")
if FileManager.default.fileExists(atPath: cachePath) {
    try FileManager.default.removeItem(atPath: cachePath)
}

if !options.aid {
    let json = { () -> [String: Any] in
        if let data = data {
            return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
        } else {
            return [:]
        }
    }()
    var supportedTable = [SupportedConfig]()
    var focusStates = [FocusState]()
    var notSupportFocusStates = [NotSupportedFocusState]()
    if
        let focusModulesSupported = supportedInfoList.filter({ $0.name == "focusModules" }).first,
        case . implictStringList(let focusModulesList) = focusModulesSupported.defaultValue
    {
        if let value = json["focusModules"] as? [String] {
            focusStates = focusModulesList.map { focusModule in
                .init(focus: focusModule, state: value.contains(focusModule))
            }
            notSupportFocusStates = value.compactMap { currentValue in
                if !focusModulesList.contains(currentValue) {
                    return .init(focus: currentValue, state: true)
                } else {
                    return nil
                }
            }
        } else if let value = json["mockModules"] as? [String] {
            focusStates = focusModulesList.map { focusModule in
                .init(focus: focusModule, state: !value.contains(focusModule))
            }
            notSupportFocusStates = value.compactMap { currentValue in
                if !focusModulesList.contains(currentValue) {
                    return .init(focus: currentValue, state: false)
                } else {
                    return nil
                }
            }
        }
        if focusStates.isEmpty {
            focusStates = focusModulesList.map { focusModule in
                .init(focus: focusModule, state: true)
            }
        }
    }

    supportedKeyValues.forEach { (supportedKey, supportedValue) in
        let currentValue = { () -> String in
            if let value = json[supportedKey] {
                if type(of: value) == type(of: NSNumber(value: true)) {
                    let result = value as? Bool ?? false
                    return "\(result)"
                } else if let array = value as? [String] {
                    return array.joined(separator: ",")
                } else {
                    return "\(value)"
                }
            } else {
                return "<null>"
            }
        }()
        if supportedKey != "focusModules" {
            supportedTable.append(SupportedConfig(name: supportedKey, value: currentValue, defaultValue: supportedValue))
        }
    }
    print(supportedTable.renderTextTable())

    var notSupportedTable = [NotSupportedConfig]()
    json.forEach { (key, value) in
        if !supportedKeyValues.map ({ $0.0 }).contains(key) {
            let newValue = { () -> String in
                if type(of: value) == type(of: NSNumber(value: true)) {
                    let result = value as? Bool ?? false
                    return "\(result)"
                } else if let array = value as? [String] {
                    return array.joined(separator: ",")
                } else {
                    return "\(value)"
                }
            }()
            notSupportedTable.append(NotSupportedConfig(name: key, value: newValue))
        }
    }
    notSupportedTable = notSupportedTable.filter { $0.name != "mockModules" }
    if !notSupportedTable.isEmpty {
        print(notSupportedTable.renderTextTable())
    }
    print(focusStates.renderTextTable())
    if !notSupportFocusStates.isEmpty {
        print(notSupportFocusStates.renderTextTable())
    }
}
