//
//  Utils.swift
//  BLEdevice
//
//  Created by Ivan Brazhnikov on 09/08/2017.
//  Copyright © 2017 Ivan Brazhnikov. All rights reserved.
//

import Foundation


infix operator +?
func +?<T>(left: String, right: T?) -> String {
  return left + (right.flatMap {"\($0)"} ?? "")
}

extension Optional {
  func flatMap<U>(or: U, transform: (Wrapped) throws -> U? ) rethrows -> U {
    return try flatMap(transform) ?? or
  }
  
  func description(or descriptionWhenNil: String) -> String {
    return flatMap { "\($0)" } ?? descriptionWhenNil
  }
  
  func spaceDescription(or descriptionWhenNil: String) -> String {
    return flatMap { " \($0)" } ?? descriptionWhenNil
  }
  
  func spaceDescriptionOrEmpty() -> String {
    return spaceDescription(or: "")
  }
  
  var descriptionOrNil: String {
    return description(or: "nil")
  }
  
  var descriptionOrEmpty: String {
    return description(or: "")
  }
}
