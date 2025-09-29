#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_facebook_app_links'
  s.version          = '3.1.1'
  s.summary          = 'A Flutter plugin to catch deferred deep links from Facebook ads with FB App Links SDK.'
  s.description      = <<-DESC
Flutter plugin for Facebook App Links SDK with GDPR consent support
                       DESC
  s.homepage         = 'https://github.com/twinsunllc/flutter_facebook_app_links'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'TwinSun LLC' => 'support@twinsunllc.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'FBSDKCoreKit', '~> 18.0'
  s.swift_version       = '5.0'

  s.ios.deployment_target = '12.0'
end
