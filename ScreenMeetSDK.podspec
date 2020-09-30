#
#

Pod::Spec.new do |s|
  s.name             = 'ScreenMeetSDK'
  s.version          = '1.0.0'
  s.summary          = 'ScreenMeetSDK allows share your app screen to support agent'

  s.description      = <<-DESC
  ScreenMeetSDK allows share your app screen to support agent
                       DESC

  s.homepage         = 'https://github.com/screenmeet/screenmeet-sdk-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ScreenMeet' => 'sdksupport@screenmeet.com' }
  s.source           = { :git => ''git@github.com:screenmeet/screenmeet-sdk-ios.git, :tag => s.version.to_s }
  
  s.swift_version = '5.0'
  s.ios.deployment_target = '12.0'

  s.source_files = 'ScreenMeetSDK/Classes/**/*'
  s.resource_bundles = {
      'ScreenMeetResource' => ['ScreenMeetSDK/Resources/*.{xib,storyboard,xcassets}']
  }
  
  s.dependency  'Socket.IO-Client-Swift', '~> 15.2'
  s.dependency  'GoogleWebRTC', '~> 1.1'
end
