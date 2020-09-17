# How to distribute

This guide provides instructions on how to distribute the ClarabridgeChat framework as well as the associated API reference documentation

The SDK can be distributed in two ways:

1. **Hosting on CocoaPods:** Host the framework on git or http, and publish a podspec on CocoaPods.

2. **Distribute the framework with a local podspec:** Offer a downloadable package for your customers that includes the framework and a Podspec file that allows the customer to install it locally using CocoaPods command line tools.

We recommend hosting the podspec on CocoaPods for ease of installation for your customers and to facilitate managing updates.

## Hosting on CocoaPods

### Prerequisites
1. Ensure you have `pod` installed. You can install it with `sudo gem install cocoapods`.
1. Register your `pod` trunk on your machine with `pod trunk register your@email.io 'Your Name' --description='My Machine'`. See [CocoapPods Trunk](https://guides.cocoapods.org/making/getting-setup-with-trunk.html) for more details.
1. If the ClarabridgeChat pod is already published, get an invite from the person who originally published it. see [Adding other people as contributors](https://guides.cocoapods.org/making/getting-setup-with-trunk#adding-other-people-as-contributors).

### Publication
1. Host the ClarabridgeChat.framework binary on a server publicly available on the internet. This could be a git repo, svn repo, https url, etc. See the [podspec reference](https://guides.cocoapods.org/syntax/podspec.html#source) for the list of supported types.
2. Create a podspec file based on the [provided example for hosting](./ClarabridgeChat.podspec.example) and fill in these fields :
    - version
    - summary
    - homepage
    - license
    - author
    - source (point to the hosted framework mentioned above. Ex: `:http => "https://company.com/ClarabridgeChat.framework"`)

For more details on each field, see the [official podspec documentation](https://guides.cocoapods.org/syntax/podspec.html).
For reference, you can refer to the [complete podspec](https://github.com/CocoaPods/Specs/blob/master/Specs/2/4/5/Smooch/5.8.2/Smooch.podspec.json) used for Smooch.

3. `pod trunk push ClarabridgeChat.podspec`

## Distribute the framework with a local podspec

1. Create a podspec file based on the [provided example](./redistribution/ClarabridgeChat.podspec.example) in the `redistribution` folder and fill in these fields :
    - version
    - summary
    - homepage
    - license
    - author

For more details on each field, see the [official podspec documentation](https://guides.cocoapods.org/syntax/podspec.html).
For reference, you can refer to the [complete podspec](https://github.com/CocoaPods/Specs/blob/master/Specs/2/4/5/Smooch/5.8.2/Smooch.podspec.json) used for Smooch.

2. Create a zip file that includes the the contents of the `redistribution` folder (the complete podspec file from step 1, the [installation guide](./redistribution/INSTALLATION_GUIDE.MD), and the framework itself).
3. Host the zip file on a server publicly available on the internet, and advise your users to follow the steps in the installation guide.

## Publish the API reference

To distribute the documentation, host the files located at `build/docs/ClarabridgeChat.ClarabridgeChat.docset/Contents/Resources` at your preferred URL.
