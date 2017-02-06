//
//  BLEoperationName.swift
//  BLEdevice
//
//  Created by Ivan Brazhnikov on 05.02.17.
//  Copyright © 2017 Ivan Brazhnikov. All rights reserved.
//

import Foundation

public struct BLEoperationName {
  public init(rawValue: String) {
    self.rawValue = rawValue
  }
  let rawValue: String
}

extension BLEoperationName: Hashable {
  public var hashValue: Int {
    return rawValue.hashValue
  }
  
  public static func == (left: BLEoperationName, right: BLEoperationName) -> Bool {
    return left.rawValue == right.rawValue
  }
}
