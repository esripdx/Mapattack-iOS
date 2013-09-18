//
//  GLUdpConnection.m
//  Mapattack-iOS
//
//  Created by kenichi nakamura on 9/18/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import "GLUdpConnection.h"
#import "MessagePack.h"

NSString *const GLMapAttackHostname = @"mapattack.org";
int const GLMapAttackPort = 5309;

static const int GLMapAttackUdpSendDataTimeout = -1;

static GLUdpConnection *instance;

@implementation GLUdpConnection
{
    GCDAsyncUdpSocket *socket;
    long queueCounter;
}

#pragma mark -

// get the singleton instance with a specified hostname to connect to
//
+ (GLUdpConnection *)getConnectionForHostname:(NSString *)hostname
{
    if (!instance) {
        instance = [[GLUdpConnection alloc] initWithHostname:hostname];
    }
    return instance;
}

// get the singleton instance with the default hostname to connect to
//
+ (GLUdpConnection *)getConnection
{
    return [GLUdpConnection getConnectionForHostname:GLMapAttackHostname];
}

#pragma mark -

- (GLUdpConnection *)initWithHostname:(NSString *)hostname
{
    queueCounter = 0;
    
    // set our hostname in the singleton instance
    //
    self.hostname = hostname;
    
    // create the socket instance, stash in ivar
    //
    socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    return self;
}

// try to connect, logging error if necessary
//
- (BOOL)connect
{
    BOOL ret = YES;
    NSError *err = nil;
    if (![socket connectToHost:self.hostname onPort:GLMapAttackPort error:&err])
    {
        NSLog(@"connection error: %@", err);
        self.lastError = err;
        ret = NO;
    }
    return ret;
}

- (void)sendDictionary:(NSDictionary *)dictionary
{
    queueCounter++;
    NSData *packed = [dictionary messagePack];
    [socket sendData:packed withTimeout:GLMapAttackUdpSendDataTimeout tag:queueCounter];
}

#pragma mark -

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    queueCounter--;
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    queueCounter--;
}

@end
