//
//  Errors.swift
//  BLEdevice
//
//  Created by Ivan Brazhnikov on 04.02.17.
//  Copyright © 2017 Ivan Brazhnikov. All rights reserved.
//

import Foundation

public enum BLEerror: Error {
  case serviceNotDiscovered
  case characteristicNotDiscovered
}

