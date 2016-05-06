//
//  AppDelegate.m
//  TrollDrop
//
//  Created by Alexsander Akers on 5/6/16.
//  Copyright © 2016 Pandamonia LLC. All rights reserved.
//

#import "AppDelegate.h"

#import <TrollDropKit/TDKTrollController.h>

@interface AppDelegate ()

@property (nonatomic, readonly, strong) TDKTrollController *trollController;

@end

@implementation AppDelegate

- (instancetype)init
{
    self = [super init];
    if (self) {
        _trollController = [[TDKTrollController alloc] init];
    }

    return self;
}

#pragma mark - App Delegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self.trollController start];
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self.trollController start];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self.trollController stop];
}

@end
