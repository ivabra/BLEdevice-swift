//
//  BLEdeviceManager.swift
//  BLEdevice
//
//  Created by Ivan Brazhnikov on 04.02.17.
//  Copyright © 2017 Ivan Brazhnikov. All rights reserved.
//


import Foundation
import CoreBluetooth

@objc
public protocol BLEdeviceCentralManagerDelegate {
  @objc optional func bleDeviceManagerDidUpdateState(_ manager: BLEdeviceCentralManager)
  @objc optional func bleDeviceManager(_ manager: BLEdeviceCentralManager, didDiscoverDevice device: BLEdevice, rssi: NSNumber)
  @objc optional func bleDeviceManager(_ manager: BLEdeviceCentralManager, didConnectDevice device: BLEdevice)
  @objc optional func bleDeviceManager(_ manager: BLEdeviceCentralManager, didDisconnectDevice device: BLEdevice, error: Error?)
  @objc optional func bleDeviceManager(_ manager: BLEdeviceCentralManager, didFailToConnect device: BLEdevice, error: Error?)
  @objc optional func bleDeviceManager(_ manager: BLEdeviceCentralManager, willRestoreDevices devices: [BLEdevice])
}



@objc
public protocol BLEdeviceCentralManager {
  var delegate: BLEdeviceCentralManagerDelegate? { get set }
  var state: CBCentralManagerState { get }
  
  func scanForDevices(options: [String : Any]?)
  func stopScan()
  
  var isScanning: Bool { get }
  
  func restoreDevices(withIdentifiers: [UUID])
  func retrieveDevices() -> [BLEdevice]
  
  func device(for uuid: UUID) -> BLEdevice?
  
  func connect(_ device: BLEdevice, options: [String : Any]?)
  func cancelDeviceConnection(_ device: BLEdevice)
  
  func dropCachedDevices()
  
  func registerDeviceType(_ deviceType: BLEdevice.Type)
  func unregisterDeviceType(_ deviceType: BLEdevice.Type)
}


public func BLEdeviceCentralManagerCreate(queue: DispatchQueue, restoreIdentifier: String? = nil, registeredTypes: [BLEdevice.Type]? = nil) -> BLEdeviceCentralManager {
  let deviceManager = BLEdeviceCentralManagerImpl(queue: queue, restoreIdentifier: restoreIdentifier)
  if let types = registeredTypes {
    deviceManager.registeredTypes = types
  }
  return deviceManager
}



class BLEdeviceCentralManagerImpl : NSObject, CBCentralManagerDelegate, BLEdeviceCentralManager {
  

  
  var centralManager: CBCentralManager!
  var registeredTypes: [BLEdevice.Type] = []
  var devices: [UUID: BLEdevice] = [:]
  
  weak var delegate: BLEdeviceCentralManagerDelegate?

  
  init(queue: DispatchQueue, restoreIdentifier: String? = nil) {
    super.init()
    var options = [String : Any]()
    options[CBCentralManagerOptionRestoreIdentifierKey] = restoreIdentifier
    self.centralManager = CBCentralManager(delegate: self, queue: queue, options: options)
  }
  
  
  func registerDeviceType(_ deviceType: BLEdevice.Type) {
    guard !registeredTypes.contains(where: { $0 === deviceType }) else {
      fatalError("You can register one type once only")
    }
    registeredTypes.append(deviceType)
  }
  
  func unregisterDeviceType(_ deviceType: BLEdevice.Type) {
    if let index = registeredTypes.index(where: { $0 === deviceType }) {
      registeredTypes.remove(at: index)
    }
  }
  
  
  private func type(for peripheral: CBPeripheral) -> BLEdevice.Type? {
    for type in self.registeredTypes {
      if type.validatePeripheral(peripheral) {
        return type
      }
    }
    return nil
  }
  
  
  var state: CBCentralManagerState {
    switch centralManager.state {
    case .poweredOff:     return .poweredOff
    case .poweredOn:      return .poweredOn
    case .resetting:      return .resetting
    case .unauthorized:   return .unauthorized
    case .unknown:        return .unknown
    case .unsupported:    return .unsupported
    }
  }
  
  
  func scanForDevices(options: [String : Any]?) {
    centralManager.scanForPeripherals(withServices: nil, options: options)
  }
  
  func stopScan() {
    centralManager.stopScan()
  }
  
  func connect(_ device: BLEdevice, options: [String : Any]?) {
    let peripheral = try! device.getPeripheral()
    centralManager.connect(peripheral, options: options)
  }
  
  func cancelDeviceConnection(_ device: BLEdevice) {
    let peripheral = try! device.getPeripheral()
    centralManager.cancelPeripheralConnection(peripheral)
  }
  
  
  var isScanning : Bool {
    return centralManager.isScanning
  }
  
  
  func retrieveDevices() -> [BLEdevice] {
    return Array(devices.values)
  }
  
  
  func device(for uuid: UUID) -> BLEdevice? {
    return devices[uuid]
  }
  
  
  func disconnectAll() {
    devices.values.filter {
      $0.connectionState == .connected || $0.connectionState == .connecting
      }.forEach {
        self.cancelDeviceConnection($0)
    }
  }
  
  func dropCachedDevices() {
    disconnectAll()
    devices.removeAll()
  }
  
  
  
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    delegate?.bleDeviceManagerDidUpdateState?(self)
  }
  
  @discardableResult
  private func findOrCreateDevice(for peripheral: CBPeripheral) -> BLEdevice {
    let device: BLEdevice
    if let _device = devices[peripheral.identifier]  {
      device = _device
    } else {
      device = createAndAddDevice(from: peripheral)
    }
    return device
  }
  
  
  
  private func createAndAddDevice(from peripheral: CBPeripheral) -> BLEdevice {
    let type = self.type(for: peripheral)!
    let instance = type.init(peripheral: peripheral)
    
    devices[peripheral.identifier] = instance
    return instance
  }
  
  func restoreDevices(withIdentifiers identifiers: [UUID]) {
    let peripherals = centralManager.retrievePeripherals(withIdentifiers: identifiers)
    for p in peripherals {
      findOrCreateDevice(for: p)
    }
  }
 
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    
    guard type(for: peripheral) != nil else {
      return
    }
    
    let device = findOrCreateDevice(for: peripheral)
    debugPrint("Peripheral ", peripheral, " was found")
    delegate?.bleDeviceManager?(self, didDiscoverDevice: device, rssi: RSSI)
  }
  
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    let device = findOrCreateDevice(for: peripheral)
    device.didConnect()
    delegate?.bleDeviceManager?(self, didConnectDevice: device)
  }
  
  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    let device = findOrCreateDevice(for: peripheral)
    device.didDisconnect(error: error)
    delegate?.bleDeviceManager?(self, didDisconnectDevice: device, error: error)
  }
  
  func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    let device = findOrCreateDevice(for: peripheral)
    device.didFailToConnect(error: error)
    delegate?.bleDeviceManager?(self, didFailToConnect: device, error: error)
  }
  
  func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
    var restored: [BLEdevice] = []
    if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
      for peripheral in peripherals where type(for: peripheral) != nil {
        let device = findOrCreateDevice(for: peripheral)
        restored.append(device)
      }
    }
    delegate?.bleDeviceManager?(self, willRestoreDevices: restored)
  }
  
  
  
}


