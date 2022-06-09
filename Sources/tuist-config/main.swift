import Foundation
import ArgumentParser

let path = FileManager.default.currentDirectoryPath + "/Tuist/config.json"
let pathURL = URL(fileURLWithPath: path)
let data = try? Data(contentsOf: pathURL)


struct ConfigOptions: ParsableArguments {

    @Flag(help: "Show config.json content")
    var show = false

    @Flag(help: "Clear config.json content")
    var clear = false

    @Argument(help: "The key")
    var key: String?

    @Argument(help: "The value")
    var value: String?

    @Option(help: "remove key-value from config.json")
    var remove: String?

}

let options = ConfigOptions.parseOrExit()

if options.show {
    if let data = data, let convertedString = String(data: data, encoding: String.Encoding.utf8) {
        print(convertedString)
    } else {
        print("no config file!")
    }
}

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

let cachePath = NSHomeDirectory().appending("/.tuist/Cache/Manifests")
if FileManager.default.fileExists(atPath: cachePath) {
    try FileManager.default.removeItem(atPath: cachePath)
}
