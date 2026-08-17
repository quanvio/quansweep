import Foundation

enum FileSystem {
    static func directorySize(at path: String) -> UInt64 {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else { return 0 }

        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: path, isDirectory: &isDir)

        if !isDir.boolValue {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
               let size = attrs[.size] as? UInt64 {
                return size
            }
            return 0
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/du")
        task.arguments = ["-sk", path]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8),
               let firstPart = output.split(separator: "\t").first,
               let kb = UInt64(firstPart.trimmingCharacters(in: .whitespaces)) {
                return kb * 1024
            }
        } catch {
            return fallbackDirectorySize(at: url)
        }

        return 0
    }

    static func fallbackDirectorySize(at url: URL) -> UInt64 {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var total: UInt64 = 0
        for case let fileURL as URL in enumerator {
            if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
               values.isRegularFile == true,
               let size = values.fileSize {
                total += UInt64(size)
            }
        }
        return total
    }

    static func modificationDate(at path: String) -> Date? {
        let url = URL(fileURLWithPath: path)
        if let values = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
           let date = values.contentModificationDate {
            return date
        }
        return nil
    }

    static func contentsOfDirectory(at path: String) -> [String] {
        (try? FileManager.default.contentsOfDirectory(atPath: path)) ?? []
    }

    static func fileExists(at path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
}
