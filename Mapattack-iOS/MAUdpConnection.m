//
//  MAUdpConnection.m
//  Mapattack-iOS
//
//  Created by kenichi nakamura on 9/18/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import "MAUdpConnection.h"
#import "MessagePack.h"

NSString *const MAMapAttackHostname = @"mapattack.org";
int const MAMapAttackPort = 5309;

static const int MAMapAttackUdpSendDataTimeout = -1;

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

+ (MAUdpConnection *)getConnectionForHostname:(NSString *)hostname delegate:(id <MAUdpConnectionDelegate>)delegate {
    MAUdpConnection *instance = [MAUdpConnection getConnectionForHostname:hostname];
    instance.delegate = delegate;
    return instance;
}

// get the singleton instance with the default hostname to connect to
//
+ (MAUdpConnection *)getConnection {
    return [MAUdpConnection getConnectionForHostname:MAMapAttackHostname];
}

+ (MAUdpConnection *)getConnectionWithDelegate:(id <MAUdpConnectionDelegate>)delegate {
    MAUdpConnection *instance = [MAUdpConnection getConnectionForHostname:MAMapAttackHostname];
    instance.delegate = delegate;
    return instance;
}

#pragma mark -

- (MAUdpConnection *)initWithHostname:(NSString *)hostname {
    queueCounter = 0;
    
    // set our hostname in the singleton instance
    //
    self.hostname = hostname;
    
    // create the socket instance, stash in ivar
    //
    NSLog(@"creating socket...");
    socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSLog(@"socket created: %@", socket);
    return self;
}

#pragma mark -

- (BOOL)connect {
    NSLog(@"connecting socket...");
    NSError *err = nil;
    if (![socket connectToHost:self.hostname onPort:MAMapAttackPort error:&err]) {
        NSLog(@"error: %@", err);
        return NO;
    }
    return YES;
}

- (void)sendDictionary:(NSDictionary *)dictionary {
    if (![socket isConnected]) {
        if (![self connect]) {
            return;
        }
    }
    queueCounter++;
    NSData *packed = [dictionary messagePack];
    [socket sendData:packed withTimeout:MAMapAttackUdpSendDataTimeout tag:queueCounter];
}

- (void)setLastError:(NSError *)lastError {
    NSLog(@"error: %@", lastError);
    _lastError = lastError;
}

- (void)close {
    [socket close];
}

- (void)beginReceiving {
    NSLog(@"beginning the receiving...");
    NSError *err = nil;
    if (![socket beginReceiving:&err]) {
        NSLog(@"begin receiving failed!");
        self.lastError = err;
    }
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
    NSLog(@"received data!");
    id unpacked = [data messagePackParse];
    NSLog(@"unpacked: %@", unpacked);
    
    if ([unpacked isKindOfClass:[NSDictionary class]] &&
        [self.delegate respondsToSelector:@selector(udpConnection:didReceiveDictionary:)]) {
        
        [self.delegate udpConnection:self didReceiveDictionary:(NSDictionary *)unpacked];
    }
    
    if ([unpacked isKindOfClass:[NSArray class]] &&
        [self.delegate respondsToSelector:@selector(udpConnection:didReceiveArray:)]) {
       
        [self.delegate udpConnection:self didReceiveArray:(NSArray *)unpacked];
    }
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error {
    NSLog(@"socket closed!");
    if (error) {
        self.lastError = error;
    }
}

@end