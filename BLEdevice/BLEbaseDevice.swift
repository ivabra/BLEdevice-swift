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
  
  
  let monitor: PeripheralMonitor
  var sem: DispatchSemaphore?
  var waitCount: Int = 0
  
  open var defaultOperationAwaitingTimeInterval: TimeInterval = 3.0
  
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
  
  
  private var syncOperationError: Error? {
    get {
      return internalUserInfo.getValue(for: "__syncOperationError") as? Error
    }
    set {
      internalUserInfo.putValue(newValue, for: "__syncOperationError")
    }
  }
  
  private var syncOperationResult: Any? {
    get {
      return internalUserInfo.getValue(for: "__syncOperationResult")
    }
    set {
      internalUserInfo.putValue(newValue, for: "__syncOperationResult")
    }
  }
  
  public weak  var delegate: BLEdeviceDelegate?
  
  
  
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
  
  
  
  final func dispatch(execute: @escaping (BLEbaseDevice)->()) {
    interfaceQueue.async { [weak self] in
      if let `self` = self {
        execute(self)
      }
    }
  }
  
  
  var isPrepared: Bool {
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
  
  
  func characteristicUUID(for operation: BLEoperation) -> CBUUID {
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
    willSendData(data: data, forCharacteristicUUID: uuid)
    try monitor.send(data: data, characteristicUUID: uuid)
    didSendData(data: data, forCharacteristicUUID: uuid)
  }
  
  
  
  
  open func willExecuteOperation(_ operation: BLEoperation) {
    if operation.requestCharacteristicUUID == nil {
      operation.requestCharacteristicUUID = defaultOperationRequestUUID
    }
    if operation.responseCharacteristicUUID == nil {
      operation.responseCharacteristicUUID = defaultOperationResponseUUID
    }
  }
  
  
  
  
  public func execute(operation: BLEoperation) throws {
    
    try trySetCurrentOperation(operation)
    
    willExecuteOperation(operation)
    
    if operation.awaitingTimeInterval == nil {
      operation.awaitingTimeInterval = defaultOperationAwaitingTimeInterval
    }
    
    let data = operation.sendingData
    let uuid: CBUUID! = operation.requestCharacteristicUUID
    assert(uuid != nil, "Target UUID should not be nil")
    
    do {
        try send(data: data, forCharacteristicUUID: uuid)
        waitForNextOperationIteration(waitingTime: operation.awaitingTimeInterval)
    } catch {
        finishCurrentOperation()
      throw error
    }
  }
  
  
  public final func waitCurrentOperation() throws  {
   
    guard currentOperation != nil else {
      return
    }
    
    
    let semaphore: DispatchSemaphore = {
      if let sem = self.sem {
        return sem
      } else {
        self.waitCount = 0
        return DispatchSemaphore(value: 0)
      }
    }()
    
    self.waitCount += 1
    semaphore.wait()
    
    if let error = syncOperationError {
      syncOperationError = nil
      throw error
    }
  }
  
  
  
  
  
  private func signalAndDropSemaphore() {
    if let sem = sem {
      let waitCount = self.waitCount
      
      self.sem = nil
      self.waitCount = 0
      
      for _ in 0..<waitCount {
         sem.signal()
      }
     
    }
  }
  
  
  
  
  private func finishCurrentOperation() {
   
    defer {
      signalAndDropSemaphore()
    }
    
    guard let currentOperation = currentOperation else {
      return
    }
    
    self.currentOperation = nil
    currentOperation.didComplete()
    syncOperationError = currentOperation.error
    didEndOperation(currentOperation)
    setInterfaceStateAndNotifyDelegate(.free)
  }
  
  
  
  
  
  
  final func waitForNextOperationIteration(waitingTime: TimeInterval){
    
    weak var current = self.currentOperation
    
    interfaceQueue.asyncAfter(deadline: .now() + waitingTime) {[weak self] in
      guard let `self` = self else { return }
      
      guard let currentOperation = self.currentOperation, currentOperation === current else {
        return
      }
      
      self.finishCurrentOperation()
    }
    
  }
  
  
  
  open func validateResposeOnGlobalErrors(_ data: Data) throws {
    
  }
  
  
  func peripheralMonitor(monitor: PeripheralMonitor, didUpdateValueForCharacteristic uuid: CBUUID, error: Error?) {
    
    
    /* Notify */
    
    didUpdateValueForCharacteristic(uuid: uuid, error: error)
    
    
    /* Getting data from characteristic */
    
    guard let receivedData = monitor.retrieveCachedData(forCharacteristicUUID: uuid) else {
      return
    }
    
    
    /* Catch global errors */
    
    do {
      try validateResposeOnGlobalErrors(receivedData)
    } catch {
      if let operation = self.currentOperation {
        operation.didReceiveError(error)
        finishCurrentOperation()
      }
      return
    }
    
    
    /* Current operation should be, else it's not expected result */
    guard let operation = self.currentOperation,
      /* should be expected characteristic */
      operation.responseCharacteristicUUID == uuid,
      /* Operation should validate resposne */
      operation.validateThisOperationIsDestination(for: receivedData) else {
      /* Else maybe its passive receiving  */
      didReceiveInPassiveMode(data: receivedData, fromCharacteristicWithUUID: uuid)
      return
    }
    
     
    
    defer {
      if operation.error != nil {
        finishCurrentOperation()
      } else {
        if operation.requiredSeveralResponses {
          waitForNextOperationIteration(waitingTime: operation.awaitingTimeInterval)
        } else {
          finishCurrentOperation()
        }
      }
    }
    
    
    
    if let error = error {
      operation.didReceiveError(error)
      return
    }
    
    // if device respond error
    
    operation.didReceiveData(receivedData)
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
  
  
  open func didWriteValue(error: Error?) {
    /* Should be overriden */
  }
  
  open func didEndOperation(_ operation: BLEoperation) {
    /* Should be overriden */
  }
  
}

extension BLEoperation {
  public func execute(at device: BLEbaseDevice) throws {
    try device.execute(operation: self)
  }
}



//extension BLEbaseDevice {
//  @discardableResult
//  public func trySetCurrentOperation<T: BLEoperation>(_ cls: T.Type, name: BLEoperationName, targetUUID: CBUUID, userInfo: [String :Any] = [:]) throws -> T {
//    let context = T.init(name: name, targetUUID: targetUUID)
//    context.userInfo = userInfo
//    try trySetCurrentOperation(context)
//    return context
//  }
//}
