//
//  BLEdeviceCentralManagerDelegate.swift
//  BLEdevice
//
//  Created by Ivan Brazhnikov on 07/08/2017.
//  Copyright © 2017 Ivan Brazhnikov. All rights reserved.
//

import Foundation

public protocol BLEdeviceCentralManagerDelegate : class {
  func bleDeviceManagerDidUpdateState(_ manager: BLEdeviceCentralManager)
  func bleDeviceManager(_ manager: BLEdeviceCentralManager, didDiscoverDevice device: BLEdevice, rssi: NSNumber)
  func bleDeviceManager(_ manager: BLEdeviceCentralManager, didConnectDevice device: BLEdevice)
  func bleDeviceManager(_ manager: BLEdeviceCentralManager, didDisconnectDevice device: BLEdevice, error: Error?)
  func bleDeviceManager(_ manager: BLEdeviceCentralManager, didFailToConnect device: BLEdevice, error: Error?)
  func bleDeviceManager(_ manager: BLEdeviceCentralManager, willRestoreDevices devices: [BLEdevice])
}
