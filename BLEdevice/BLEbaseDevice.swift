//
//  BLEdeviceDefaultImpl.swift
//  BLEdevice
//
//  Created by Ivan Brazhnikov on 05.02.17.
//  Copyright © 2017 Ivan Brazhnikov. All rights reserved.
//

import Foundation
import CoreBluetooth

@objc
open class BLEbaseDevice: NSObject, BLEdevice, PeripheralMonitorDelegate {
  
  
  
  
  let monitor: PeripheralMonitor
  
  /* Current state */
  
  public var currentOperation: BLEoperation?
  
  public private(set) var interfaceState: BLEinterfaceState = .initial
  
  public let userInfo: BLEdeviceUserInfo = .init()
  
  
  /* User info */
  
  
  let internalUserInfo: BLEdeviceUserInfo = .init()
  
  
  
  
  
  
  open class func defaultConfiguration() -> BLEdeviceConfiguration {
    return .empty
  }

  
  open class func validatePeripheral(_ peripheral: CBPeripheral) -> Bool {
    return false
  }
  
  
  open func willSendData(data: Data, forCharacteristicUUID: CBUUID) {
    
  }
  
  open func didSendData(data: Data, forCharacteristicUUID: CBUUID) {
    
  }
  
  open func didReceiveInPassiveMode(data: Data, fromCharacteristicWithUUID uuid: CBUUID) {
    /* When it's no operation, but data was received */
  }
  
  open func didUpdateValueForCharacteristic(uuid: CBUUID, error: Error?) {
    
  }
  
  open func didWriteValueForCharacteristic(uuid: CBUUID, error: Error?) {
    
  }
  
  
  
  
  
  
  
  public func getPeripheral() throws -> CBPeripheral {
    return monitor.peripheral
  }
  
  
  public var identifier: UUID {
    return monitor.peripheral.identifier
  }
  
  
  public var name: String? {
    return monitor.peripheral.name
  }
  
  public var connectionState: CBPeripheralState {
    return monitor.peripheral.state
  }
  
  
  
  /* Delegates */
  
  public weak  var delegate: BLEdeviceDelegate?
  
  
  /* Some operation params */
  
  private var delayedOperationEnd: DispatchWorkItem? { didSet { oldValue?.cancel() }}
  
  
  required convenience public init(peripheral: CBPeripheral) {
    let config = type(of: self).defaultConfiguration()
    self.init(peripheral: peripheral, config: config)
  }
  
  public init(peripheral: CBPeripheral, config: BLEdeviceConfiguration) {
    let monitor = PeripheralMonitorCreate(peripheral: peripheral, configuration: config)
    self.monitor = monitor
    super.init()
    monitor.delegate = self
  }
  

  
  lazy var interfaceQueue : DispatchQueue = { () -> DispatchQueue in
    let id = ObjectIdentifier(self).hashValue
    let queue = DispatchQueue(label: "\(type(of:self)).\(id)", qos: .utility, attributes: .concurrent)
    return queue
  }()
  
  
  
  func assertInteractionState() throws {
    guard isPrepared else {
        throw BLEdeviceError.notPrepared
    }
    
    guard interfaceState == .free else {
      throw BLEdeviceError.interfaceStateNotFree
    }
    
    guard currentOperation == nil else {
      throw BLEdeviceError.currentOperationNotCompleted
    }
  }
  
  
  func trySetCurrentOperation(_ operation: BLEoperation) throws {
    try assertInteractionState()
    currentOperation = operation
  }
  
  
  
  func dispatch(execute: @escaping ()->()) {
    interfaceQueue.async(execute: execute)
  }
  
  
  var isPrepared: Bool {
    return monitor.isPrepared
  }
  
  
  
  public func prepare() {
    monitor.scan()
  }
  
  
  func setInterfaceStateAndNotifyDelegate(_ state: BLEinterfaceState) {
    interfaceState = state
    delegate?.bleDeviceDidChangeInterfaceState?(self)
  }
  
  
  func freeInterfaceStateAndNotifyDelegate() {
    if interfaceState != .initial {
      setInterfaceStateAndNotifyDelegate(.free)
    }
  }
  
  
  
