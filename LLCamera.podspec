Pod::Spec.new do |s|
  s.name         = "LLCamera"
  s.summary      = "LLCamera is a simple custom camera with AVFoundation"
  s.description  = <<-DESC
                    LLCamera is a simple custom camera with AVFoundation, completely customizable.
                   DESC
  s.homepage     = "https://github.com/bboybboy/LLCamera"
  s.license      = "MIT"
  s.author             = { "Vadik Kovalsky" => "kovalsky.v@gmail.com" }
  s.social_media_url   = "http://google.com"
  s.platform = :ios, '8.0'
  s.source = { :git => 'https://github.com/bboybboy/LLCamera.git' }
  s.source_files = 'LLCamera/Categories/*.{h,m}', 'LLCamera/Controllers/*.{h,m}', 'LLCamera/Headers/*.{h,m}', 'LLCamera/Managers/*.{h,m}', 'LLCamera/Objects/*.{h,m}', 'LLCamera/Views/*.{h,m}', 'LLCamera/Filters/*.{h,m}'
  s.resources = ['LLCamera/Resources/*.{xib,xcassets}', 'LLCamera/Localizations/LLCamera.bundle']
  s.frameworks = 'AVFoundation', 'CoreMedia', 'QuartzCore'
  s.requires_arc = true
end
