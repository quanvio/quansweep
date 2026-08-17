import Foundation
import IOKit

/// Minimal SMC reader used to fetch CPU proximity temperature.
///
/// On Intel Macs the AppleSMC service is usually reachable and exposes
/// CPU temperature keys. On Apple Silicon the service may exist but CPU
/// temperature keys are not publicly exposed; in that case the caller
/// should fall back to `ProcessInfo.thermalState` or HIDThermalReader.
final class SMCReader {

    private var connection: io_connect_t = 0

    init?() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault,
                                                  IOServiceMatching("AppleSMC"))
        guard service != 0 else { return nil }

        let status = IOServiceOpen(service, mach_task_self_, 0, &connection)
        IOObjectRelease(service)
        guard status == kIOReturnSuccess else { return nil }
    }

    deinit {
        if connection != 0 {
            IOServiceClose(connection)
        }
    }

    /// Returns the first available CPU temperature in Celsius, or nil.
    func readCPUTemperature() -> Double? {
        // Intel CPU temperature keys.
        let intelKeys = ["TC0C", "TC0D", "TC0E", "TC0F", "TC0P", "TCPC"]
        // Apple Silicon performance / efficiency core temperature keys.
        // These are not officially documented and may not be reachable from
        // user space on newer machines, but we try them before falling back.
        let appleSiliconKeys = ["Tp0a", "Tp0b", "Tp0c", "Tp0d", "Tp0e", "Tp0f",
                                "Tp1a", "Tp1b", "Tp1c", "Tp1d", "Tp1e", "Tp1f",
                                "Tc0a", "Tc0b", "Tc0c", "Tc0d", "Tc0e", "Tc0f"]
        let keys = intelKeys + appleSiliconKeys
        for key in keys {
            if let value = readFloat(key) {
                return value
            }
        }
        return nil
    }

    // MARK: - Private helpers

    private func readFloat(_ key: String) -> Double? {
        guard key.count == 4 else { return nil }
        let code = FourCharCode(from: key)

        guard let info = keyInfo(code) else { return nil }
        guard info.dataType == FourCharCode(from: "sp78") ||
              info.dataType == FourCharCode(from: "sp87") ||
              info.dataType == FourCharCode(from: "sp96") ||
              info.dataType == FourCharCode(from: "flt ") else {
            return nil
        }

        var input = SMCKeyData(key: code)
        var output = SMCKeyData()
        let inputSize = MemoryLayout<SMCKeyData>.size
        var outputSize = MemoryLayout<SMCKeyData>.size

        let result = IOConnectCallStructMethod(connection, SMCSelector.readKey,
                                               &input, inputSize,
                                               &output, &outputSize)
        guard result == kIOReturnSuccess else { return nil }

        return parseTemperature(info: info, bytes: output.bytes)
    }

    private func keyInfo(_ key: FourCharCode) -> SMCKeyInfoData? {
        var input = SMCKeyData(key: key, data8: SMCSelector.getKeyInfo)
        var output = SMCKeyData()
        let inputSize = MemoryLayout<SMCKeyData>.size
        var outputSize = MemoryLayout<SMCKeyData>.size

        let result = IOConnectCallStructMethod(connection, SMCSelector.readKey,
                                               &input, inputSize,
                                               &output, &outputSize)
        guard result == kIOReturnSuccess else { return nil }
        return output.keyInfo
    }

    private func parseTemperature(info: SMCKeyInfoData, bytes: SMCBytes) -> Double? {
        var data = [UInt8](repeating: 0, count: 32)
        withUnsafeBytes(of: bytes) { raw in
            data = Array(raw.bindMemory(to: UInt8.self))
        }

        if info.dataType == FourCharCode(from: "flt ") {
            guard info.dataSize >= 4 else { return nil }
            return Double(Float(bitPattern: UInt32(littleEndianBytes: Array(data[0..<4]))))
        }

        // Most temperature keys are fixed-point sp78 (signed 7.8) or similar.
        guard info.dataSize >= 2 else { return nil }
        let integerPart    = Int8(bitPattern: data[0])
        let fractionalPart = data[1]
        return Double(integerPart) + Double(fractionalPart) / 256.0
    }
}

// MARK: - SMC data structures

/// These layouts mirror the AppleSMC user-client structs used by
/// tools such as smcFanControl and iStats.
private struct SMCVersion {
    var major: UInt8 = 0
    var minor: UInt8 = 0
    var build: UInt8 = 0
    var reserved: UInt8 = 0
    var release: UInt16 = 0
}

private struct SMCPLimitData {
    var version: UInt16 = 0
    var length: UInt16 = 0
    var cpuPLimit: UInt32 = 0
    var gpuPLimit: UInt32 = 0
    var memPLimit: UInt32 = 0
}

private struct SMCKeyInfoData {
    var dataSize: UInt32 = 0
    var dataType: UInt32 = 0
    var dataAttributes: UInt8 = 0
}

private typealias SMCBytes = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                              UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                              UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                              UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)

private struct SMCKeyData {
    var key: UInt32 = 0
    var vers = SMCVersion()
    var pLimitData = SMCPLimitData()
    var keyInfo = SMCKeyInfoData()
    var result: UInt8 = 0
    var status: UInt8 = 0
    var data8: UInt8 = 0
    var data32: UInt32 = 0
    var bytes: SMCBytes = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                           0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
}

private enum SMCSelector {
    static let readKey: UInt32 = 5
    static let getKeyInfo: UInt8 = 9
}

private extension FourCharCode {
    init(from string: String) {
        precondition(string.count == 4, "FourCharCode must be exactly 4 characters")
        var code: FourCharCode = 0
        for char in string.utf8 {
            code = (code << 8) + FourCharCode(char)
        }
        self = code
    }
}

private extension UInt32 {
    init(littleEndianBytes bytes: [UInt8]) {
        precondition(bytes.count >= 4)
        self = (UInt32(bytes[3]) << 24) |
               (UInt32(bytes[2]) << 16) |
               (UInt32(bytes[1]) << 8)  |
                UInt32(bytes[0])
    }
}
