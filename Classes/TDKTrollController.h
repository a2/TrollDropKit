//
//  TDKTrollController.h
//  TrollDropKit
//
//  Created by Alexsander Akers on 5/5/16.
//  Copyright © 2016 Pandamonia LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TDKPerson : NSObject

@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) NSString *computerName;
@property (nonatomic, readonly) NSString *secondaryName;

@end

typedef BOOL (^TDKTrollControllerShouldTrollHandler)(TDKPerson *person);
typedef NSURL *_Nullable (^TDKTrollControllerSharedURLOverrideHandler)(TDKPerson *person);

@interface TDKTrollController : NSObject

/// The duration to wait after trolling before trolling again.
@property (nonatomic) NSTimeInterval rechargeDuration;

/// The local file URL with which to troll. Defaults to a troll face image.
@property (nonatomic, copy, null_resettable) NSURL *sharedURL;

/// Whether the scanner is currently active.
@property (nonatomic, getter=isRunning) BOOL running;

/// A block handler that allows for fine-grained control of whom to troll.
@property (nonatomic, copy) TDKTrollControllerShouldTrollHandler shouldTrollHandler;

/// A block handler that allows customization of the shared file for certain people.
@property (nonatomic, copy) TDKTrollControllerSharedURLOverrideHandler sharedURLOverrideHandler;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

/// Start scanning for people and troll them.
- (void)start;

/// Stop scanning for people.
- (void)stop;

@end

NS_ASSUME_NONNULL_END
