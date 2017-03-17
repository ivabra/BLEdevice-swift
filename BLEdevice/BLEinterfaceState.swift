//
//  BLEinterfaceState.swift
//  BLEdevice
//
//  Created by Ivan Brazhnikov on 05.02.17.
//  Copyright © 2017 Ivan Brazhnikov. All rights reserved.
//

import Foundation

@objc
public enum BLEinterfaceState: Int {
  case initial = 0
  case preparing = 1
  case free = 2
  case busy = 3
}

extension BLEinterfaceState: CustomStringConvertible, CustomDebugStringConvertible {
  public var description: String {
    switch self {
    case .initial : return "Initital"
    case .preparing: return "Preparing"
    case .free: return "Free"
    case .busy: return "Busy"
    }
  }
  
  public var debugDescription: String {
    return "\(description, rawValue))"
  }
}
