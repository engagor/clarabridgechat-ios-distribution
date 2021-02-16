# ClarabridgeChat

This repository contains all the source code for the iOS SDK, as well as a built version and instructions on how to distribute it to your customers.

The structure for the repository is as follows:

| Filename        | Description                                               |
|-----------------|-----------------------------------------------------------|
| source          | Contains the source for the SDK                           |
| build           | Contains the ready to distribute binaries                 |
| build/doc       | API reference documentation in appledocs format           |
| HOWTODISTRIBUTE | Guide which explains how to distribute the SDK to your customers |
| README          | This guide                                                |

# Distribution

For instructions on how to distribute, follow the [how to distribute](./HOWTODISTRIBUTE.MD) guide.

# Development / Testing

## Using the pre-built framework

To test the pre-built framework in your own application, follow the steps below to link the SDK to your app.

These steps are provided for testing purposes only. Linking the framework in this way will result in errors when trying to submit your application to the App Store. For production distribution instructions, follow the instructions in the [how to distribute](./HOWTODISTRIBUTE.MD) guide.

1. Copy the `ClarabridgeChat.xcframework` file from the `build` directory into your project directory.
2. Add the framework to your Xcode project by selecting `File` > `Add Files to "My_Project"` and selecting `xcClarabridgeChat.framework` in the file picker.
3. In your project settings, add `ClarabridgeChat.xcframework` to the list of `Embedded Binaries` in the `General` tab for your application target.

You should now be able to import the framework (`#import <ClarabridgeChat/ClarabridgeChat.h>`) and start using it in your code.

## Using the Xcode project

To test using the provided Xcode project and source code, follow the steps below to add `ClarabridgeChat.xcodeproj` as a dependent project of your application.

1. Add the project file to your Xcode project by selecting `File` > `Add Files to "My_Project"` and selecting `ClarabridgeChat.xcodeproj` in the file picker. `ClarabridgeChat.xcodeproj` can be found in the `source` directory of this repository
2. In your project settings, navigate to the `Build Phases` tab, and click the `+` button under the `Target Dependencies` section.
3. Select the `ClarabridgeChat` framework to add it as a target dependency of your project

You should now be able to import the framework (`#import <ClarabridgeChat/ClarabridgeChat.h>`) and start using it in your code.

# Version

This is version 3.1.0 of ClarabridgeChat. It corresponds to version [10.1.0](https://github.com/smooch/smooch-ios/releases/tag/10.1.0) of the Smooch iOS SDK.
