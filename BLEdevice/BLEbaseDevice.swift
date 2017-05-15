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
  
  /* State */
  
  public var currentOperation: BLEOperation?
  
  public
  private(set) var interfaceState: BLEinterfaceState = .initial {
    didSet {
      log.debug("\(self) changed interface state to \((self.interfaceState)). Previous state was \((oldValue))")
    }
  }
  
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
    log.debug("Setting current operation with name \(operation.name) and type \(type(of: operation))")
    try assertInteractionState()
    currentOperation = operation
    log.debug("Operation \(operation) was set as current")
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
  
  
  public func prepare() {
    log.debug("Begin preparing...")
    setInterfaceStateAndNotifyDelegate(.preparing)
    monitor.scan()
  }
  
  
  func characteristicUUID(for operation: BLEOperation) -> CBUUID {
    fatalError()
  }
  
  
  func setInterfaceStateAndNotifyDelegate(_ state: BLEinterfaceState) {
    log.debug("Setting interface state to \(state.rawValue)")
    interfaceState = state
    delegate?.bleDeviceDidChangeInterfaceState?(self)
  }
  
  
  func freeInterfaceStateAndNotifyDelegate() {
    log.debug("Freing interface state for notification delegate")
    if interfaceState != .initial {
      setInterfaceStateAndNotifyDelegate(.free)
    } else {
      log.warning("State is initial, can't be as free")
    }
  }
  
  
  
  public func send(data: Data, forCharacteristicUUID uuid: CBUUID) throws {
    delegate?.bleDevice?(self, willSendData: data, toCharateristic: uuid)
    log.debug("Sending data \(data) to characteristic with UUID \(uuid)...")
    try monitor.send(data: data, characteristicUUID: uuid)
    log.debug("...done")
    delegate?.bleDevice?(self, didSendData: data, toCharateristic: uuid)
  }
 
  
  public func readCharateristicValue(forUUID uuid: CBUUID) throws {
    log.debug("Request for reading characteristic with uuid \(uuid)")
    try monitor.readValue(forCharacteristicUUID: uuid)
  }
  
  public func charateristicValue(forUUID uuid: CBUUID) -> Data? {
    log.debug("Getting characteristic value for characteristic \(uuid)")
    let data = monitor.retrieveData(forCharacteristicUUID: uuid)
    log.debug("Value is \(data)")
    return data
  }
  
  public func executeOperation(_ operation: BLEOperation) throws {
    log.debug("Executing operation with name `\(operation.name)` and type \(type(of: operation))")
    try trySetCurrentOperation(operation)
    (operation as? BLEBaseOperation)?.interactor = monitor
    delegate?.bleDevice?(self, willExecuteOperation: operation)
    executeNextCurrentOperationIteration()
  }
  
  
  
  
  private func executeNextCurrentOperationIteration() {
    log.debug("Executing operation iteraction")
    guard let operation = self.currentOperation else {
      return
    }
    log.debug("Current operation is \(operation) with name \(operation.name)")
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
    log.debug("Dropping current operatin...")
    if let currentOperation = self.currentOperation {
      log.debug("Current operation exists: \(currentOperation)")
      currentOperation.didReceiveExternalError(BLEOperationError.interrupted)
      finishCurrentOperation()
    }
  }

  
  private func finishCurrentOperation() {
   log.debug("Finishing current operation...")
    guard let currentOperation = currentOperation else {
      log.warning("Current operation not exists")
      return
    }
    self.currentOperation = nil
    setInterfaceStateAndNotifyDelegate(.free)
    didFinishOperation(currentOperation)
    delegate?.bleDevice?(self, didFinishOperation: currentOperation)
  }
  
  
  
  
  
  
  final func scheduleCurrentOperationTimeout(_ timeout: TimeInterval){
    weak var current = self.currentOperation
    log.debug("Scheduling operation timeout with \(timeout)s...")
    interfaceQueue.asyncAfter(deadline: .now() + timeout) {[weak self] in
      guard let `self` = self else { return }
      log.debug("Timout for operation \(current)")
      if let monitoringOpeartion = current,
            let currentOperation = self.currentOperation,
            currentOperation === monitoringOpeartion,
            currentOperation.executionTimestamp == monitoringOpeartion.executionTimestamp {
        log.debug("Timeout is valid for current operation")
        currentOperation.timeout()
        self.executeNextCurrentOperationIteration()
      } else {
        log.debug("Timeout is NOT valid for current operation")
      }
    }
  }
  
  
//  
//  open func validateResposeOnGlobalErrors(_ data: Data) throws {}
//  
//  
  
  public func peripheralMonitor(monitor: PeripheralMonitor, didUpdateValueForCharacteristic uuid: CBUUID, error: Error?) {
    log.debug("Characteristic with UUID \(uuid) was updated (error: \(error))")
    
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
    log.debug("Getting operation that can respond on characteristic (\(uuid))")
    if let op = self.currentOperation, op.canRespondOnCharacteristic(characteristicUUID: uuid) {
      log.debug("Found \(op) with name \(op.name)")
      return op
    }
    return nil
  }
  
  
  public func peripheralMonitor(monitor: PeripheralMonitor, didWriteValueForCharacteristic uuid: CBUUID, error: Error?) {
    log.debug("Characteristic with UUID \(uuid) was writted (error: \(error))")
    delegate?.bleDevice?(self, didWriteValueForCharacteristicUUID: uuid, error: error)
    if let opertation = findRespondingOperation(onCharacteristicUUID: uuid) {
      opertation.didWriteValue(forCharacteristicUUID: uuid, error: error)
    }
  }
  
  
  
  open func didConnect() {
    log.debug("\(self) was connected")
    setInterfaceStateAndNotifyDelegate(.initial)
    delegate?.bleDeviceDidConnect?(self)
  }
  
  
  open func didDisconnect(error: Error?) {
    log.debug("\(self) was disconnedted with error \(error)")
    setInterfaceStateAndNotifyDelegate(.initial)
    delegate?.bleDevice?(self, didDisconnect: error)
  }
  
  open func didFailToConnect(error: Error?) {
    log.debug("\(self) can't be connected because \(error)")
    delegate?.bleDevice?(self, didFailToConnect: error)
  }
  
  
  
  /* MARK: Monitor response */
  
  
  
  public func peripheralMonitor(monitor: PeripheralMonitor, didEndScanning error: Error?) {
    log.debug("Finish scanning services and characteristics (error: \(error))")
    if error == nil {
      self.interfaceState = .free
    } else {
      self.interfaceState = .initial
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



