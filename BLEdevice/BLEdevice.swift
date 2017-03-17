//
//  BLEDevice.swift
//  BLEdevice
//
//  Created by Ivan Brazhnikov on 04.02.17.
//  Copyright © 2017 Ivan Brazhnikov. All rights reserved.
//

import Foundation
import CoreBluetooth
import XCGLogger

extension XCGLogger {
  static func create() -> XCGLogger {
    let log = XCGLogger(identifier: "BLEdevice", includeDefaultDestinations: true)
    log.setup(level: .debug,
              showLogIdentifier: true,
              showFunctionName: true,
              showThreadName: false,
              showLevel: false,
              showFileNames: false,
              showLineNumbers: false,
              showDate: true)
    return log
  }
}

let log = XCGLogger.create()

@objc public protocol BLEdeviceDelegate: class {
  
  @objc optional func bleDevice(_ device: BLEdevice, willSendData data: Data, toCharateristic characteristicUUID: CBUUID)
  @objc optional func bleDevice(_ device: BLEdevice, didSendData data: Data, toCharateristic characteristicUUID: CBUUID)
  
  @objc optional func bleDevice(_ device: BLEdevice, willExecuteOperation operation: BLEOperation)
  @objc optional func bleDevice(_ device: BLEdevice, didFinishOperation operation: BLEOperation)
  
  @objc optional func bleDeviceDidConnect(_ device: BLEdevice)
  @objc optional func bleDevice(_ device:BLEdevice, didDisconnect error: Error?)
  @objc optional func bleDevice(_ device: BLEdevice, didFailToConnect error: Error?)
  @objc optional func bleDeviceDidChangeInterfaceState(_ device: BLEdevice)
  @objc optional func bleDevice(_ device: BLEdevice, didEndInitializing error: Error?)
  @objc optional func bleDevice(_ device: BLEdevice, didWriteValueForCharacteristicUUID uuid: CBUUID, error: Error?)
  @objc optional func bleDevice(_ device: BLEdevice, didUpdateValueForCharacteristicUUID uuid: CBUUID, error: Error?)
}




public enum BLEdeviceError : Error {
  case notPrepared
  case interfaceStateNotFree
  case currentOperationNotCompleted
}


@objc public protocol BLEdevice: class {
  
  static func validatePeripheral(_ peripheral: CBPeripheral) -> Bool
  static func defaultConfiguration() -> BLEdeviceConfiguration
  static func primaryServiceUUID() -> CBUUID
  
  init(peripheral: CBPeripheral)
  
  var delegate: BLEdeviceDelegate? { get set }
  var connectionState: CBPeripheralState { get }
  var interfaceState: BLEinterfaceState { get }
  var identifier: UUID { get }
  var name: String? { get }
  
  func prepare()
  var isPrepared: Bool { get }
  
  func getPeripheral() throws -> CBPeripheral
  
  func didConnect()
  func didDisconnect(error: Error?)
  func didFailToConnect(error: Error?)
  
  func charateristicValue(forUUID uuid: CBUUID) -> Data?
  func readCharateristicValue(forUUID uuid: CBUUID) throws
  func send(data: Data, forCharacteristicUUID uuid: CBUUID) throws

  func executeOperation(_ operation: BLEOperation) throws
  var currentOperation: BLEOperation? { get }
  func dropCurrentOperaton()
}

