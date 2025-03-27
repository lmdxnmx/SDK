Pod::Spec.new do |spec|
  spec.name         = "IoMT.SDK"
  spec.version      = "0.3.9"
  spec.summary      = "IoMT.SDK is a tool for collecting and sending medical measurements from Bluetooth devices"
  
  spec.description  = <<-DESC
  IoMT.SDK is a tool for collecting and sending medical measurements from Bluetooth devices
  DESC
  spec.homepage     = "https://github.com/lmdxnmx/SDK.git"
  spec.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  spec.author       = { "lmdxnmx" => "nikita021103@mail.ru" }
  spec.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  spec.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  spec.source_files = 'IoMT.SDK/**/*.{swift}'
  spec.ios.deployment_target = '11.0'
  spec.swift_version = '5.7.2'
  spec.source       = { :git => "https://github.com/lmdxnmx/SDK.git", :tag => "#{spec.version.to_s}" }
  spec.dependency 'ReachabilitySwift', '~> 5.0'
  spec.resources = 'IoMT.SDK/*.xcdatamodeld'
  spec.vendored_frameworks = 'IoMT.SDK/Frameworks/lame.framework'
  spec.vendored_libraries = 'IoMT.SDK/libs/**/*.a'
end
