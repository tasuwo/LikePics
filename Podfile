use_frameworks!
inhibit_all_warnings!
platform :ios, '14.0'

def test_shared_pods
    pod 'Quick',         '~> 3.0.0'
    pod 'Nimble',        '~> 9.0.0'
end

target 'TBox' do
  pod 'LicensePlist', '~> 3.0.4'
  pod 'SwiftGen', '~> 6.4.0'
  pod 'Sourcery', '~> 1.0.3'

  target 'TBoxTests' do
    inherit! :search_paths
    test_shared_pods
  end
end

target 'Persistence' do
  pod 'RealmSwift', '~> 10.5.1'

  target 'PersistenceTests' do
    inherit! :search_paths
    test_shared_pods
  end
end

target 'Domain' do
  target 'DomainTests' do
    inherit! :search_paths
    test_shared_pods
  end
end

target 'ShareExtension' do
end

target 'TBoxUIKit' do
  target 'TBoxUIKitTests' do
    inherit! :search_paths
    test_shared_pods
  end
end

target 'TBoxCore' do
  pod 'Erik', '~> 5.0.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
    end
    if target.name.include?('Realm')
      target.build_configurations.each do |config|
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      end
    end
  end
end

