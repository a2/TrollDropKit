//
//  Sharing.m
//  TrollDropKit
//
//  Created by Alexsander Akers on 5/5/16.
//  Copyright © 2016 Pandamonia LLC. All rights reserved.
//

#import "Sharing.h"

CFStringRef kTDKSFBrowserKindAirDrop;
CFStringRef kTDKSFOperationKindSender;
CFStringRef kTDKSFOperationItemsKey;
CFStringRef kTDKSFOperationNodeKey;

TDKSFBrowserRef (*TDKSFBrowserCreate)(CFAllocatorRef alloc, CFStringRef kind);
void (*TDKSFBrowserSetClient)(TDKSFBrowserRef browser, void *callback, TDKSFBrowserClientContext *clientContext);
void (*TDKSFBrowserSetDispatchQueue)(TDKSFBrowserRef browser, dispatch_queue_t queue);
void (*TDKSFBrowserOpenNode)(TDKSFBrowserRef browser, TDKSFNodeRef node, void *protocol, CFOptionFlags flags);
CFArrayRef (*TDKSFBrowserCopyChildren)(TDKSFBrowserRef browser, TDKSFNodeRef node);
void (*TDKSFBrowserInvalidate)(TDKSFBrowserRef browser);
TDKSFNodeRef (*TDKSFBrowserGetRootNode)(TDKSFBrowserRef browser);

CFStringRef (*TDKSFNodeCopyDisplayName)(TDKSFNodeRef node);
CFStringRef (*TDKSFNodeCopyComputerName)(TDKSFNodeRef node);
CFStringRef (*TDKSFNodeCopySecondaryName)(TDKSFNodeRef node);

TDKSFOperationRef (*TDKSFOperationCreate)(CFAllocatorRef alloc, CFStringRef kind, void *argA, void *argB);
void (*TDKSFOperationSetClient)(TDKSFOperationRef operation, void *callback, TDKSFOperationClientContext *context);
void (*TDKSFOperationSetDispatchQueue)(TDKSFOperationRef operation, dispatch_queue_t queue);
CFTypeRef (*TDKSFOperationCopyProperty)(TDKSFOperationRef operation, CFStringRef name);
void (*TDKSFOperationSetProperty)(TDKSFOperationRef operation, CFStringRef name, CFTypeRef value);
void (*TDKSFOperationResume)(TDKSFOperationRef operation);
void (*TDKSFOperationCancel)(TDKSFOperationRef operation);

static void __TDKSharingInitialize(void *context) {
    CFURLRef bundleURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, CFSTR("/System/Library/PrivateFrameworks/Sharing.framework"), kCFURLPOSIXPathStyle, false);
    CFBundleRef bundle = CFBundleCreate(kCFAllocatorDefault, bundleURL);
    CFRelease(bundleURL);
    if (!bundle) return;

    CFErrorRef error = NULL;
    if (!CFBundleLoadExecutableAndReturnError(bundle, &error)) {
        CFRelease(bundle);
        return;
    }

#define SYMBOLS \
    WRAPPER(SFBrowserKindAirDrop)  \
    WRAPPER(SFOperationKindSender) \
    WRAPPER(SFOperationItemsKey)   \
    WRAPPER(SFOperationNodeKey)    \

#define WRAPPER(X) CFSTR("k" #X),
    CFStringRef symbolNames[] = { SYMBOLS };
#undef WRAPPER

#define WRAPPER(X) (void *)&kTDK ## X,
    void **symbolDestinations[] = { SYMBOLS };
#undef WRAPPER

    CFArrayRef symbolNamesArray = CFArrayCreate(kCFAllocatorDefault, (const void **)symbolNames, sizeof(symbolNames) / sizeof(*symbolNames), &kCFTypeArrayCallBacks);

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
#undef WRAPPER

#define WRAPPER(X) (void (**)(void))&TDK ## X,
    void (**functionDestinations[])(void) = { FUNCTIONS };
#undef WRAPPER

    CFArrayRef functionNamesArray = CFArrayCreate(kCFAllocatorDefault, (const void **)functionNames, sizeof(functionNames) / sizeof(*functionNames), &kCFTypeArrayCallBacks);

    void (*functions[sizeof(functionNames) / sizeof(*functionNames)])(void);
    CFBundleGetFunctionPointersForNames(bundle, functionNamesArray, (void **)functions);
    CFRelease(functionNamesArray);

    for (size_t i = 0; i < sizeof(functionNames) / sizeof(*functionNames); i++) {
        NSCAssert(functions[i] != NULL, @"Could not find pointer for function named \"%@\"", (__bridge id)functionNames[i]);
        *(functionDestinations[i]) = functions[i];
    }
#undef FUNCTIONS

    CFRelease(bundle);
}

void TDKSharingInitialize(void) {
    static dispatch_once_t onceToken;
    dispatch_once_f(&onceToken, NULL, __TDKSharingInitialize);
}
