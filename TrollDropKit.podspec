Pod::Spec.new do |s|
  s.name = "TrollDropKit"
  s.version = "0.1.0"
  s.summary = "Send trollfaces via AirDrop to nearby devices."
  s.description = "Scans for nearby devices with AirDrop enabled and sends them a trollface image (or a file of your choice)."
  s.homepage = "https://github.com/a2/TrollDropKit"
  s.license = "MIT"
  s.author = { "Alexsander Akers" => "me@a2.io" }
  s.social_media_url = "https://twitter.com/a2"
  s.source = { :git => "https://github.com/a2/TrollDropKit.git", :tag => "#{s.version}" }
  s.source_files = "Classes", "Classes/**/*.{h,m}"
  s.public_header_files = "Classes/TDKTrollController.h"
  s.ios.deployment_target = "7.0"
  s.tvos.deployment_target = "9.0"
  s.osx.deployment_target = "10.7"
  s.requires_arc = true
end
