//
//  BLEdeviceConfiguration.swift
//  BLEdevice
//
//  Created by Ivan Brazhnikov on 05.02.17.
//  Copyright © 2017 Ivan Brazhnikov. All rights reserved.
//

import Foundation
import CoreBluetooth


@objc
public class BLEdeviceConfiguration: NSObject {
  
  public let serviceDescriptions: [ServiceDescription]
  
  
  fileprivate let _servicesMap: [CBUUID : ServiceDescription]
  fileprivate let _characteristicMap: [CBUUID : CharacterisicDescription]
  fileprivate let _characteristicToServiceUUIDMap:[CBUUID: CBUUID]
  
  
  public init(serviceDescriptions: [ServiceDescription]) {
    
    
    /* Initialize services map */
    var serviceMap = [CBUUID: ServiceDescription]()
    for s in serviceDescriptions {
      serviceMap[s.serviceUUID] = s
    }
    self._servicesMap = serviceMap
    
    
    
    /* Initialize characteristic map */
    var characteristicMap = [CBUUID : CharacterisicDescription]()
    for ch in serviceDescriptions.flatMap ({ $0.characteristics }) {
      characteristicMap[ch.uuid] = ch
    }
    self._characteristicMap = characteristicMap
    
    
    /* Initialize characteristic to service map */
    var chToS = [CBUUID : CBUUID]()
    for s in serviceDescriptions {
      for ch in s.characteristics {
        chToS[ch.uuid] = s.serviceUUID
      }
    }
    self._characteristicToServiceUUIDMap = chToS
    
    self.serviceDescriptions = serviceDescriptions
  }
  
}


extension BLEdeviceConfiguration {
  
  @nonobjc
  public static var empty: BLEdeviceConfiguration {
    return BLEdeviceConfiguration(serviceDescriptions: [])
  }
  
  
  public convenience init(serviceDescription: ServiceDescription) {
    self.init(serviceDescriptions: [serviceDescription])
  }
  
  @nonobjc
  public convenience init(object: [String : [String : (type: CBCharacteristicWriteType?, notify: Bool)]]) {
    let services = object.map { serviceUUID, characteristicInfo -> ServiceDescription in
      let characteristics = characteristicInfo.map { uuid, info in
        CharacterisicDescription(uuid: CBUUID(string: uuid), writeType: info.type, notify: info.notify)
      }
      return ServiceDescription(serviceUUID: CBUUID(string: serviceUUID), characteristics: characteristics)
    }
    self.init(serviceDescriptions: services)
  }
  
  public func characteristicDescription(for uuid: CBUUID) -> CharacterisicDescription {
    if let characteristic = _characteristicMap[uuid] {
      return characteristic
    }
    fatalError("Characteristic with such UUID did not registered")
  }
  
  
  
  public func serviceDescription(for uuid: CBUUID) -> ServiceDescription {
    if let service = _servicesMap[uuid] {
      return service
    }
    fatalError("Characteristic with such UUID did not registered")
  }
  
  
  
  public func serviceUUID(forCharacteristicUUID uuid: CBUUID) -> CBUUID {
    if let service = _characteristicToServiceUUIDMap[uuid] {
      return service
    }
    fatalError("Characteristic with such UUID did not registered")
  }
  
  
  public var servicesUUIDs : [CBUUID] {
    return serviceDescriptions.map { $0.serviceUUID }
  }
}



public struct CharacterisicDescription {
  public let uuid: CBUUID
  public let writeType: CBCharacteristicWriteType?
  public let notify: Bool
  
  public init(uuid: CBUUID, writeType: CBCharacteristicWriteType? = nil, notify: Bool = false) {
    self.uuid = uuid
    self.writeType = writeType
    self.notify = notify
  }
  
}


public class ServiceDescription {
  public var serviceUUID: CBUUID
  public var characteristics: [CharacterisicDescription]
  
  public init(serviceUUID: CBUUID, characteristics: [CharacterisicDescription]) {
    self.serviceUUID = serviceUUID
    self.characteristics = characteristics
  }
}
