platform :ios, '14.0'

target 'Reverse Text' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  pod 'Firebase/Core'
  pod 'Firebase/MLVision'
  pod 'Firebase/MLVisionTextModel'
pod 'Firebase/Analytics'
pod 'FirebaseDatabase'
pod 'FirebaseAuth'



end

post_install do |installer|
     installer.pods_project.targets.each do |target|
         target.build_configurations.each do |config|
            if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 14.0
              config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
            end
         end
     end
  end
