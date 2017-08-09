//
//  Logger.swift
//  BLEdevice
//
//  Created by Ivan Brazhnikov on 18/03/2017.
//  Copyright © 2017 Ivan Brazhnikov. All rights reserved.
//

import Foundation
import XCGLogger

let log: XCGLogger = createLogger()

public func BLEDeviceGetLoggerInstance() -> XCGLogger {
  return log
}

private func createLogger() -> XCGLogger {
  let log = XCGLogger(identifier: "AXALockConnect", includeDefaultDestinations: true)
  #if RELEASE
    log.setup(level: .warning,
              showLogIdentifier: true,
              showFunctionName: false,
              showThreadName: false,
              showLevel: true,
              showFileNames: false,
              showLineNumbers: false,
              showDate: true)
  #else
    log.setup(level: .debug,
              showLogIdentifier: true,
              showFunctionName: true,
              showThreadName: false,
              showLevel: false,
              showFileNames: true,
              showLineNumbers: true,
              showDate: true)
  #endif
  return log
}
