import Foundation
import Darwin
import MachO

struct SystemStats: Equatable {
    var cpuPercent: Double = 0
    var memoryUsed: UInt64 = 0
    var memoryTotal: UInt64 = 0
    var storageUsed: UInt64 = 0
    var storageTotal: UInt64 = 0
    var thermalState: ProcessInfo.ThermalState = .nominal
    var fanSpeed: String = "Normal"
    var temperature: String = "N/A"
    var temperatureValue: Double = 0
    var networkPeak: String = "1.2 GB/s"
}

actor SystemMonitor {
    static let shared = SystemMonitor()

    private var timer: Timer?
    private var latest = SystemStats()

    private var previousCPU = host_cpu_load_info()
    private var previousCPUTime = Date.distantPast

    private let smcReader = SMCReader()
    private let hidReader = HIDThermalReader()

    func startMonitoring(interval: TimeInterval = 2.0) {
        timer?.invalidate()
        latest = readCurrentStats()

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                guard let self else { return }
                let stats = await self.readCurrentStats()
                await self.update(stats: stats)
            }
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func currentStats() -> SystemStats { latest }

    private func update(stats: SystemStats) {
        latest = stats
    }

    // MARK: - Readers

    private func readCurrentStats() -> SystemStats {
        var stats = SystemStats()
        stats.cpuPercent = cpuUsage()
        (stats.memoryUsed, stats.memoryTotal) = memoryUsage()
        (stats.storageUsed, stats.storageTotal) = storageUsage()
        stats.thermalState = ProcessInfo.processInfo.thermalState
        stats.fanSpeed = "Normal"
        (stats.temperature, stats.temperatureValue) = temperatureReading()
        stats.networkPeak = mockNetworkPeak()
        return stats
    }

    private func temperatureReading() -> (String, Double) {
        if let celsius = smcReader?.readCPUTemperature() ?? hidReader?.readCPUTemperature() {
            return (String(format: "%.0f°C", celsius), celsius)
        }

        let state = ProcessInfo.processInfo.thermalState
        switch state {
        case .nominal:  return ("Nominal", 35)
        case .fair:     return ("Fair", 50)
        case .serious:  return ("Serious", 70)
        case .critical: return ("Critical", 85)
        @unknown default: return ("N/A", 0)
        }
    }

    private func cpuUsage() -> Double {
        var cpuInfo = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &cpuInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }

        let user = Double(cpuInfo.cpu_ticks.0)
        let system = Double(cpuInfo.cpu_ticks.1)
        let idle = Double(cpuInfo.cpu_ticks.2)
        let nice = Double(cpuInfo.cpu_ticks.3)
        let totalTicks = user + system + idle + nice

        let previousTotal = Double(previousCPU.cpu_ticks.0 + previousCPU.cpu_ticks.1 + previousCPU.cpu_ticks.2 + previousCPU.cpu_ticks.3)
        let delta = totalTicks - previousTotal
        let busy = (user + system + nice) - (Double(previousCPU.cpu_ticks.0 + previousCPU.cpu_ticks.1 + previousCPU.cpu_ticks.3))

        previousCPU = cpuInfo
        let now = Date()
        let _ = now.timeIntervalSince(previousCPUTime)
        previousCPUTime = now

        guard delta > 0 else { return 0 }
        return min(max((busy / delta) * 100, 0), 100)
    }

    private func memoryUsage() -> (used: UInt64, total: UInt64) {
        var info = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return (0, 0) }

        let pageSize = UInt64(getpagesize())
        let used = UInt64(info.active_count + info.inactive_count + info.wire_count) * pageSize
        let total = UInt64(info.active_count + info.inactive_count + info.wire_count + info.free_count) * pageSize
        return (used, total)
    }

    private func storageUsage() -> (used: UInt64, total: UInt64) {
        let home = URL(fileURLWithPath: NSHomeDirectory())
        do {
            let values = try home.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
            let total = UInt64(values.volumeTotalCapacity ?? 0)
            let available = UInt64(values.volumeAvailableCapacity ?? 0)
            let used = total > available ? total - available : 0
            return (used, total)
        } catch {
            return (0, 0)
        }
    }

    private func mockNetworkPeak() -> String {
        let variation = Double.random(in: -0.05...0.05)
        let value = max(0, 1.2 + variation)
        return String(format: "%.1f GB/s", value)
    }
}
