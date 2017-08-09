//
//  DefaultBLEDeviceManager.swift
//  BLEdevice
//
//  Created by Ivan Brazhnikov on 07/08/2017.
//  Copyright © 2017 Ivan Brazhnikov. All rights reserved.
//

import Foundation
import CoreBluetooth

class DefaultBLEdeviceCentralManager : NSObject, CBCentralManagerDelegate, BLEdeviceCentralManager {
  
  private var centralManager: CBCentralManager!
  private var registeredTypes: [BLEdevice.Type] = []
  private var peripheralToDeviceMap = NSMapTable<CBPeripheral, AnyObject>(keyOptions: NSPointerFunctions.Options.weakMemory, valueOptions: NSPointerFunctions.Options.weakMemory)
  
  weak var delegate: BLEdeviceCentralManagerDelegate?
  
  #if TARGET_OS_IOS
  #else
  private var isScanning_macOS: Bool = false
  #endif
  
  let queue : DispatchQueue
  
  init(queue: DispatchQueue, restoreIdentifier: String? = nil) {
    var options = [String : Any]()
    #if TARGET_OS_IOS
      options[CBCentralManagerOptionRestoreIdentifierKey] = restoreIdentifier
    #endif
    self.queue = queue
    super.init()
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
  
  var state: BLEdeviceManagerState {
    let state = centralManager.state
    switch state {
      case .unknown:      return .unknown
      case .resetting:    return .resetting
      case .unsupported:  return .unsupported
      case .unauthorized: return .unauthorized
      case .poweredOff:   return .poweredOff
      case .poweredOn:    return .poweredOn
    }
  }
  
  func scanForDevices(options: [String : Any]?) {
    #if TARGET_OS_IOS
    #else
      self.isScanning_macOS = true
    #endif
    centralManager.scanForPeripherals(withServices: nil, options: options)
  }
  
  func stopScan() {
    #if TARGET_OS_IOS
    #else
      self.isScanning_macOS = false
    #endif
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
     #if TARGET_OS_IOS
      return centralManager.isScanning
    #else
      return isScanning_macOS
    #endif
  }
  
  func devices(for uuids: [UUID]) -> [BLEdevice] {
    let ps = centralManager.retrievePeripherals(withIdentifiers: uuids)
    let devices = ps.filter { self.type(for: $0) != nil }.map { self.findOrCreateDevice(for: $0) }
    return devices
  }
  
  func connectedDevices(withTypes types: [BLEdevice.Type]) -> [BLEdevice] {
    let uuids = types.map { $0.primaryServiceUUID() }
    let peripherals = centralManager.retrieveConnectedPeripherals(withServices: uuids)
    let devices = peripherals.map { findOrCreateDevice(for: $0) }
    return devices
  }
  
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    delegate?.bleDeviceManagerDidUpdateState(self)
  }
  
  @discardableResult
  private func findOrCreateDevice(for peripheral: CBPeripheral) -> BLEdevice {
    let device: BLEdevice
    if let _device = peripheralToDeviceMap.object(forKey: peripheral) as? BLEdevice  {
      device = _device
    } else {
      device = createAndAddDevice(from: peripheral)
    }
    return device
  }
  
  private func createAndAddDevice(from peripheral: CBPeripheral) -> BLEdevice {
    let type = self.type(for: peripheral)!
    let instance = type.init(peripheral: peripheral, baseQueue: queue)
    self.peripheralToDeviceMap.setObject(instance, forKey: peripheral)
    return instance
  }
  
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    
    guard type(for: peripheral) != nil else {
      return
    }
    
    let device = findOrCreateDevice(for: peripheral)
    delegate?.bleDeviceManager(self, didDiscoverDevice: device, rssi: RSSI)
  }
  
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    let device = findOrCreateDevice(for: peripheral)
    device.didConnect()
    delegate?.bleDeviceManager(self, didConnectDevice: device)
  }
  
  func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    let device = findOrCreateDevice(for: peripheral)
    device.didDisconnect(error: error)
    delegate?.bleDeviceManager(self, didDisconnectDevice: device, error: error)
  }
  
  func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    log.debug()
    let device = findOrCreateDevice(for: peripheral)
    device.didFailToConnect(error: error)
    delegate?.bleDeviceManager(self, didFailToConnect: device, error: error)
  }
  
  func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
    var restored: [BLEdevice] = []
    #if TARGET_OS_IOS
      let key = CBCentralManagerRestoredStatePeripheralsKey
    #else
      let key = "CBCentralManagerRestoredStatePeripheralsKey"
    #endif
    
    if let peripherals = dict[key] as? [CBPeripheral] {
      for peripheral in peripherals where type(for: peripheral) != nil {
        let device = findOrCreateDevice(for: peripheral)
        restored.append(device)
      }
    }
    delegate?.bleDeviceManager(self, willRestoreDevices: restored)
  }
}
