//
//  AppDelegate.m
//  NewsLetter
//
//  Created by JunfengLi on 15/8/16.
//  Copyright (c) 2015年 JunfengLi. All rights reserved.
//

#import "AppDelegate.h"
#import "SinaConfig.h"
#import <SSKeychain.h>

#define kSinaWeiboDidLogin @"SinaWeiboDidLogin"
#define kSinaWeiboDidLogout @"SinaWeiboDidLogout"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [WeiboSDK enableDebugMode:YES];
    [WeiboSDK registerApp:kAppKey];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kSinaWeiboDidLogin
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                                      self.window.rootViewController = [mainStoryboard instantiateInitialViewController];
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kSinaWeiboDidLogout
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      UIStoryboard *loginStoryboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
                                                      self.window.rootViewController = [loginStoryboard instantiateInitialViewController];
                                                  }];
    
    if ([self isAuthorized]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kSinaWeiboDidLogin object:nil];
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(nonnull UIApplication *)application openURL:(nonnull NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(nonnull id)annotation
{
    return [WeiboSDK handleOpenURL:url delegate:self];
}

- (BOOL)application:(nonnull UIApplication *)application handleOpenURL:(nonnull NSURL *)url
{
    return [WeiboSDK handleOpenURL:url delegate:self];
}

#pragma mark - Methods

- (BOOL)isAuthorized
{
    NSString *accessToken = [SSKeychain passwordForService:@"NewsLetter" account:@"accessToken"];
    NSString *userID = [SSKeychain passwordForService:@"NewsLetter" account:@"userID"];
    BOOL isAuthorizeExpired = [self isAuthorizeExpired];
    return accessToken && userID && !isAuthorizeExpired;
}

- (BOOL)isAuthorizeExpired
{
    NSDate *expiresIn = [[NSUserDefaults standardUserDefaults] objectForKey:@"expiresIn"];
    if (expiresIn) {
        NSDate *now = [NSDate date];
        return ([now compare:expiresIn] == NSOrderedDescending);
    }
    
    return NO;
}

#pragma mark - WeiboSDKDelegate

- (void)didReceiveWeiboResponse:(WBBaseResponse *)response
{
    if ([response isKindOfClass:[WBAuthorizeResponse class]]) {
        WBAuthorizeResponse *authorizeResponse = (WBAuthorizeResponse *)response;
        
        NSError *accessTokenError;
        [SSKeychain setPassword:authorizeResponse.accessToken forService:@"NewsLetter" account:@"accessToken" error:&accessTokenError];
        if (accessTokenError) {
            NSLog(@"accessToken 写入失败: %@", accessTokenError);
        }
        
        NSError *refreshTokenError;
        [SSKeychain setPassword:authorizeResponse.refreshToken forService:@"NewsLetter" account:@"refreshToken" error:&refreshTokenError];
        if (refreshTokenError) {
            NSLog(@"refreshToken 写入失败: %@", refreshTokenError);
        }
        
        //        NSError *expiresInError;
        //        [SSKeychain setPassword:authorizeResponse.userInfo[@"expires_in"] forService:@"NewsLetter" account:@"expiresIn" error:&expiresInError];
        //        if (expiresInError) {
        //            NSLog(@"expiresIn 写入失败: %@", expiresInError);
        //        }
        [[NSUserDefaults standardUserDefaults] setObject:authorizeResponse.expirationDate forKey:@"expiresIn"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSError *userIDError;
        [SSKeychain setPassword:authorizeResponse.userID forService:@"NewsLetter" account:@"userID" error:&userIDError];
        if (userIDError) {
            NSLog(@"userID 写入失败: %@", userIDError);
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kSinaWeiboDidLogin object:nil];
    }
}

@end
