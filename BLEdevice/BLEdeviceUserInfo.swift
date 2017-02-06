//
//  BLEdeviceUserInfo.swift
//  BLEdevice
//
//  Created by Ivan Brazhnikov on 05.02.17.
//  Copyright © 2017 Ivan Brazhnikov. All rights reserved.
//

import Foundation


public class BLEdeviceUserInfo {
  private var storage: [AnyHashable: Any] = [:]
  
  public func putValue(_ value: Any?, for key: AnyHashable) {
    storage[key] = value
  }
  
  public func deleteValue(for key: AnyHashable) {
    storage.removeValue(forKey: key)
  }
  
  public func getValue(for key: AnyHashable) -> Any? {
    return storage[key]
  }
  
}
