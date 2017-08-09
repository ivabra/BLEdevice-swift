//
//  BLEdeviceDefaultImpl.swift
//  BLEdevice
//
//  Created by Ivan Brazhnikov on 05.02.17.
//  Copyright © 2017 Ivan Brazhnikov. All rights reserved.
//

import Foundation
import CoreBluetooth

open class BLEbaseDevice: BLEdevice {

  // MARK: Class properties
  open class func primaryServiceUUID() -> CBUUID {
    fatalError()
  }
  
  /// BLE device configurtion
  open class func defaultConfiguration() -> BLEdeviceConfiguration {
    return .empty
  }
  
  /// Is peripheral valid for this device class
  open class func validatePeripheral(_ peripheral: CBPeripheral) -> Bool {
    fatalError()
  }
  
  // MARK: Public properties
  public weak var delegate: BLEdeviceDelegate?
  public let userInfo: BLEdeviceUserInfo = .init()
  
  // MARK: Internal properties
  let internalUserInfo: BLEdeviceUserInfo = .init()
  
  // MARK: Private properties
  private let monitor: PeripheralMonitor
  private let queue: DispatchQueue
  
  
  
  // MARK: State properties
  
  public var interfaceState: BLEinterfaceState {
    if !self.monitor.isNeedScanning {
      return BLEinterfaceState.ready
    } else if self.monitor.isScanning {
      return BLEinterfaceState.preparing
    } else {
      return BLEinterfaceState.needPrepare
    }
  }

  public var connectionState: CBPeripheralState {
    return monitor.peripheral.state
  }
  
  // MARK: Device properties
  public func getPeripheral() throws -> CBPeripheral {
    return monitor.peripheral
  }
  
  public var identifier: UUID {
    return monitor.peripheral.identifier
  }
  
  public var name: String? {
    return monitor.peripheral.name
  }
  
  required convenience public init(peripheral: CBPeripheral, baseQueue: DispatchQueue) {
    let config = type(of: self).defaultConfiguration()
    self.init(peripheral: peripheral, config: config, baseQueue: baseQueue)
  }
  
  public init(peripheral: CBPeripheral, config: BLEdeviceConfiguration, baseQueue: DispatchQueue) {
    let monitor = PeripheralMonitorCreate(peripheral: peripheral, configuration: config)
    self.monitor = monitor
    self.queue = DispatchQueue(label: "com.dantelab.bledevice." + peripheral.identifier.uuidString,
                               qos: DispatchQoS.utility,
                               attributes: [],
                               target: baseQueue)
    monitor.delegate = self
  }

 
  
  fileprivate func assertInteractionState() throws {
    guard self.interfaceState == .ready else {
        throw BLEdeviceError.notPrepared
    }
  }
  
  // MARK: Operations
  
  public private(set) var operationStack: [BLEOperation] = [] {
    didSet {
      log.debug(operationStack)
    }
  }
  
  public var currentOperation: BLEOperation? {
    didSet {
      log.debug("new: \(currentOperation?.description ?? "nil"), old: \(oldValue?.description ?? "nil")")
    }
  }
  
  
  public func executeOperation(_ operation: BLEOperation) {
    self._executeOperation(operation)
  }
  
  fileprivate func _executeOperation(_ operation: BLEOperation) {
    log.debug("Executing operation `\(operation.name)` and type \(type(of: operation))")
    (operation as? BLEBaseOperation)?.interactor = monitor
    operationStack.append(operation)
    dispatchOperations()
  }
  
  fileprivate func dispatchOperations() {
    log.debug("")
    guard let current = currentOperation else {
      if !operationStack.isEmpty {
        currentOperation = operationStack.removeFirst()
        dispatchOperations()
      }
      return
    }
    log.debug("Current operation is \(current)")
    guard !current.isFinished else {
      currentOperation = nil
      log.debug("Finishing operation \(current)")
      didFinishOperation(current)
      delegate?.bleDevice(self, didFinishOperation: current)
      return
    }
    
    do {
      log.debug("will execute operation \(current)")
      delegate?.bleDevice(self, willExecuteOperation: current) 
      try current.start()
      if current.isFinished {
        dispatchOperations()
      } else {
        scheduleOperationTimeout(current)
      }
      
    } catch {
      log.warning(error)
      current.didReceiveExternalError(error)
      dispatchOperations()
    }
    
  }
  
  
  fileprivate func scheduleOperationTimeout(_ operation: BLEOperation){
    log.debug("Timeout for \(operation) is \(operation.responseTimeout)s.")
    
    let tm = operation.executionTimestamp
    
    queue.asyncAfter(deadline: .now() + operation.responseTimeout) {[weak self, weak operation] in
      guard
        let `self` = self,
        let operation = operation,
        operation.executionTimestamp == tm
        else {
          return
      }
      log.debug("Fired timeout for \(operation)")
      operation.timeout()
      self.dispatchOperations()
    }
    
  }
  
