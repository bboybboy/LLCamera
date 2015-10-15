Pod::Spec.new do |s|
  s.name         = "LLCamera"
  s.version      = "2.4.1"
  s.summary      = "LLCamera is a simple custom camera with AVFoundation"
  s.description  = <<-DESC
                    LLCamera is a simple custom camera with AVFoundation, completely customizable.
                   DESC
  s.homepage     = "https://github.com/bboybboy/LLCamera"
  s.license      = "MIT"
  s.author             = { "Vadik Kovalsky" => "kovalsky.v@gmail.com" }
  s.social_media_url   = "http://google.com"
  s.platform = :ios, '6.0'
  s.source = { :git => 'https://github.com/bboybboy/LLCamera.git' }
  s.source_files = 'DBCamera/Categories/*.{h,m}', 'DBCamera/Controllers/*.{h,m}', 'DBCamera/Headers/*.{h,m}', 'DBCamera/Managers/*.{h,m}', 'DBCamera/Objects/*.{h,m}', 'DBCamera/Views/*.{h,m}', 'DBCamera/Filters/*.{h,m}'
  s.resources = ['DBCamera/Resources/*.{xib,xcassets}', 'DBCamera/Localizations/DBCamera.bundle']
  s.framework = 'AVFoundation', 'CoreMedia', 'QuartzCore'
  s.requires_arc = true
  s.dependency 'GPUImage', '~> 0.1'
end
