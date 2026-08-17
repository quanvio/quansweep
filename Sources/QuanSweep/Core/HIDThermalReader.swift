import Foundation
import IOKit

// MARK: - IOKit HID private SPI declarations

// These functions are part of IOKit's HID event system. They are not in the
// public Swift headers, but they are present in the framework and are used by
// open-source tools such as Stats and iStat Menus to read Apple Silicon
// temperatures without elevated privileges.

typealias IOHIDEventSystemClientRef = OpaquePointer
typealias IOHIDServiceClientRef = OpaquePointer
typealias IOHIDEventRef = OpaquePointer
typealias IOHIDFloat = Double

@_silgen_name("IOHIDEventSystemClientCreate")
func IOHIDEventSystemClientCreate(_ allocator: CFAllocator?) -> IOHIDEventSystemClientRef?

@_silgen_name("IOHIDEventSystemClientSetMatching")
func IOHIDEventSystemClientSetMatching(_ client: IOHIDEventSystemClientRef, _ match: CFDictionary) -> Int32

@_silgen_name("IOHIDEventSystemClientCopyServices")
func IOHIDEventSystemClientCopyServices(_ client: IOHIDEventSystemClientRef) -> Unmanaged<CFArray>?

@_silgen_name("IOHIDServiceClientCopyProperty")
func IOHIDServiceClientCopyProperty(_ service: IOHIDServiceClientRef, _ property: CFString) -> Unmanaged<AnyObject>?

@_silgen_name("IOHIDServiceClientCopyEvent")
func IOHIDServiceClientCopyEvent(_ service: IOHIDServiceClientRef,
                                 _ type: Int64,
                                 _ field: Int32,
                                 _ options: Int64) -> Unmanaged<AnyObject>?

@_silgen_name("IOHIDEventGetFloatValue")
func IOHIDEventGetFloatValue(_ event: IOHIDEventRef, _ field: Int32) -> IOHIDFloat

private let kIOHIDEventTypeTemperature: Int64 = 15

private func IOHIDEventFieldBase(_ type: Int64) -> Int32 {
    return Int32(type << 16)
}

// MARK: - Reader

/// Reads CPU/GPU thermal sensors exposed through the HID event system.
/// This works on Apple Silicon Macs where the SMC does not expose CPU keys.
final class HIDThermalReader {

    private let client: IOHIDEventSystemClientRef?

    init?() {
        // Different Mac models expose thermal sensors under slightly different
        // HID usage combinations. Try the most specific first, then fall back to
        // the broader vendor page so we still pick up sensors on newer machines.
        let profiles: [[String: Any]] = [
            ["PrimaryUsagePage": Int32(0xff00), "PrimaryUsage": Int32(0x0005)],
            ["PrimaryUsagePage": Int32(0xff00), "PrimaryUsage": Int32(0x0008)],
            ["PrimaryUsagePage": Int32(0xff00)]
        ]

        for profile in profiles {
            guard let candidate = IOHIDEventSystemClientCreate(kCFAllocatorDefault) else {
                continue
            }

            _ = IOHIDEventSystemClientSetMatching(candidate, profile as CFDictionary)

            if let servicesRef = IOHIDEventSystemClientCopyServices(candidate) {
                let services = servicesRef.takeRetainedValue()
                if CFArrayGetCount(services) > 0 {
                    self.client = candidate
                    return
                }
            }

            Unmanaged<AnyObject>.passUnretained(unsafeBitCast(candidate, to: AnyObject.self)).release()
        }

        return nil
    }

    deinit {
        if let client = client {
            Unmanaged<AnyObject>.passUnretained(unsafeBitCast(client, to: AnyObject.self)).release()
        }
    }

    /// Lists discovered CPU thermal sensors for debugging.
    func listSensors() -> [(name: String, temperature: Double)] {
        guard let client = client,
              let servicesRef = IOHIDEventSystemClientCopyServices(client) else {
            return []
        }
        let services = servicesRef.takeRetainedValue()

        let count = CFArrayGetCount(services)
        var results: [(name: String, temperature: Double)] = []

        for i in 0..<count {
            let rawService = CFArrayGetValueAtIndex(services, i)
            let service = unsafeBitCast(rawService!, to: IOHIDServiceClientRef.self)

            guard let nameRef = IOHIDServiceClientCopyProperty(service, "Product" as CFString) else {
                continue
            }
            let name = nameRef.takeRetainedValue() as? String ?? ""

            guard Self.isCPUSensor(name: name) else { continue }

            guard let eventRef = IOHIDServiceClientCopyEvent(service,
                                                             kIOHIDEventTypeTemperature,
                                                             0,
                                                             0) else {
                continue
            }
            let event = unsafeBitCast(eventRef.takeRetainedValue(), to: IOHIDEventRef.self)

            let temp = IOHIDEventGetFloatValue(event, IOHIDEventFieldBase(kIOHIDEventTypeTemperature))
            if temp > 0 {
                results.append((name, temp))
            }
        }

        return results
    }

    private static func isCPUSensor(name: String) -> Bool {
        let lower = name.lowercased()
        return lower.contains("pacc") ||
               lower.contains("eacc") ||
               lower.contains("cpu") ||
               lower.contains("soc mtr") ||
               lower.contains("soc die") ||
               lower.contains("ane mtr") ||
               lower.contains("isp mtr")
    }

    /// Returns the average temperature of CPU-related sensors, or nil.
    func readCPUTemperature() -> Double? {
        guard let client = client,
              let servicesRef = IOHIDEventSystemClientCopyServices(client) else {
            return nil
        }
        let services = servicesRef.takeRetainedValue()

        let count = CFArrayGetCount(services)
        var temperatures: [Double] = []

        for i in 0..<count {
            let rawService = CFArrayGetValueAtIndex(services, i)
            let service = unsafeBitCast(rawService!, to: IOHIDServiceClientRef.self)

            guard let nameRef = IOHIDServiceClientCopyProperty(service, "Product" as CFString) else {
                continue
            }
            let name = nameRef.takeRetainedValue() as? String ?? ""

            guard Self.isCPUSensor(name: name) else { continue }

            guard let eventRef = IOHIDServiceClientCopyEvent(service,
                                                             kIOHIDEventTypeTemperature,
                                                             0,
                                                             0) else {
                continue
            }
            let event = unsafeBitCast(eventRef.takeRetainedValue(), to: IOHIDEventRef.self)

            let temp = IOHIDEventGetFloatValue(event, IOHIDEventFieldBase(kIOHIDEventTypeTemperature))
            if temp > 0 {
                temperatures.append(temp)
            }
        }

        guard !temperatures.isEmpty else { return nil }
        return temperatures.reduce(0, +) / Double(temperatures.count)
    }
}
