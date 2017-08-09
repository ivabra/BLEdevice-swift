//
//  BLEinterfaceState.swift
//  BLEdevice
//
//  Created by Ivan Brazhnikov on 05.02.17.
//  Copyright © 2017 Ivan Brazhnikov. All rights reserved.
//

import Foundation

public enum BLEinterfaceState {
  case needPrepare
  case preparing
  case ready
}

extension BLEinterfaceState: CustomStringConvertible, CustomDebugStringConvertible {
  
  public var description: String {
    switch self {
    case .needPrepare : return "Need to prepare"
    case .preparing: return "Preparing"
    case .ready: return "Ready"
    }
  }
  
  public var debugDescription: String {
    return "\(description, hashValue))"
  }
}
