use_frameworks!

target 'ConcordeTests', :exclusive => true do

pod 'Nimble'
pod 'Nimble-Snapshots'
pod 'Quick'

end

# Workaround for Xcode >= 7.1 vs. CP 0.39
post_install do |installer|
  `rm -rf ./Pods/Headers`
end

