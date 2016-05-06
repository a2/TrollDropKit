//
//  Sharing.h
//  TrollDropKit
//
//  Created by Alexsander Akers on 5/5/16.
//  Copyright © 2016 Pandamonia LLC. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>

extern const CFStringRef kSFBrowserKindAirDrop;
extern const CFStringRef kSFOperationKindSender;
extern const CFStringRef kSFOperationItemsKey;
extern const CFStringRef kSFOperationNodeKey;

typedef CF_ENUM(CFIndex, SFOperationEvent) {
    kSFOperationEventUnknown,
    kSFOperationEventNewOperation,
    kSFOperationEventAskUser,
    kSFOperationEventWaitForAnswer,
    kSFOperationEventCanceled,
    kSFOperationEventStarted,
    kSFOperationEventPreprocess,
    kSFOperationEventProgress,
    kSFOperationEventPostprocess,
    kSFOperationEventFinished,
    kSFOperationEventErrorOccurred,
    kSFOperationEventConnecting,
    kSFOperationEventInformation,
    kSFOperationEventConflict,
    kSFOperationEventBlocked,
};

typedef struct SFBrowser *SFBrowserRef;
typedef struct SFNode *SFNodeRef;
typedef struct SFOperation *SFOperationRef;

struct SFBrowserClientContext {
    CFIndex version;
    void *info;
    CFAllocatorRetainCallBack retain;
    CFAllocatorReleaseCallBack release;
    CFAllocatorCopyDescriptionCallBack copyDescription;
};
typedef struct SFBrowserClientContext SFBrowserClientContext;

struct SFOperationClientContext {
    CFIndex version;
    void *info;
    CFAllocatorRetainCallBack retain;
    CFAllocatorReleaseCallBack release;
    CFAllocatorCopyDescriptionCallBack copyDescription;
};
typedef struct SFOperationClientContext SFOperationClientContext;

extern SFBrowserRef SFBrowserCreate(CFAllocatorRef alloc, CFStringRef kind);
extern void SFBrowserSetClient(SFBrowserRef browser, void *callback, SFBrowserClientContext *clientContext);
extern void SFBrowserSetDispatchQueue(SFBrowserRef browser, dispatch_queue_t queue);
extern void SFBrowserOpenNode(SFBrowserRef browser, SFNodeRef node, void *protocol, CFOptionFlags flags);
extern CFArrayRef SFBrowserCopyChildren(SFBrowserRef browser, SFNodeRef node);
extern void SFBrowserInvalidate(SFBrowserRef browser);
extern SFNodeRef SFBrowserGetRootNode(SFBrowserRef browser);

extern CFStringRef SFNodeCopyDisplayName(SFNodeRef node);
extern CFStringRef SFNodeCopyComputerName(SFNodeRef node);
extern CFStringRef SFNodeCopySecondaryName(SFNodeRef node);

extern SFOperationRef SFOperationCreate(CFAllocatorRef alloc, CFStringRef kind, void *argA, void *argB);
extern void SFOperationSetClient(SFOperationRef operation, void *callback, SFOperationClientContext *context);
extern void SFOperationSetDispatchQueue(SFOperationRef operation, dispatch_queue_t queue);
extern CFTypeRef SFOperationCopyProperty(SFOperationRef operation, CFStringRef name);
extern void SFOperationSetProperty(SFOperationRef operation, CFStringRef name, CFTypeRef value);
extern void SFOperationResume(SFOperationRef operation);
extern void SFOperationCancel(SFOperationRef operation);
