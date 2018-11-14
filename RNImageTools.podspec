
Pod::Spec.new do |s|
  s.name         = "RNImageTools"
  s.version      = "1.0.0"
  s.summary      = "RNImageTools"
  s.description  = <<-DESC
                  A collection of image processing tools for React Native
                   DESC
  s.homepage     = "https://github.com/wowmaking/react-native-image-tools"
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "Dmitry Kazlouski" => "dkazlouski@wowmaking.net" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/wowmaking/react-native-image-tools", :tag => "master" }
  s.source_files  = "ios/**/*.{h,m}"
  s.requires_arc = true


  s.dependency "React"
  #s.dependency "others"

end

