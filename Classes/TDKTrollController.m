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

static void browserCallback(SFBrowserRef browser, SFNodeRef node, CFArrayRef children, void *argA, void *argB, void *context);
static void operationCallback(SFOperationRef operation, SFOperationEvent event, CFTypeRef results, void *context);
static void dictionaryValueApplier(const void *key, const void *value, void *context);

@implementation TDKPerson

+ (instancetype)personWithNode:(id)node
{
    SFNodeRef nodeRef = (__bridge SFNodeRef)node;

    TDKPerson *person = [[self alloc] init];
    person->_displayName = (__bridge_transfer id)SFNodeCopyDisplayName(nodeRef);
    person->_computerName = (__bridge_transfer id)SFNodeCopyComputerName(nodeRef);
    person->_secondaryName = (__bridge_transfer id)SFNodeCopySecondaryName(nodeRef);

    return person;
}

@end

@interface TDKTrollController ()

@property (nonatomic, nullable) SFBrowserRef browser;
@property (nonatomic, nullable, copy) NSSet /* <SFNodeRef> */ *people;

@end

@implementation TDKTrollController
{
    CFMutableDictionaryRef /* <SFNodeRef, SFOperationRef> */ _operations;
}

@synthesize sharedURL = _sharedURL;

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

- (void)setBrowser:(SFBrowserRef)browser
{
    // Release old browser.
    if (_browser) CFRelease(_browser);

    // Retain new browser - if there is one.
    _browser = browser ? (SFBrowserRef)CFRetain(browser) : NULL;
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

+ (id)propertyFromNode:(id)node withCopyFunction:(CFTypeRef (*)(SFNodeRef))function
{
    return (__bridge_transfer id)function((__bridge SFNodeRef)node);
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

    SFBrowserClientContext clientContext = {
        .version = 0,
        .info = (__bridge void *)self,
    };

    SFBrowserRef browser = SFBrowserCreate(kCFAllocatorDefault, kSFBrowserKindAirDrop);
    SFBrowserSetClient(browser, &browserCallback, &clientContext);
    SFBrowserSetDispatchQueue(browser, dispatch_get_main_queue());
    SFBrowserOpenNode(browser, NULL, NULL, 0);
    self.browser = browser;
}

/// Stop the browser and clean up browsing state.
- (void)stop
{
    if (!self.running) return;

    // Cancel dormant trollings.
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    // Cancel pending operations.
    CFDictionaryApplyFunction(_operations, &dictionaryValueApplier, &SFOperationCancel);

    // Empty operations map.
    CFDictionaryRemoveAllValues(_operations);

    // Invalidate the browser.
    SFBrowserInvalidate(self.browser);
    self.browser = NULL;
}

#pragma mark - Troll

/// Troll the person/device identified by \c node (\c SFNodeRef)
- (void)troll:(id)node
{
    NSArray *items = @[[self fileURLForNode:node]];

    SFOperationClientContext clientContext = {
        .version = 0,
        .info = (__bridge void *)self,
    };

    SFOperationRef operation = SFOperationCreate(kCFAllocatorDefault, kSFOperationKindSender, NULL, NULL);
    SFOperationSetClient(operation, &operationCallback, &clientContext);
    SFOperationSetProperty(operation, kSFOperationNodeKey, (__bridge SFNodeRef)node);
    SFOperationSetProperty(operation, kSFOperationItemsKey, (__bridge CFArrayRef)items);
    SFOperationSetDispatchQueue(operation, dispatch_get_main_queue());
    SFOperationResume(operation);

    [self setOperation:(__bridge_transfer id)operation forNode:node];
}

#pragma mark - Callbacks

/// Browser callback.
/// Invoked when a child is added or removed from the browser's root node.
/// Invoked from the C function at EOF.
- (void)handleBrowserCallback:(SFBrowserRef)browser node:(SFNodeRef)node children:(CFArrayRef)children
{
    NSArray *nodes = (__bridge_transfer NSArray *)SFBrowserCopyChildren(browser, NULL);
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
- (void)handleOperationCallback:(SFOperationRef)operation event:(SFOperationEvent)event results:(CFTypeRef)results
{
    switch (event) {
        case kSFOperationEventAskUser:
            // Seems that .AskUser requires the operation to be resumed.
            SFOperationResume(operation);
            break;

        case kSFOperationEventCanceled:
        case kSFOperationEventErrorOccurred:
        case kSFOperationEventFinished: {
            // Schedule a new trolling if the operation has ended.
            id node = (__bridge_transfer id)SFOperationCopyProperty(operation, kSFOperationNodeKey);
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

static void browserCallback(SFBrowserRef browser, SFNodeRef node, CFArrayRef children, void *argA, void *argB, void *context) {
    [(__bridge TDKTrollController *)context handleBrowserCallback:browser node:node children:children];
}

static void operationCallback(SFOperationRef operation, SFOperationEvent event, CFTypeRef results, void *context) {
    [(__bridge TDKTrollController *)context handleOperationCallback:operation event:event results:results];
}

static void dictionaryValueApplier(const void *key, const void *value, void *context) {
    ((void (*)(const void *))context)(value);
}
