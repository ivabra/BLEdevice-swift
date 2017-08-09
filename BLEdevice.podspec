Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name         = "BLEdevice"
  s.version      = "0.3.0"
  s.summary      = "Library that eases the way to interact with Bluetooth Low Energy devices."
  
  s.description  = <<-DESC
                    Library that eases the way to interact with Bluetooth Low Energy devices.
                   DESC

  s.homepage     = "https://github.com/ivabra/BLEdevice-swift"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  

  s.license      = "MIT"

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  
  s.author             = { "Ivan Brazhnikov" => "samsungpc239@gmail.com" }

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  
   s.ios.deployment_target = "9.0"
   s.osx.deployment_target = "10.13"
   s.watchos.deployment_target = "4.0"
   s.tvos.deployment_target = "10.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  
  s.source       = { :git => "https://github.com/ivabra/BLEdevice-swift.git", :commit => "1fc54e33b1bea856a305764ed7455df2414a00ac" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source_files  = "BLEdevice", "BLEdevice/**/*.{h,m,swift}"
  s.public_header_files = "BLEdevice/**/*.h"


  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  
  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

   s.framework  = "CoreBluetooth"

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
   s.dependency "XCGLogger"

end
