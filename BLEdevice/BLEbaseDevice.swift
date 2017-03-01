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
  
  open class func primaryServiceUUID() -> CBUUID {
    fatalError()
  }
  
  
  public weak var delegate: BLEdeviceDelegate?
  
  let monitor: PeripheralMonitor
  var waitCount: Int = 0
  
 // open var defaultOperationAwaitingTimeInterval: TimeInterval = 3.0
  
  /* State */
  
  public var currentOperation: BLEOperation?
  
  public
  private(set) var interfaceState: BLEinterfaceState = .initial
  
  public let userInfo: BLEdeviceUserInfo = .init()
  
  
  /* User info */
  
  
  let internalUserInfo: BLEdeviceUserInfo = .init()
  
  
  open class func defaultConfiguration() -> BLEdeviceConfiguration {
    return .empty
  }

  
  open class func validatePeripheral(_ peripheral: CBPeripheral) -> Bool {
    fatalError()
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
  
  
  
  func trySetCurrentOperation(_ operation: BLEOperation) throws {
    try assertInteractionState()
    currentOperation = operation
    setInterfaceStateAndNotifyDelegate(.busy)
  }
  
  
  
  final func dispatch(execute: @escaping (BLEbaseDevice)->()) {
    interfaceQueue.async { [weak self] in
      if let `self` = self {
        execute(self)
      }
    }
  }
  
  
  open var isPrepared: Bool {
    return monitor.isPrepared
  }
  
  
  open var defaultOperationRequestUUID: CBUUID? {
    return nil
  }
  
  
  open var defaultOperationResponseUUID: CBUUID? {
    return nil
  }
  
  
  public func prepare() {
    setInterfaceStateAndNotifyDelegate(.preparing)
    monitor.scan()
  }
  
  
  func characteristicUUID(for operation: BLEOperation) -> CBUUID {
    fatalError()
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
    delegate?.bleDevice?(self, willSendData: data, toCharateristic: uuid)
    try monitor.send(data: data, characteristicUUID: uuid)
    delegate?.bleDevice?(self, didSendData: data, toCharateristic: uuid)
  }
 
  
  public func readCharateristicValue(forUUID uuid: CBUUID) throws {
    try monitor.readValue(forCharacteristicUUID: uuid)
  }
  
  public func charateristicValue(forUUID uuid: CBUUID) -> Data? {
    return monitor.retrieveData(forCharacteristicUUID: uuid)
  }
  
  public func executeOperation(_ operation: BLEOperation) throws {
    try trySetCurrentOperation(operation)
    (operation as? BLEBaseOperation)?.interactor = monitor
    delegate?.bleDevice?(self, willExecuteOperation: operation)
    executeNextCurrentOperationIteration()
  }
  
  
  
  
  private func executeNextCurrentOperationIteration() {
 
    guard let operation = self.currentOperation else {
      fatalError()
    }
    
    guard operation.hasNextIteration && operation.error == nil else {
      finishCurrentOperation()
      return
    }
    
    do {
      try operation.start()
      scheduleCurrentOperationTimeout(operation.responseTimeout)
    } catch {
      operation.didReceiveExternalError(error)
      executeNextCurrentOperationIteration()
    }
  }
  
  
  public func dropCurrentOperaton() {
    if let currentOperation = self.currentOperation {
      currentOperation.didReceiveExternalError(BLEOperationError.interrupted)
      finishCurrentOperation()
    }
  }

  
  private func finishCurrentOperation() {
   
    guard let currentOperation = currentOperation else {
      return
    }
    
    self.currentOperation = nil
    delegate?.bleDevice?(self, didFinishOperation: currentOperation)
    didFinishOperation(currentOperation)
    setInterfaceStateAndNotifyDelegate(.free)
  }
  
  
  
  
  
  
  final func scheduleCurrentOperationTimeout(_ timeout: TimeInterval){
    
    weak var current = self.currentOperation
    
    interfaceQueue.asyncAfter(deadline: .now() + timeout) {[weak self] in
      guard let `self` = self else { return }
      
      guard let monitoringOpeartion = current,
            let currentOperation = self.currentOperation,
            currentOperation === monitoringOpeartion,
            currentOperation.executionTimestamp == monitoringOpeartion.executionTimestamp
      else {
        return
      }
      
      self.executeNextCurrentOperationIteration()
    }
    
  }
  
  
  
  open func validateResposeOnGlobalErrors(_ data: Data) throws {}
  
  
  
  public func peripheralMonitor(monitor: PeripheralMonitor, didUpdateValueForCharacteristic uuid: CBUUID, error: Error?) {
    
    
    /* Notify */
    
    delegate?.bleDevice?(self, didUpdateValueForCharacteristicUUID: uuid, error: error)
    
    /* Getting data from characteristic */
    
    let receivedData = monitor.retrieveCachedData(forCharacteristicUUID: uuid) ?? Data()
    
    guard let operation = findRespondingOperation(onCharacteristicUUID: uuid),
          operation.canRespondOnData(data: receivedData)
    else {
      return
    }
    
    operation.didUpdateValue(receivedData, forCharacteristicUUID: uuid, error: error)
    executeNextCurrentOperationIteration()
  }
  
  
  
  
  private func findRespondingOperation(onCharacteristicUUID uuid: CBUUID) -> BLEOperation? {
    if let op = self.currentOperation, op.canRespondOnCharacteristic(characteristicUUID: uuid) {
      return op
    }
    return nil
  }
  
  
  public func peripheralMonitor(monitor: PeripheralMonitor, didWriteValueForCharacteristic uuid: CBUUID, error: Error?) {
    delegate?.bleDevice?(self, didWriteValueForCharacteristicUUID: uuid, error: error)
    if let opertation = findRespondingOperation(onCharacteristicUUID: uuid) {
      opertation.didWriteValue(forCharacteristicUUID: uuid, error: error)
    }
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
  
  
  
  public func peripheralMonitor(monitor: PeripheralMonitor, didEndScanning error: Error?) {
    if error == nil {
      self.interfaceState = .free
    }
    delegate?.bleDevice?(self, didEndInitializing: error)
  }
  
  
  open func didFinishOperation(_ operation: BLEOperation) {
    
  }
  
  
}

extension BLEOperation {
  public func execute(at device: BLEbaseDevice) throws {
    try device.executeOperation(self)
  }
}



