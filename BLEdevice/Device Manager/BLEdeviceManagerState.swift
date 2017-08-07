//
//  BLEdeviceManagerState.swift
//  BLEdevice
//
//  Created by Ivan Brazhnikov on 07/08/2017.
//  Copyright © 2017 Ivan Brazhnikov. All rights reserved.
//

import CoreBluetooth

public enum BLEdeviceManagerState {
  
  case unknown
  case resetting
  case unsupported
  case unauthorized
  case poweredOff
  case poweredOn
  
  
  @available(iOS 10.0, macOS 10.13, *)
  init(_ state: CBManagerState) {
    switch state {
    case .unknown:      self = .unknown
    case .resetting:    self = .resetting
    case .unsupported:  self = .unsupported
    case .unauthorized: self = .unauthorized
    case .poweredOff:   self = .poweredOff
    case .poweredOn:    self = .poweredOn
    }
  }
  
  init(_ state: CBCentralManagerState) {
    switch state {
    case .unknown:      self = .unknown
    case .resetting:    self = .resetting
    case .unsupported:  self = .unsupported
    case .unauthorized: self = .unauthorized
    case .poweredOff:   self = .poweredOff
    case .poweredOn:    self = .poweredOn
    }
  }
}
