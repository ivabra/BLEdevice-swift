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

public enum BLEdeviceError : Error {
  case notPrepared
  case interfaceStateNotFree
  case currentOperationNotCompleted
}

public protocol BLEdevice: class {
  
  static func validatePeripheral(_ peripheral: CBPeripheral) -> Bool
  static func defaultConfiguration() -> BLEdeviceConfiguration
  static func primaryServiceUUID() -> CBUUID
  
  init(peripheral: CBPeripheral, baseQueue: DispatchQueue)
  
  var delegate: BLEdeviceDelegate? { get set }
  var connectionState: CBPeripheralState { get }
  var interfaceState: BLEinterfaceState { get }
  var identifier: UUID { get }
  var name: String? { get }
  
  func prepare()
  
  func getPeripheral() throws -> CBPeripheral
  
  func didConnect()
  func didDisconnect(error: Error?)
  func didFailToConnect(error: Error?)
  
  func charateristicValue(forUUID uuid: CBUUID) -> Data?
  func readCharateristicValue(forUUID uuid: CBUUID) throws
  func send(data: Data, forCharacteristicUUID uuid: CBUUID) throws

  var currentOperation: BLEOperation? { get }
  
  func executeOperation(_ operation: BLEOperation)
  func dropCurrentOperation()
  func dropAllOperations()
}

