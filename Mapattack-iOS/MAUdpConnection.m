//
//  MAUdpConnection.m
//  Mapattack-iOS
//
//  Created by kenichi nakamura on 9/18/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import "MAUdpConnection.h"
#import "MessagePack.h"

NSString *const GLMapAttackHostname = @"mapattack.org";
int const GLMapAttackPort = 5309;

static const int GLMapAttackUdpSendDataTimeout = -1;

static MAUdpConnection *instance;

@implementation MAUdpConnection {
    GCDAsyncUdpSocket *socket;
    long queueCounter;
}

#pragma mark -

// get the singleton instance with a specified hostname to connect to
//
+ (MAUdpConnection *)getConnectionForHostname:(NSString *)hostname {
    if (!instance) {
        instance = [[MAUdpConnection alloc] initWithHostname:hostname];
    }
    return instance;
}

// get the singleton instance with the default hostname to connect to
//
+ (MAUdpConnection *)getConnection {
    return [MAUdpConnection getConnectionForHostname:GLMapAttackHostname];
}

#pragma mark -

- (MAUdpConnection *)initWithHostname:(NSString *)hostname {
    queueCounter = 0;
    
    // set our hostname in the singleton instance
    //
    self.hostname = hostname;
    
    // create the socket instance, stash in ivar
    //
    socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    return self;
}

#pragma mark -

- (BOOL)connect {
    return [socket connectToHost:self.hostname onPort:GLMapAttackPort error:nil];
}

- (void)sendDictionary:(NSDictionary *)dictionary {
    if (![socket isConnected]) {
        if (![self connect]) {
            return;
        }
    }
    queueCounter++;
    NSData *packed = [dictionary messagePack];
    [socket sendData:packed withTimeout:GLMapAttackUdpSendDataTimeout tag:queueCounter];
}

- (void)setLastError:(NSError *)lastError {
    NSLog(@"error: %@", lastError);
    _lastError = lastError;
}

- (void)close {
    [socket close];
}

#pragma mark - GCDAsyncUdpSocketDelegate

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    queueCounter--;
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error {
    queueCounter--;
    self.lastError = error;
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError *)error {
    NSLog(@"did not connect!");
    if (error) {
        self.lastError = error;
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext {
    
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error {
    NSLog(@"socket closed!");
    if (error) {
        self.lastError = error;
    }
}

@end