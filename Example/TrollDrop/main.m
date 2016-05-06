//
//  main.m
//  TrollDrop
//
//  Created by Alexsander Akers on 5/6/16.
//  Copyright © 2016 Pandamonia LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TrollDropKit/TDKTrollController.h>

static BOOL shouldKeepRunning = YES;

static void terminationHandler(int signum) {
    shouldKeepRunning = NO;
}

static void configureHandlers() {
    struct sigaction action;
    memset(&action, 0, sizeof(struct sigaction));
    action.sa_handler = terminationHandler;

    if (sigaction(SIGINT, &action, NULL) < 0) {
        perror("sigaction");
    }

    if (sigaction(SIGTERM, &action, NULL) < 0) {
        perror("sigaction");
    }
}

int main(int argc, const char *argv[]) {
    configureHandlers();

    NS_VALID_UNTIL_END_OF_SCOPE TDKTrollController *trollController = [[TDKTrollController alloc] init];

    printf("Begin the trolling...\n");
    [trollController start];

    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    while (shouldKeepRunning && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]]);

    [trollController stop];
    printf("Trolling stopped.\n");

    return 0;
}
