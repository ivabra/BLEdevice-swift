//
//  BLEdeviceDelegate.swift
//  BLEdevice
//
//  Created by Ivan Brazhnikov on 07/08/2017.
//  Copyright © 2017 Ivan Brazhnikov. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol BLEdeviceDelegate: class {
  func bleDevice(_ device: BLEdevice, willSendData data: Data, toCharacteristic uuid: CBUUID)
  func bleDevice(_ device: BLEdevice, didSendData data: Data, toCharacteristic uuid: CBUUID)
  
  func bleDevice(_ device: BLEdevice, willExecuteOperation operation: BLEOperation)
  func bleDevice(_ device: BLEdevice, didFinishOperation operation: BLEOperation)
  
  func bleDeviceDidConnect(_ device: BLEdevice)
  func bleDevice(_ device:BLEdevice, didDisconnect error: Error?)
  func bleDevice(_ device: BLEdevice, didFailToConnect error: Error?)
  func bleDevice(_ device: BLEdevice, didEndInitializing error: Error?)
  func bleDevice(_ device: BLEdevice, didWriteValueToCharacteristic uuid: CBUUID, error: Error?)
  func bleDevice(_ device: BLEdevice, didUpdateValueForCharacteristic uuid: CBUUID, error: Error?)
}

