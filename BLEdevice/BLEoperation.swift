//
//  BLEoperation.swift
//  BLEdevice
//
//  Created by Ivan Brazhnikov on 05.02.17.
//  Copyright © 2017 Ivan Brazhnikov. All rights reserved.
//

import Foundation
import CoreBluetooth

public enum BLEOperationError: Error {
  case interrupted
}

public protocol BLEOperation: class, CustomStringConvertible {
  var name: String { get }
  var error: Error? { get }
  var userInfo: [String : Any] { get }
  var executionTimestamp: TimeInterval { get }
  
  var isFinished: Bool { get }
  
  func canRespondOnCharacteristic(characteristicUUID: CBUUID) -> Bool
  func canRespondOnData(data: Data) -> Bool
  
  var responseTimeout: TimeInterval { get }
  //var hasNextIteration: Bool { get }
  
  func start() throws
  
  func didUpdateValue(forCharacteristicUUID uuid: CBUUID, error: Error?)
  func didWriteValue(forCharacteristicUUID uuid: CBUUID, error: Error?)
  func didReceiveExternalError(_ error: Error)
  
  func timeout()
}


extension BLEOperation {
  public var description: String {
    return "\(name)(\(type(of: self)))"
  }
}


open class BLEBaseOperation: BLEOperation {
  
  
  private var executedOnce: Bool = false
  public internal(set) var interactor: PeripheralInteractor!
  
  public let operationName: BLEoperationName
  
  public var name: String {
    return operationName.rawValue
  }
  
  public init(name: String) {
    self.operationName = BLEoperationName(rawValue: name)
  }
  
  public convenience init(name: BLEoperationName) {
    self.init(name: name.rawValue)
  }
  
  public var error: Error?
  public var userInfo: [String : Any] = [:]
  public var allowedResponseCharacteristicUUIDs: Set<CBUUID> = []
  
  public var responseTimeout: TimeInterval = 3.0
  public var executionTimestamp: TimeInterval = Date().timeIntervalSinceReferenceDate
  
  
  open var isFinished: Bool {
    return executedOnce == true || error != nil
  }
  
  
  open func canRespondOnCharacteristic(characteristicUUID: CBUUID) -> Bool {
    return allowedResponseCharacteristicUUIDs.contains(characteristicUUID)
  }
  
  open func canRespondOnData(data: Data) -> Bool {
    return true
  }
  
  func updateExecutionTimestamp() {
    self.executionTimestamp = Date.timeIntervalSinceReferenceDate
  }
  
  final public func start() throws {
     log.debug(self)
     self.executedOnce = true
     updateExecutionTimestamp()
     try main()
     log.debug("\(self) was started")
  }
  
  open func main() throws {
   
  }
  
  open func didUpdateValue(forCharacteristicUUID uuid: CBUUID, error: Error?) {}
  
  open func didWriteValue(forCharacteristicUUID uuid: CBUUID, error: Error?) {}
  
  open func timeout() {
    log.debug("Timeout for \(type(of: self))")
  }
  
  open func didReceiveExternalError(_ error: Error) {
    self.error = error
  }
  
}

