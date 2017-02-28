//
//  BLEoperation.swift
//  BLEdevice
//
//  Created by Ivan Brazhnikov on 05.02.17.
//  Copyright © 2017 Ivan Brazhnikov. All rights reserved.
//

import Foundation
import CoreBluetooth

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
