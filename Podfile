platform :ios, '17.0'

install! 'cocoapods', :deterministic_uuids => false

target 'FreeAPISample' do
  use_frameworks!

  pod 'Alamofire', '~> 5.9'
  pod 'SDWebImage', '~> 5.19'
  pod 'SDWebImageSwiftUI', '~> 2.1'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'YES'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'YES'
      config.build_settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = 'Apple Development'
      config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = 'Apple Development'
      config.build_settings['DEVELOPMENT_TEAM'] = 'WCMK4Y9GWR'
    end
  end
end