# Installation guide

To add the ClarabridgeChat.framework library to your XCode project, follow the steps below to install the framework using CocoaPods

1. First, install [CocoaPods](https://cocoapods.org/) if it isn't already

```bash
gem install cocoapods
```

2. Copy the `ClarabridgeChat.framework` and `ClarabridgeChat.podspec` files somewhere in your project directory, for example in `vendor/ClarabridgeChat`
3. Add the ClarabridgeChat dependency to your [Podfile](https://guides.cocoapods.org/using/the-podfile.html), using a local `path` that points to the directory in step 2

```ruby
target 'YourApp' do
    pod 'ClarabridgeChat', :path => 'vendor/ClarabridgeChat'
end
```

4. Install the pod

```bash
pod install
```

5. Open the generated `.xcworkspace` file and add the following keys to your app's Info.plist file (replacing the values if desired):

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>${PRODUCT_NAME} will read your photo library to gather additional information</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>${PRODUCT_NAME} will write to your photo library to gather additional information</string>
<key>NSCameraUsageDescription</key>
<string>${PRODUCT_NAME} will use your camera to gather additional information</string>
```

6. Start using the framework in your code.

Objective-C:

```objc
#import <ClarabridgeChat/ClarabridgeChat.h>

[ClarabridgeChat initWithSettings:[CLBSettings settingsWithIntegrationId:@"YOUR_INTEGRATION_ID"] completionHandler:^(NSError * _Nullable error, NSDictionary * _Nullable userInfo) {
    // Your code after init is complete
}];
```

Swift:

```swift
ClarabridgeChat.initWith(CLBSettings(integrationId: "YOUR_INTEGRATION_ID")) { (error: Error?, userInfo: [AnyHashable : Any]?) in
    // Your code after init is complete
}
```
