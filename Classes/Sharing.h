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

void TDKSharingInitialize(void);
