//
//  CLBAppDelegateProxy.m
//  ClarabridgeChat
//
//  Copyright (c) 2015 Smooch Technologies. All rights reserved.
//

#import "CLBAppDelegateProxy.h"
#import <objc/runtime.h>
#import "ClarabridgeChat+Private.h"

@implementation CLBAppDelegateProxy

// Store original methods so we can call them later
static void (*didRegisterForRemoteNotificationsOriginalImpl)(id self, SEL _cmd, UIApplication* application, NSData* deviceToken);
static void (*failedToRegisterOriginalImpl)(id self, SEL _cmd, UIApplication* application, NSError* error);
static void (*didReceiveRemoteNotifOriginalImpl)(id self, SEL _cmd, UIApplication* application, NSDictionary* userInfo);
static void (*didReceiveRemoteNotifFetchCompletionOriginalImpl)(id self, SEL _cmd, UIApplication* application, NSDictionary* userInfo, void (^completionHandler)(UIBackgroundFetchResult));
static void (*didHandleRemoteActionWithIdentifierOriginalImpl)(id self, SEL _cmd, UIApplication* application, NSString* identifier, NSDictionary* userInfo, NSDictionary* responseInfo, void (^completionHandler)(void));

static void didRegisterForRemoteNotificationsNewImpl(id self, SEL _cmd, UIApplication* application, NSData* deviceToken) {
    [[ClarabridgeChat clbAppDelegate] application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];

    if(didRegisterForRemoteNotificationsOriginalImpl){
        didRegisterForRemoteNotificationsOriginalImpl(self, _cmd, application, deviceToken);
    }
}

static void failedToRegisterNewImpl(id self, SEL _cmd, UIApplication* application, NSError* error) {
    [[ClarabridgeChat clbAppDelegate] application:application didFailToRegisterForRemoteNotificationsWithError:error];

    if(failedToRegisterOriginalImpl){
        failedToRegisterOriginalImpl(self, _cmd, application, error);
    }
}

static void didReceiveRemoteNotifNewImpl(id self, SEL _cmd, UIApplication* application, NSDictionary* userInfo) {
    [[ClarabridgeChat clbAppDelegate] application:application didReceiveRemoteNotification:userInfo];

    if(didReceiveRemoteNotifOriginalImpl){
        didReceiveRemoteNotifOriginalImpl(self, _cmd, application, userInfo);
    }
}

static void didReceiveRemoteNotifFetchCompletionNewImpl(id self, SEL _cmd, UIApplication* application, NSDictionary* userInfo, void (^completionHandler)(UIBackgroundFetchResult)) {
    [[ClarabridgeChat clbAppDelegate] application:application didReceiveRemoteNotification:userInfo];

    if(didReceiveRemoteNotifFetchCompletionOriginalImpl){
        didReceiveRemoteNotifFetchCompletionOriginalImpl(self, _cmd, application, userInfo, completionHandler);
    }else{
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

static void didHandleRemoteActionWithIdentifierNewImpl(id self, SEL _cmd, UIApplication* application, NSString* identifier, NSDictionary* userInfo, NSDictionary* responseInfo, void (^completionHandler)(void)) {
    [[ClarabridgeChat clbAppDelegate] application:application handleActionWithIdentifier:identifier forRemoteNotification:userInfo withResponseInfo:responseInfo completionHandler:completionHandler];

    if(didHandleRemoteActionWithIdentifierOriginalImpl){
        didHandleRemoteActionWithIdentifierOriginalImpl(self, _cmd, application, identifier, userInfo, responseInfo, completionHandler);
    }
}

static BOOL methodsProxied = NO;

+(void)proxyAppDelegateMethods {
    if(methodsProxied){
        return;
    }
    methodsProxied = YES;

    Class appDelegateClass = [[UIApplication sharedApplication].delegate class];

    [self replaceMethod:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:) ofClass:appDelegateClass with:(IMP)didRegisterForRemoteNotificationsNewImpl storeOriginalImplementation:(IMP *)&didRegisterForRemoteNotificationsOriginalImpl];

    [self replaceMethod:@selector(application:didFailToRegisterForRemoteNotificationsWithError:) ofClass:appDelegateClass with:(IMP)failedToRegisterNewImpl storeOriginalImplementation:(IMP *)&failedToRegisterOriginalImpl];

    [self replaceMethod:@selector(application:didReceiveRemoteNotification:) ofClass:appDelegateClass with:(IMP)didReceiveRemoteNotifNewImpl storeOriginalImplementation:(IMP *)&didReceiveRemoteNotifOriginalImpl];

    [self replaceMethod:@selector(application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:) ofClass:appDelegateClass with:(IMP)didHandleRemoteActionWithIdentifierNewImpl storeOriginalImplementation:(IMP *)&didHandleRemoteActionWithIdentifierOriginalImpl];

    SEL receiveRemoteNotifCompletionHandler = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
    if([appDelegateClass instancesRespondToSelector:receiveRemoteNotifCompletionHandler]){
        [self replaceMethod:receiveRemoteNotifCompletionHandler ofClass:appDelegateClass with:(IMP)didReceiveRemoteNotifFetchCompletionNewImpl storeOriginalImplementation:(IMP *)&didReceiveRemoteNotifFetchCompletionOriginalImpl];
    }
}

+(BOOL)replaceMethod:(SEL)selector ofClass:(Class)class with:(IMP)newImplementation storeOriginalImplementation:(IMP*)methodStore {
    IMP imp = NULL;
    Method method = class_getInstanceMethod(class, selector);
    if (method) {
        const char *type = method_getTypeEncoding(method);
        imp = class_replaceMethod(class, selector, newImplementation, type);
        if (!imp) {
            imp = method_getImplementation(method);
        }
    }else{
        const char *type = @encode(Method);
        class_addMethod(class, selector, newImplementation, type);
    }
    if (imp && methodStore) { *methodStore = imp; }
    return (imp != NULL);
}

@end
