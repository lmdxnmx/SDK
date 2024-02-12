Pod::Spec.new do |spec|
  spec.name         = "IoMT.SDK"
  spec.version      = "0.0.1"
  spec.summary      = "IoMT.SDK is a tool for collect and send medical measurements from Bluetooth devices"
  
  spec.description  = <<-DESC
  IoMT.SDK is a tool for collect and send medical measurements from Bluetooth devices
  DESC
  
  spec.homepage     = "http://EXAMPLE/IoMT.SDK"
  spec.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  spec.author       = { "ArooiD" => "deniss.komissarov@gmail.com" }
  spec.source_files = 'IoMT.SDK/**/*.{swift}'
  spec.ios.deployment_target = '11.0'
  spec.swift_version = '5.0'
  spec.source       = { :git => "https://github.com/ArooiD/IoMT.SDK/IoMT.SDK.git", :tag => "#{spec.version}" }
  spec.preserve_paths = 'IoMT.SDK/*'
end
