//
//  Sharing.h
//  TrollDropKit
//
//  Created by Alexsander Akers on 5/5/16.
//  Copyright © 2016 Pandamonia LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

static CFStringRef kTDKSFBrowserKindAirDrop;
static CFStringRef kTDKSFOperationKindSender;
static CFStringRef kTDKSFOperationItemsKey;
static CFStringRef kTDKSFOperationNodeKey;

typedef CF_ENUM(CFIndex, TDKSFOperationEvent) {
    kTDKSFOperationEventUnknown,
    kTDKSFOperationEventNewOperation,
    kTDKSFOperationEventAskUser,
    kTDKSFOperationEventWaitForAnswer,
    kTDKSFOperationEventCanceled,
    kTDKSFOperationEventStarted,
    kTDKSFOperationEventPreprocess,
    kTDKSFOperationEventProgress,
    kTDKSFOperationEventPostprocess,
    kTDKSFOperationEventFinished,
    kTDKSFOperationEventErrorOccurred,
    kTDKSFOperationEventConnecting,
    kTDKSFOperationEventInformation,
    kTDKSFOperationEventConflict,
    kTDKSFOperationEventBlocked,
};

typedef struct TDKSFBrowser *TDKSFBrowserRef;
typedef struct TDKSFNode *TDKSFNodeRef;
typedef struct TDKSFOperation *TDKSFOperationRef;

struct TDKSFBrowserClientContext {
    CFIndex version;
    void *info;
    CFAllocatorRetainCallBack retain;
    CFAllocatorReleaseCallBack release;
    CFAllocatorCopyDescriptionCallBack copyDescription;
};
typedef struct TDKSFBrowserClientContext TDKSFBrowserClientContext;

struct TDKSFOperationClientContext {
    CFIndex version;
    void *info;
    CFAllocatorRetainCallBack retain;
    CFAllocatorReleaseCallBack release;
    CFAllocatorCopyDescriptionCallBack copyDescription;
};
typedef struct TDKSFOperationClientContext TDKSFOperationClientContext;

static TDKSFBrowserRef (*TDKSFBrowserCreate)(CFAllocatorRef alloc, CFStringRef kind);
static void (*TDKSFBrowserSetClient)(TDKSFBrowserRef browser, void *callback, TDKSFBrowserClientContext *clientContext);
static void (*TDKSFBrowserSetDispatchQueue)(TDKSFBrowserRef browser, dispatch_queue_t queue);
static void (*TDKSFBrowserOpenNode)(TDKSFBrowserRef browser, TDKSFNodeRef node, void *protocol, CFOptionFlags flags);
static CFArrayRef (*TDKSFBrowserCopyChildren)(TDKSFBrowserRef browser, TDKSFNodeRef node);
static void (*TDKSFBrowserInvalidate)(TDKSFBrowserRef browser);
static TDKSFNodeRef (*TDKSFBrowserGetRootNode)(TDKSFBrowserRef browser);

static CFStringRef (*TDKSFNodeCopyDisplayName)(TDKSFNodeRef node);
static CFStringRef (*TDKSFNodeCopyComputerName)(TDKSFNodeRef node);
static CFStringRef (*TDKSFNodeCopySecondaryName)(TDKSFNodeRef node);

static TDKSFOperationRef (*TDKSFOperationCreate)(CFAllocatorRef alloc, CFStringRef kind, void *argA, void *argB);
static void (*TDKSFOperationSetClient)(TDKSFOperationRef operation, void *callback, TDKSFOperationClientContext *context);
static void (*TDKSFOperationSetDispatchQueue)(TDKSFOperationRef operation, dispatch_queue_t queue);
static CFTypeRef (*TDKSFOperationCopyProperty)(TDKSFOperationRef operation, CFStringRef name);
static void (*TDKSFOperationSetProperty)(TDKSFOperationRef operation, CFStringRef name, CFTypeRef value);
static void (*TDKSFOperationResume)(TDKSFOperationRef operation);
static void (*TDKSFOperationCancel)(TDKSFOperationRef operation);

