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
    var availableCapacity: ByteCount { get }
    var isLowOnFreeSpace: Bool { get }
}

protocol MemoryUsageProtocol {
    var physicalMemory: UInt { get }
    var usagePercentage: Double { get }
    var used: UInt { get }
}

enum DeviceCapacity {
    struct Disk: DiskUsageProtocol {
        var availableCapacity: ByteCount {
            let homeDirectoryURL = URL(fileURLWithPath: NSHomeDirectory())
            return homeDirectoryURL.value(forKey: .volumeAvailableCapacityKey, keyPath: \.volumeAvailableCapacity) ?? 0
        }

        var isLowOnFreeSpace: Bool {
            let lowStorageLimit = 100_000_000
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