  public func send(data: Data, forCharacteristicUUID uuid: CBUUID) throws {
    willSendData(data: data, forCharacteristicUUID: uuid)
    try monitor.send(data: data, characteristicUUID: uuid)
    didSendData(data: data, forCharacteristicUUID: uuid)
  }
  
  
  
  public func execute(_ operation: BLEoperation) throws {
    
    try trySetCurrentOperation(operation)
    
    let data = operation.sendingData
    let uuid = operation.targetCharacteristicUUID
    
    do {
       try monitor.send(data: data, characteristicUUID: uuid)
    } catch {
      dropInOperationState()
      throw error
    }
   
  }
  
  
  private func dropInOperationState() {
    assert(currentOperation != nil, "Operation should be not nil")
    let cachedOperation = self.currentOperation!
    delayedOperationEnd = nil
    currentOperation = nil
    didEndOperation(cachedOperation)
    cachedOperation.didComplete()
    setInterfaceStateAndNotifyDelegate(.free)
  }
  
  
  
  final func waitForNextOperationIteration(waitingTime: TimeInterval){
    var operationEnd: DispatchWorkItem!
    
    operationEnd = DispatchWorkItem { [weak operationEnd, unowned self] in
      guard let op = operationEnd, op.isCancelled else {
        return
      }
      self.dropInOperationState()
    }
    
    self.delayedOperationEnd = operationEnd
    interfaceQueue.asyncAfter(wallDeadline: .now() + waitingTime, execute: operationEnd)
  }
  
  func peripheralMonitor(monitor: PeripheralMonitor, didUpdateValueForCharacteristic uuid: CBUUID, error: Error?) {
    
    didUpdateValueForCharacteristic(uuid: uuid, error: error)
    // Drop delayed operation
    delayedOperationEnd = nil
    
    let receivedData = monitor.retrieveCachedData(forCharacteristicUUID: uuid);
    
    // Current operation should be, else it's not expected result
    guard let operation = self.currentOperation, operation.targetCharacteristicUUID == uuid else {
      
      if let data = receivedData {
        didReceiveInPassiveMode(data: data, fromCharacteristicWithUUID: uuid)
      }
      
      return
    }
    
    
    defer {
      if operation.error != nil {
        dropInOperationState()
      } else {
        if let waitingTime = operation.timeIntervalForNextOperation {
          waitForNextOperationIteration(waitingTime: waitingTime)
        } else {
          dropInOperationState()
        }
      }
    }
    
    
    
    if let error = error {
      operation.didReceiveError(error)
      return
    }
    
    // if characteristic was notified, but value == nil
    guard let data = receivedData else {
      fatalError("It can't be called without received value")
    }
    
    // if device respond error
    
    operation.didReceiveData(data)
    
  }
  
  
  func peripheralMonitor(monitor: PeripheralMonitor, didWriteValueForCharacteristic uuid: CBUUID, error: Error?) {
    didWriteValueForCharacteristic(uuid: uuid, error: error)
  }
  
  
  
  
  
  open func didConnect() {
    delegate?.bleDeviceDidConnect?(self)
  }
  
  
  open func didDisconnect(error: Error?) {
    interfaceState = .initial
    delegate?.bleDevice?(self, didDisconnect: error)
  }
  
  open func didFailToConnect(error: Error?) {
    delegate?.bleDevice?(self, didFailToConnect: error)
  }
  
  
  
  /* MARK: Monitor response */
  
  
  
  func peripheralMonitor(monitor: PeripheralMonitor, didEndScanning error: Error?) {
    if error == nil {
      self.interfaceState = .free
    }
    delegate?.bleDevice?(self, didEndInitializing: error)
  }
  
  
  func didWriteValue(error: Error?) {
    /* Should be overriden */
  }
  
  func didEndOperation(_ operation: BLEoperation) {
    /* Should be overriden */
  }
  
}



extension BLEbaseDevice {
  @discardableResult
  public func trySetCurrentOperation<T: BLEoperation>(_ cls: T.Type, name: BLEoperationName, targetUUID: CBUUID, userInfo: [String :Any] = [:]) throws -> T {
    let context = T.init(name: name, targetUUID: targetUUID)
    context.userInfo = userInfo
    try trySetCurrentOperation(context)
    return context
  }
}
