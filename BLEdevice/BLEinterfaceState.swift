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
  case initial
  case preparing
  case free
  case busy
}
