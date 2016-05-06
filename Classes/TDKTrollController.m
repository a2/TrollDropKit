//
//  TDKTrollController.m
//  TrollDropKit
//
//  Created by Alexsander Akers on 5/5/16.
//  Copyright © 2016 Pandamonia LLC. All rights reserved.
//

#import "TDKTrollController.h"
#import "Sharing.h"
#import "Trollface.h"

static void browserCallback(TDKSFBrowserRef browser, TDKSFNodeRef node, CFArrayRef children, void *argA, void *argB, void *context);
static void operationCallback(TDKSFOperationRef operation, TDKSFOperationEvent event, CFTypeRef results, void *context);
static void dictionaryValueApplier(const void *key, const void *value, void *context);

@implementation TDKPerson

+ (instancetype)personWithNode:(id)node
{
    TDKSFNodeRef nodeRef = (__bridge TDKSFNodeRef)node;

    TDKPerson *person = [[self alloc] init];
    person->_displayName = (__bridge_transfer id)TDKSFNodeCopyDisplayName(nodeRef);
    person->_computerName = (__bridge_transfer id)TDKSFNodeCopyComputerName(nodeRef);
    person->_secondaryName = (__bridge_transfer id)TDKSFNodeCopySecondaryName(nodeRef);

    return person;
}

@end

@interface TDKTrollController ()

@property (nonatomic, nullable) TDKSFBrowserRef browser;
@property (nonatomic, nullable, copy) NSSet /* <TDKSFNodeRef> */ *people;

@end

@implementation TDKTrollController
{
    CFMutableDictionaryRef /* <TDKSFNodeRef, TDKSFOperationRef> */ _operations;
}

@synthesize sharedURL = _sharedURL;

+ (void)initialize
{
    if (self == [TDKTrollController class]) {
        TDKSharingInitialize();
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _operations = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        _rechargeDuration = 15.0;
    }

    return self;
}

- (void)dealloc
{
    // Stop if we are running.
    // Invalidates and cleans up browsing state.
    [self stop];

    // Clean up CF ivars.
    CFRelease(_operations);
}

#pragma mark - Accessors

- (NSURL *)sharedURL
{
    if (!_sharedURL) {
        _sharedURL = [TDKTrollController writeTrollfaceToTemporaryFile];
    }

    return _sharedURL;
}

- (void)setSharedURL:(NSURL *)newURL
{
    _sharedURL = newURL ? [newURL copy] : [TDKTrollController writeTrollfaceToTemporaryFile];
}

- (void)setBrowser:(TDKSFBrowserRef)browser
{
    // Release old browser.
    if (_browser) CFRelease(_browser);

    // Retain new browser - if there is one.
    _browser = browser ? (TDKSFBrowserRef)CFRetain(browser) : NULL;
}

#pragma mark - Node Operations

/// The in-progress operation for the node, if it exists.
- (nullable id)operationForNode:(id)node
{
    return (__bridge id)CFDictionaryGetValue(_operations, (__bridge void *)node);
}

/// Associates an operation with a given node.
- (void)setOperation:(nullable id)operation forNode:(id)node
{
    void *key = (__bridge void *)node;
    if (operation) {
        CFDictionarySetValue(_operations, key, (__bridge void *)operation);
    } else {
        CFDictionaryRemoveValue(_operations, key);
    }
}

+ (id)propertyFromNode:(id)node withCopyFunction:(CFTypeRef (*)(TDKSFNodeRef))function
{
    return (__bridge_transfer id)function((__bridge TDKSFNodeRef)node);
}

/// If there is a \c sharedURLOverrideHandler and it returns a non-nil URL, prefer that over the \c sharedURL.
- (NSURL *)fileURLForNode:(id)node
{
    NSURL *fileURL = self.sharedURL;
    if (self.sharedURLOverrideHandler) {
        TDKPerson *person = [TDKPerson personWithNode:node];
        NSURL *overrideURL = self.sharedURLOverrideHandler(person);
        if (overrideURL) {
            fileURL = overrideURL;
        }
    }

    return fileURL;
}

#pragma mark - Start / Stop

/// Whether the browser is running.
- (BOOL)isRunning
{
    return self.browser != NULL;
}

/// KVO compliance for \c isRunning
+ (NSSet *)keyPathsForValuesAffectingRunning
{
    return [NSSet setWithObject:@"browser"];
}

/// Start the browser.
- (void)start
{
    if (self.running) return;

    TDKSFBrowserClientContext clientContext = {
        .version = 0,
        .info = (__bridge void *)self,
    };

    TDKSFBrowserRef browser = TDKSFBrowserCreate(kCFAllocatorDefault, kTDKSFBrowserKindAirDrop);
    TDKSFBrowserSetClient(browser, &browserCallback, &clientContext);
    TDKSFBrowserSetDispatchQueue(browser, dispatch_get_main_queue());
    TDKSFBrowserOpenNode(browser, NULL, NULL, 0);
    self.browser = browser;
}