  fileprivate func findRespondingOperation(onCharacteristicUUID uuid: CBUUID) -> BLEOperation? {
    log.debug("uuid: \(uuid)")
    if let op = self.currentOperation, op.canRespondOnCharacteristic(characteristicUUID: uuid) {
      log.debug("Found \(op) with name \(op.name)")
      return op
    }
    return nil
  }
   
  
  final func dispatch(execute: @escaping (BLEbaseDevice)->()) {
    queue.async { [weak self] in
      if let `self` = self {
        execute(self)
      }
    }
  }
   
  public func prepare() {
    log.debug("")
    monitor.scan()
  }
  

  public func send(data: Data, forCharacteristicUUID uuid: CBUUID) throws {
    delegate?.bleDevice(self, willSendData: data, toCharacteristic: uuid)
    log.debug("Sending data \(data) to characteristic with UUID \(uuid)...")
    try monitor.send(data: data, characteristicUUID: uuid)
    log.debug("...done")
    delegate?.bleDevice(self, didSendData: data, toCharacteristic: uuid)
  }
 
  public func readCharateristicValue(forUUID uuid: CBUUID) throws {
    log.debug("reading value of characteristic(\(uuid))")
    try monitor.readValue(forCharacteristicUUID: uuid)
  }
  
  public func charateristicValue(forUUID uuid: CBUUID) -> Data? {
    log.debug("Getting characteristic value for characteristic \(uuid)")
    let data = monitor.retrieveData(forCharacteristicUUID: uuid)
    log.debug { "Value of \(uuid) is " + data.descriptionOrNil }
    return data
  }
  
  
  
  open func didConnect() {
    log.debug("\(self) was connected")
    delegate?.bleDeviceDidConnect(self)
  }
  
  
  open func didDisconnect(error: Error?) {
    log.debug { "\(self) was disconnected" + error.flatMap(or: "") { " with error \($0)" } }
    delegate?.bleDevice(self, didDisconnect: error)
  }
  
  open func didFailToConnect(error: Error?) {
    log.debug("\(self) can't be connected" + error.flatMap(or: "", transform: { " \($0)" }) )
    delegate?.bleDevice(self, didFailToConnect: error)
  }
  
  open func didFinishOperation(_ operation: BLEOperation) {}
  
  public func dropCurrentOperation() {
    if let c = currentOperation {
      c.didReceiveExternalError(BLEOperationError.interrupted)
      dispatchOperations()
    }
  }
  
  public func dropAllOperations() {
    operationStack.removeAll()
    dropCurrentOperation()
  }
  
}

extension BLEbaseDevice : PeripheralMonitorDelegate {
  
  public func peripheralMonitor(_ monitor: PeripheralMonitor, didWriteValueForCharacteristic uuid: CBUUID, error: Error?) {
    log.debug("Characteristic with UUID \(uuid) was written" + error.spaceDescription(or: ""))
    delegate?.bleDevice(self, didWriteValueToCharacteristic: uuid, error: error)
    guard let operation = findRespondingOperation(onCharacteristicUUID: uuid) else {
        return
    }
    operation.didWriteValue(forCharacteristicUUID: uuid, error: error)
    dispatchOperations()
  }
  
  public func peripheralMonitor(_ monitor: PeripheralMonitor, didUpdateValueForCharacteristic uuid: CBUUID, error: Error?) {
    log.debug("Characteristic (\(uuid)) was updated" + error.flatMap(or: "") { " \($0)" })
    delegate?.bleDevice(self, didUpdateValueForCharacteristic: uuid, error: error)
    guard let operation = findRespondingOperation(onCharacteristicUUID: uuid) else {
      return
    }
    operation.didUpdateValue(forCharacteristicUUID: uuid, error: error)
    dispatchOperations()
  }
  
  public func peripheralMonitor(_ monitor: PeripheralMonitor, didEndScanning error: Error?) {
    log.debug("Finish scanning services and characteristics" + error.spaceDescription(or: ""))
    delegate?.bleDevice(self, didEndInitializing: error)
  }
  
}



extension BLEOperation {
  public func execute(at device: BLEbaseDevice) {
     device.executeOperation(self)
  }
}

