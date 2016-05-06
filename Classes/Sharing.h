//
//  Sharing.h
//  TrollDropKit
//
//  Created by Alexsander Akers on 5/5/16.
//  Copyright © 2016 Pandamonia LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

extern CFStringRef kTDKSFBrowserKindAirDrop;
extern CFStringRef kTDKSFOperationKindSender;
extern CFStringRef kTDKSFOperationItemsKey;
extern CFStringRef kTDKSFOperationNodeKey;

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

extern TDKSFBrowserRef (*TDKSFBrowserCreate)(CFAllocatorRef alloc, CFStringRef kind);
extern void (*TDKSFBrowserSetClient)(TDKSFBrowserRef browser, void *callback, TDKSFBrowserClientContext *clientContext);
extern void (*TDKSFBrowserSetDispatchQueue)(TDKSFBrowserRef browser, dispatch_queue_t queue);
extern void (*TDKSFBrowserOpenNode)(TDKSFBrowserRef browser, TDKSFNodeRef node, void *protocol, CFOptionFlags flags);
extern CFArrayRef (*TDKSFBrowserCopyChildren)(TDKSFBrowserRef browser, TDKSFNodeRef node);
extern void (*TDKSFBrowserInvalidate)(TDKSFBrowserRef browser);
extern TDKSFNodeRef (*TDKSFBrowserGetRootNode)(TDKSFBrowserRef browser);

extern CFStringRef (*TDKSFNodeCopyDisplayName)(TDKSFNodeRef node);
extern CFStringRef (*TDKSFNodeCopyComputerName)(TDKSFNodeRef node);
extern CFStringRef (*TDKSFNodeCopySecondaryName)(TDKSFNodeRef node);

extern TDKSFOperationRef (*TDKSFOperationCreate)(CFAllocatorRef alloc, CFStringRef kind, void *argA, void *argB);
extern void (*TDKSFOperationSetClient)(TDKSFOperationRef operation, void *callback, TDKSFOperationClientContext *context);
extern void (*TDKSFOperationSetDispatchQueue)(TDKSFOperationRef operation, dispatch_queue_t queue);
extern CFTypeRef (*TDKSFOperationCopyProperty)(TDKSFOperationRef operation, CFStringRef name);
extern void (*TDKSFOperationSetProperty)(TDKSFOperationRef operation, CFStringRef name, CFTypeRef value);
extern void (*TDKSFOperationResume)(TDKSFOperationRef operation);
extern void (*TDKSFOperationCancel)(TDKSFOperationRef operation);

void TDKSharingInitialize(void);
