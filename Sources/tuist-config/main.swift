import Foundation
import ArgumentParser
import SwiftyTextTable

let path = FileManager.default.currentDirectoryPath + "/Tuist/config.json"
let pathURL = URL(fileURLWithPath: path)
var data: Data? { try? Data(contentsOf: pathURL) }


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
        } else if key == "focusModules" || key == "mockModules" {
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
    SupportedConfig.supportedKeyValues.forEach { (supportedKey, supportedValue) in
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
        supportedTable.append(SupportedConfig(name: supportedKey, value: currentValue, defaultValue: supportedValue))
    }
    print(supportedTable.renderTextTable())

    var notSupportedTable = [NotSupportedConfig]()
    json.forEach { (key, value) in
        if !SupportedConfig.supportedKeyValues.map ({ $0.0 }).contains(key) {
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
    if !notSupportedTable.isEmpty {
        print(notSupportedTable.renderTextTable())
    }
}


struct SupportedConfig {
    let name: String
    let value: String
    let defaultValue: String

    static let supportedKeyValues = [("mockAllModules", "false"), ("focusModules", "<null>"), ("mockModules", "[]"), ("integrateSwiftLint", "true"), ("uploadBuildLog", "false"), ("keepAllTargets", "true"), ("previewMode", "false"), ("enableRemoteCache", "false"), ("remoteCacheProducer", "false"), ("remotePreviewResumeCacheProducer", "false")]
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
