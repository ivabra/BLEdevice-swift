//
//  BLEDevice.swift
//  BLEdevice
//
//  Created by Ivan Brazhnikov on 04.02.17.
//  Copyright © 2017 Ivan Brazhnikov. All rights reserved.
//

import Foundation
import CoreBluetooth

@objc public protocol BLEdeviceDelegate: class {
  @objc optional func bleDeviceDidConnect(_ device: BLEdevice)
  @objc optional func bleDevice(_ device:BLEdevice, didDisconnect error: Error?)
  @objc optional func bleDevice(_ device: BLEdevice, didFailToConnect error: Error?)
  @objc optional func bleDeviceDidChangeInterfaceState(_ device: BLEdevice)
  @objc optional func bleDevice(_ device: BLEdevice, didEndInitializing error: Error?)
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
  
  func getPeripheral() throws -> CBPeripheral
  
  func didConnect()
  func didDisconnect(error: Error?)
  func didFailToConnect(error: Error?)
  
  func waitCurrentOperation() throws
  
}