/// Stop the browser and clean up browsing state.
- (void)stop
{
    if (!self.running) return;

    // Cancel dormant trollings.
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    // Cancel pending operations.
    CFDictionaryApplyFunction(_operations, &dictionaryValueApplier, &TDKSFOperationCancel);

    // Empty operations map.
    CFDictionaryRemoveAllValues(_operations);

    // Invalidate the browser.
    TDKSFBrowserInvalidate(self.browser);
    self.browser = NULL;
}

#pragma mark - Troll

/// Troll the person/device identified by \c node (\c TDKSFNodeRef)
- (void)troll:(id)node
{
    NSArray *items = @[[self fileURLForNode:node]];

    TDKSFOperationClientContext clientContext = {
        .version = 0,
        .info = (__bridge void *)self,
    };

    TDKSFOperationRef operation = TDKSFOperationCreate(kCFAllocatorDefault, kTDKSFOperationKindSender, NULL, NULL);
    TDKSFOperationSetClient(operation, &operationCallback, &clientContext);
    TDKSFOperationSetProperty(operation, kTDKSFOperationNodeKey, (__bridge TDKSFNodeRef)node);
    TDKSFOperationSetProperty(operation, kTDKSFOperationItemsKey, (__bridge CFArrayRef)items);
    TDKSFOperationSetDispatchQueue(operation, dispatch_get_main_queue());
    TDKSFOperationResume(operation);

    [self setOperation:(__bridge_transfer id)operation forNode:node];
}

#pragma mark - Callbacks

/// Browser callback.
/// Invoked when a child is added or removed from the browser's root node.
/// Invoked from the C function at EOF.
- (void)handleBrowserCallback:(TDKSFBrowserRef)browser node:(TDKSFNodeRef)node children:(CFArrayRef)children
{
    NSArray *nodes = (__bridge_transfer NSArray *)TDKSFBrowserCopyChildren(browser, NULL);
    NSMutableSet *newPeople = [NSMutableSet setWithCapacity:nodes.count];

    for (id node in nodes) {
        BOOL isAwareOfPerson = [self.people containsObject:node] || [self operationForNode:node] != nil;
        BOOL shouldTroll = !self.shouldTrollHandler || self.shouldTrollHandler([TDKPerson personWithNode:node]);

        if (!isAwareOfPerson && shouldTroll) {
            [self troll:node];
        }

        [newPeople addObject:node];
    }

    self.people = newPeople;
}

/// Operation callback.
/// Invoked when the operation triggers an event.
/// Invoked from the C function at EOF.
- (void)handleOperationCallback:(TDKSFOperationRef)operation event:(TDKSFOperationEvent)event results:(CFTypeRef)results
{
    switch (event) {
        case kTDKSFOperationEventAskUser:
            // Seems that .AskUser requires the operation to be resumed.
            TDKSFOperationResume(operation);
            break;

        case kTDKSFOperationEventCanceled:
        case kTDKSFOperationEventErrorOccurred:
        case kTDKSFOperationEventFinished: {
            // Schedule a new trolling if the operation has ended.
            id node = (__bridge_transfer id)TDKSFOperationCopyProperty(operation, kTDKSFOperationNodeKey);
            [self setOperation:nil forNode:node];
            [self performSelector:@selector(troll:) withObject:node afterDelay:self.rechargeDuration];
            break;
        }

        default:
            break;
    }
}

#pragma mark - Trollface Data / URL Helpers

/// The trollface image as JPEG data.
+ (NSData *)trollface
{
    return [NSData dataWithBytesNoCopy:__trollface length:__trollface_len freeWhenDone:NO];
}

/// The destination (in temporary storage) of the trollface file.
+ (NSURL *)temporaryTrollfaceURL
{
    return [NSURL fileURLWithPathComponents:@[NSTemporaryDirectory(), @"trollface.jpg"]];
}

/// Writes the trollface data to a temporary URL and returns that URL.
+ (NSURL *)writeTrollfaceToTemporaryFile
{
    NSURL *trollfaceURL = [self temporaryTrollfaceURL];
    [[self trollface] writeToURL:trollfaceURL options:NSDataWritingWithoutOverwriting error:NULL];
    return trollfaceURL;
}

@end

static void browserCallback(TDKSFBrowserRef browser, TDKSFNodeRef node, CFArrayRef children, void *argA, void *argB, void *context) {
    [(__bridge TDKTrollController *)context handleBrowserCallback:browser node:node children:children];
}

static void operationCallback(TDKSFOperationRef operation, TDKSFOperationEvent event, CFTypeRef results, void *context) {
    [(__bridge TDKTrollController *)context handleOperationCallback:operation event:event results:results];
}

static void dictionaryValueApplier(const void *key, const void *value, void *context) {
    ((void (*)(const void *))context)(value);
}
