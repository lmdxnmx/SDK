Pod::Spec.new do |spec|
  spec.name         = "IoMT.SDK"
  spec.version      = "0.0.1"
  spec.summary      = "IoMT.SDK is a tool for collecting and sending medical measurements from Bluetooth devices"
  
  spec.description  = <<-DESC
  IoMT.SDK is a tool for collecting and sending medical measurements from Bluetooth devices
  DESC
  spec.xcconfig = {
    :LIBRARY_SEARCH_PATHS => 'IoMT.SDK/Decoder',
    :OTHER_CFLAGS => '$(inherited)',
    :OTHER_LDFLAGS => '$(inherited)',
    :HEADER_SEARCH_PATHS => 'IoMT.SDK/Decoder',
  }
  spec.homepage     = "http://EXAMPLE/IoMT.SDK"
  spec.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  spec.author       = { "ArooiD" => "deniss.komissarov@gmail.com" }
  spec.vendored_libraries = 'IoMT.SDK/Decoder'
  spec.source_files = 'IoMT.SDK/**/*.{swift}'
  spec.ios.deployment_target = '11.0'
  spec.swift_version = '5.0'
  spec.source       = { :git => "https://github.com/lmdxnmx/SDK.git", :tag => "#{spec.version}" }
  spec.dependency 'ReachabilitySwift', '~> 5.0'
  spec.resources = 'IoMT.SDK/*.xcdatamodeld'
end
