// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation

protocol DiskUsageProtocol {
    var availableCapacity: Measurement<UnitInformationStorage> { get }
    var isLowOnFreeSpace: Bool { get }
}

protocol MemoryUsageProtocol {
    var physicalMemory: UInt { get }
    var usagePercentage: Double { get }
    var used: UInt { get }
}

enum DeviceCapacity {
    struct Disk: DiskUsageProtocol {
        var availableCapacity: Measurement<UnitInformationStorage> {
            let homeDirectoryURL = URL(fileURLWithPath: NSHomeDirectory())
            let bytes = homeDirectoryURL.value(
                forKey: .volumeAvailableCapacityKey,
                keyPath: \.volumeAvailableCapacity
            ) ?? 0
            return .init(value: Double(bytes), unit: .bytes)
        }

        var isLowOnFreeSpace: Bool {
            let lowStorageLimit = Measurement<UnitInformationStorage>(value: 100, unit: .megabytes)
            return availableCapacity < lowStorageLimit
        }
    }

    struct Memory: MemoryUsageProtocol {
        var physicalMemory: UInt {
            UInt(ProcessInfo.processInfo.physicalMemory)
        }

        var usagePercentage: Double {
            Double(used) / Double(physicalMemory)
        }

        var used: UInt {
            var taskInfo = task_vm_info_data_t()
            var outputCount = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size / MemoryLayout<integer_t>.size)

            let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) { taskInfoPointer in
                taskInfoPointer.withMemoryRebound(to: integer_t.self, capacity: 1) { outputPointer in
                    task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), outputPointer, &outputCount)
                }
            }

            assert(result == KERN_SUCCESS)

            return UInt(taskInfo.phys_footprint)
        }

        // Returns the total available memory on device
        var availableMemory: Double {
            var taskInfo = task_vm_info_data_t()
            var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
            _ = withUnsafeMutablePointer(to: &taskInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                    task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
                }
            }
            let usedMegabytes = taskInfo.resident_size / (1_024 * 1_024)
            let totalMb = ProcessInfo.processInfo.physicalMemory / (1_024 * 1_024)
            return Double(totalMb - usedMegabytes)
        }

#if DEBUG
        func test() {
            if #available(iOS 15.0, *) {
                print("You should see this in Xcode under Memory Use:")
                print(used.formatted(.byteCount(style: .memory)))
                print(usagePercentage.formatted(.percent.precision(.fractionLength(2))))
            }
        }
#endif
    }
}
