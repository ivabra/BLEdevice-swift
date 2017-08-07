//
//  ViewController.swift
//  BLEdevice-Sample
//
//  Created by Ivan Brazhnikov on 05.02.17.
//  Copyright © 2017 Ivan Brazhnikov. All rights reserved.
//

import UIKit
import BLEdevice
import CoreBluetooth


class ViewController: UIViewController, BLEdeviceCentralManagerDelegate, BLEdeviceDelegate {

  var manager: BLEdeviceCentralManager!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    manager = BLEdeviceCentralManagerCreate(queue: .main, restoreIdentifier: "main")
    manager.registerDeviceType(SimpleDevice.self)
    manager.delegate = self
    
    // Do any additional setup after loading the view, typically from a nib.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


  func bleDeviceManager(_ manager: BLEdeviceCentralManager, didDiscoverDevice device: BLEdevice, rssi: NSNumber) {
     device.delegate = self
  }
}

class SimpleDevice: BLEbaseDevice {
  
  override class func defaultConfiguration() -> BLEdeviceConfiguration {
    
    let characteristic: [CharacterisicDescription] = [
      .init(uuid: CBUUID(string: "0xF0080003-0451-4000-B000-000000000000"), writeType: .withResponse),
      .init(uuid: CBUUID(string: "0xF0080002-0451-4000-B000-000000000000"), notify: true)
    ]
    
    let serviceDescription = ServiceDescription(serviceUUID:      CBUUID(string: "0xF0080001-0451-4000-B000-000000000000"),
                                                characteristics:  characteristic)
    
    let configuration = BLEdeviceConfiguration(serviceDescription: serviceDescription)
    
    return configuration
  }
  
  override init(peripheral: CBPeripheral, config: BLEdeviceConfiguration) {
    super.init(peripheral: peripheral, config: config)
  }
  
  
  
}
