use_frameworks!
platform :ios, '13.0'

def test_shared_pods
    pod 'Quick',         '~> 2.2.0'
    pod 'Nimble',        '~> 8.0.5'
end

target 'Persistence' do
  pod 'RealmSwift', '~> 5.3.3'

  target 'PersistenceTests' do
    inherit! :search_paths
    test_shared_pods
  end
end

target 'Domain' do
  pod 'Erik', '~> 5.0.0'
  pod 'PromiseKit', '~> 6.8'

  target 'DomainTests' do
    inherit! :search_paths
    test_shared_pods
  end
end

target 'TBox' do

  pod 'SwiftGen', '~> 6.0'

  target 'TBoxTests' do
    inherit! :search_paths
    test_shared_pods
  end
end

target 'ShareExtension' do
end

target 'TBoxUIKit' do
  pod 'Kingfisher', '~> 5.14.1'

  target 'TBoxUIKitTests' do
    inherit! :search_paths
    test_shared_pods
  end
end

target 'TBoxCore' do
  pod 'PromiseKit', '~> 6.8'
end

target 'TBoxUIKitCatalog' do
end
