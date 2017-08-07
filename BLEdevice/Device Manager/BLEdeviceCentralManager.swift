//
//  BLEdeviceManager.swift
//  BLEdevice
//
//  Created by Ivan Brazhnikov on 04.02.17.
//  Copyright © 2017 Ivan Brazhnikov. All rights reserved.
//


import Foundation
import CoreBluetooth

public protocol BLEdeviceCentralManagerDelegate : class {
  func bleDeviceManagerDidUpdateState(_ manager: BLEdeviceCentralManager)
  func bleDeviceManager(_ manager: BLEdeviceCentralManager, didDiscoverDevice device: BLEdevice, rssi: NSNumber)
  func bleDeviceManager(_ manager: BLEdeviceCentralManager, didConnectDevice device: BLEdevice)
  func bleDeviceManager(_ manager: BLEdeviceCentralManager, didDisconnectDevice device: BLEdevice, error: Error?)
  func bleDeviceManager(_ manager: BLEdeviceCentralManager, didFailToConnect device: BLEdevice, error: Error?)
  func bleDeviceManager(_ manager: BLEdeviceCentralManager, willRestoreDevices devices: [BLEdevice])
}


public protocol BLEdeviceCentralManager: class {
  var delegate: BLEdeviceCentralManagerDelegate? { get set }
  var state: BLEdeviceManagerState { get }
  
  func scanForDevices(options: [String : Any]?)
  func stopScan()
  
  var isScanning: Bool { get }

  func devices(for uuids: [UUID]) -> [BLEdevice]
  func connectedDevices(withTypes: [BLEdevice.Type]) -> [BLEdevice]
  
  func connect(_ device: BLEdevice, options: [String : Any]?)
  func cancelDeviceConnection(_ device: BLEdevice)
  
  
  func registerDeviceType(_ deviceType: BLEdevice.Type)
  func unregisterDeviceType(_ deviceType: BLEdevice.Type)
}


public func BLEdeviceCentralManagerCreate(queue: DispatchQueue, restoreIdentifier: String? = nil, registeredTypes: [BLEdevice.Type]? = nil) -> BLEdeviceCentralManager {
  let deviceManager = DefaultBLEdeviceCentralManager(queue: queue, restoreIdentifier: restoreIdentifier)
  registeredTypes?.forEach(deviceManager.registerDeviceType)
  return deviceManager
}






