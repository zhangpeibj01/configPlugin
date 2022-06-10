import Foundation
import ArgumentParser

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
        } else if value.hasPrefix("[") && value.hasSuffix("]") {
            let start = value.index(value.startIndex, offsetBy: 1)
            let end = value.index(value.endIndex, offsetBy: -1)
            json[key] = String(value[start...end]).replacingOccurrences(of: " ", with: "").components(separatedBy: ",")
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
                        print("true")
                    } else if type(of: value) == type(of: NSNumber(value: false)) {
                        print("false")
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

if
    !options.aid,
    let data = data,
    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

    print("--------------------------current supported config--------------------------")
    let supportedKeys = ["key", "mockAllModules", "focusModules", "mockModules", "integrateSwiftLint", "uploadBuildLog", "keepAllTargets", "previewMode", "enableRemoteCache", "remoteCacheProducer", "remotePreviewResumeCacheProducer"]
    let keyNumberMaxCount = (supportedKeys.map { $0.count }.max() ?? 0) + 4
    let realSupportedValues = supportedKeys.map { (value) -> String in
        if let currentValue = json[value] {
            if type(of: currentValue) == type(of: NSNumber(value: true)) {
                return "true"
            } else if type(of: currentValue) == type(of: NSNumber(value: false)) {
                return "false"
            } else if let array = currentValue as? [String] {
                return array.joined(separator: ",")
            } else {
                return "\(currentValue)"
            }
        } else {
            return "<null>"
        }
    }
    var supportedValues = ["value"]
    supportedValues.append(contentsOf: realSupportedValues)
    let valueNumberMaxCount = (supportedValues.map { $0.count }.max() ?? 0) + 4
    let defaultedValues = ["defaultValue", "false", "[]", "[]", "false", "false", "true", "false", "false", "false", "false"]
    let defaultedValueMaxCount = (defaultedValues.map { $0.count }.max() ?? 0)
    supportedKeys.enumerated().forEach { (index, key) in
        print("|\(key.padding(toLength: keyNumberMaxCount, withPad: " ", startingAt: 0))|\(supportedValues[index].padding(toLength: valueNumberMaxCount, withPad: " ", startingAt: 0))|\(defaultedValues[index].padding(toLength: defaultedValueMaxCount, withPad: " ", startingAt: 0))")
    }
    print("--------------------------current not supported config--------------------------")
    var notSupportedKeys = ["key"]
    var notSupportedValues = ["value"]
    json.forEach { (key, value) in
        if !supportedKeys.contains(key) {
            notSupportedKeys.append(key)
            let newValue = { () -> String in
                if type(of: value) == type(of: NSNumber(value: true)) {
                    return "true"
                } else if type(of: value) == type(of: NSNumber(value: false)) {
                    return "false"
                } else if let array = value as? [String] {
                    return array.joined(separator: ",")
                } else {
                    return "\(value)"
                }
            }()
            notSupportedValues.append(newValue)
        }
    }
    let notSupportedKeyNumberMaxCount = (notSupportedKeys.map { $0.count }.max() ?? 0) + 4
    let notSupportedValueNumberMaxCount = (notSupportedValues.map { $0.count }.max() ?? 0) + 4
    notSupportedKeys.enumerated().forEach { (index, key) in
        print("|\(key.padding(toLength: notSupportedKeyNumberMaxCount, withPad: " ", startingAt: 0))|\(notSupportedValues[index].padding(toLength: notSupportedValueNumberMaxCount, withPad: " ", startingAt: 0))")
    }
}
