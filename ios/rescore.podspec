#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint rescore.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'rescore'
  s.version          = '0.0.1'
  s.summary          = 'Duet Rescore Library Implementation'
  s.description      = <<-DESC
Duet Rescore Library Implementation
                       DESC
  s.homepage         = 'http://www.rescore.app'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Alastair Carey' => 'alastair@alastaircarey.com' }
  s.source           = { :path => '.' }
  s.public_header_files = 'Classes**/*.h'
  s.source_files = 'Classes/**/*'
  s.static_framework = true
  s.vendored_libraries = "**/*.a"
  s.dependency 'Flutter'
  s.platform = :ios, '8.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
end
