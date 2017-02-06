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
  var targetCharacteristicUUID: CBUUID { get }
  
  var timeIntervalForNextOperation: TimeInterval? { get }
  var error: Error? { get }
  var result: Any? { get }
  var userInfo: [String : Any] { get set }
  
  var sendingData: Data { get }
  
  init(name: BLEoperationName, targetUUID: CBUUID)
  
  func didReceiveData(_ data: Data)
  func didReceiveError(_ error: Error)
  func didComplete()
}

open class BLEbaseOperation: BLEoperation {
  
  public let name: BLEoperationName
  public let targetCharacteristicUUID: CBUUID
  
  public var timeIntervalForNextOperation: TimeInterval?
  
  open var error: Error?
  open var result: Any?
  open var userInfo: [String : Any]
  
  open var sendingData: Data {
    return .init()
  }
  
  required public init(name: BLEoperationName, targetUUID: CBUUID) {
    self.name = name
    self.targetCharacteristicUUID = targetUUID
    self.userInfo = [:]
  }
  
  open func didReceiveData(_ data: Data) {
    
  }
  
  open func didReceiveError(_ error: Error) {
    
  }
  
  open func didComplete() {
    
  }
  
}
