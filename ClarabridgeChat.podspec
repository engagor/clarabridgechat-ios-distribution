Pod::Spec.new do |s|
  s.name                  = "ClarabridgeChat"
  s.version               = "3.1.0"
  s.summary               = "Clarabridge iOS Chat SDK"
  s.homepage              = "https://www.clarabridge.com/"
  s.author                = { "YOU" => "anthony.meirlaen@clarabrige.com" }
  s.source 	              = { :git => 'https://github.com/engagor/clarabridgechat-ios-distribution.git', :tag =>"v3.1.0" }
  s.license               = { :type => "Commercial", :text => "https://app.engagor.com/privacy-policy" }
  s.preserve_paths        = "build/ClarabridgeChat.xcframework/*"
  s.frameworks            = "ClarabridgeChat", "CoreText", "SystemConfiguration", "CoreTelephony", "Foundation", "CoreGraphics", "UIKit", "QuartzCore", "AssetsLibrary", "Photos", "AVFoundation", "CFNetwork"
  s.library               = "icucore"
  s.xcconfig              = { "FRAMEWORK_SEARCH_PATHS" => "$(PODS_ROOT)/ClarabridgeChat" }
  s.vendored_frameworks   = "build/ClarabridgeChat.xcframework"
  s.requires_arc          = true
  s.platform              = :ios
  s.ios.deployment_target = '8.0'
end
