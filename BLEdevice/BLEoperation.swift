//
//  BLEoperation.swift
//  BLEdevice
//
//  Created by Ivan Brazhnikov on 05.02.17.
//  Copyright © 2017 Ivan Brazhnikov. All rights reserved.
//

import Foundation
import CoreBluetooth

/*
public protocol BLEoperation: class {
  
  var name: BLEoperationName { get }
  var requestCharacteristicUUID: CBUUID! { get set }
  var responseCharacteristicUUID: CBUUID! { get set }
  
  var awaitingTimeInterval: TimeInterval! { get set }
  var requiredSeveralResponses: Bool { get }
  
  var error: Error? { get } 
  var userInfo: [String : Any] { get set }
  
  var sendingData: Data { get }
  
  init(name: BLEoperationName)
  
  func didReceiveData(_ data: Data)
  func didReceiveError(_ error: Error)
  func didComplete()
  
  func validateThisOperationIsDestination(for data: Data) -> Bool
}



open class BLEbaseOperation: BLEoperation {
  
  public let name: BLEoperationName
  public var requestCharacteristicUUID: CBUUID!
  public var responseCharacteristicUUID: CBUUID!
  
  open var awaitingTimeInterval: TimeInterval!
  
  public var requiredSeveralResponses: Bool {
    return false
  }
  
  open var error: Error?
  open var userInfo: [String : Any]
  
  open var sendingData: Data {
    return .init()
  }
  
  required public init(name: BLEoperationName) {
    self.name = name
    self.userInfo = [:]
  }
  
  open func validateThisOperationIsDestination(for data: Data) -> Bool {
    fatalError("Method not implemented yet")
  }
  
  open func didReceiveData(_ data: Data) {
    
  }
  
  open func didReceiveError(_ error: Error) {
    if self.error == nil {
      self.error = error
    }
  }
  
  open func didComplete() {
    
  }
  
}
*/

public enum BLEOperationError: Error {
  case interrupted
}


@objc public protocol BLEOperation: class {
  var name: String { get }
  var error: Error? { get }
  var userInfo: [String : Any] { get }
  var executionTimestamp: TimeInterval { get }
  
  func canRespondOnCharacteristic(characteristicUUID: CBUUID) -> Bool
  func canRespondOnData(data: Data) -> Bool
  
  var responseTimeout: TimeInterval { get }
  var hasNextIteration: Bool { get }
  
  func start() throws
  
  func didUpdateValue(_ data: Data, forCharacteristicUUID uuid: CBUUID, error: Error?)
  func didWriteValue(forCharacteristicUUID uuid: CBUUID, error: Error?)
  func didReceiveExternalError(_ error: Error)
  
  func timeout()
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
  
  open var hasNextIteration: Bool {
    return executedOnce == false
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
     self.executedOnce = true
     updateExecutionTimestamp()
     try main()
  }
  
  open func main() throws {
   
  }
  
  open func didUpdateValue(_ data: Data, forCharacteristicUUID uuid: CBUUID, error: Error?) {
    
  }
  
  open func didWriteValue(forCharacteristicUUID uuid: CBUUID, error: Error?) {
    
  } 
  
  open func timeout() {
    
  }
  
  open func didReceiveExternalError(_ error: Error) {
    self.error = error
  }
  
}