static void __TDKSharingInitialize(void *context) {
    CFURLRef bundleURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, CFSTR("/System/Library/PrivateFrameworks/Sharing.framework"), kCFURLPOSIXPathStyle, false);
    CFBundleRef bundle = CFBundleCreate(kCFAllocatorDefault, bundleURL);
    CFRelease(bundleURL);
    if (!bundle) return;

#define SYMBOLS \
    WRAPPER(SFBrowserKindAirDrop)  \
    WRAPPER(SFOperationKindSender) \
    WRAPPER(SFOperationItemsKey)   \
    WRAPPER(SFOperationNodeKey)    \

#define WRAPPER(X) CFSTR("k" #X),
    CFStringRef symbolNames[] = { SYMBOLS };
#define WRAPPER(X) &kTDK ## X,
    void **symbolDestinations[] = { SYMBOLS };
#undef WRAPPER

    CFArrayRef symbolNamesArray = CFArrayCreate(kCFAllocatorDefault, (void **)symbolNames, sizeof(symbolNames) / sizeof(*symbolNames), &kCFTypeArrayCallBacks);

    void **symbols[sizeof(symbolNames) / sizeof(*symbolNames)];
    CFBundleGetDataPointersForNames(bundle, symbolNamesArray, (void **)symbols);
    CFRelease(symbolNamesArray);

    for (size_t i = 0; i < sizeof(symbolNames) / sizeof(*symbolNames); i++) {
        NSCAssert(symbols[i] != NULL, @"Could not find pointer for symbol named \"%@\"", (__bridge id)symbolNames[i]);
        *symbolDestinations[i] = *symbols[i];
    }
#undef SYMBOLS

#define FUNCTIONS \
    WRAPPER(SFBrowserCreate)             \
    WRAPPER(SFBrowserSetClient)          \
    WRAPPER(SFBrowserSetDispatchQueue)   \
    WRAPPER(SFBrowserOpenNode)           \
    WRAPPER(SFBrowserCopyChildren)       \
    WRAPPER(SFBrowserInvalidate)         \
    WRAPPER(SFBrowserGetRootNode)        \
    WRAPPER(SFNodeCopyDisplayName)       \
    WRAPPER(SFNodeCopyComputerName)      \
    WRAPPER(SFNodeCopySecondaryName)     \
    WRAPPER(SFOperationCreate)           \
    WRAPPER(SFOperationSetClient)        \
    WRAPPER(SFOperationSetDispatchQueue) \
    WRAPPER(SFOperationCopyProperty)     \
    WRAPPER(SFOperationSetProperty)      \
    WRAPPER(SFOperationResume)           \
    WRAPPER(SFOperationCancel)           \

#define WRAPPER(X) CFSTR(#X),
    CFStringRef functionNames[] = { FUNCTIONS };
#define WRAPPER(X) &TDK ## X,
    void **functionDestinations[] = { FUNCTIONS };
#undef WRAPPER

    CFArrayRef functionNamesArray = CFArrayCreate(kCFAllocatorDefault, (void **)functionNames, sizeof(functionNames) / sizeof(*functionNames), &kCFTypeArrayCallBacks);

    void *functions[sizeof(functionNames) / sizeof(*functionNames)];
    CFBundleGetFunctionPointersForNames(bundle, functionNamesArray, functions);
    CFRelease(functionNamesArray);

    for (size_t i = 0; i < sizeof(functionNames) / sizeof(*functionNames); i++) {
        NSCAssert(functions[i] != NULL, @"Could not find pointer for function named \"%@\"", (__bridge id)functionNames[i]);
        *functionDestinations[i] = functions[i];
    }
#undef FUNCTIONS

    CFRelease(bundle);
}

static void TDKSharingInitialize(void) {
    static dispatch_once_t onceToken;
    dispatch_once_f(&onceToken, NULL, __TDKSharingInitialize);
}
