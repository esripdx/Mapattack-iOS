//
//  MAUdpConnection.m
//  Mapattack-iOS
//
//  Created by kenichi nakamura on 9/18/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import "MAUdpConnection.h"

static const int MAMapAttackUdpSendDataTimeout = -1;

@implementation MAUdpConnection {
    GCDAsyncUdpSocket *socket;
    long queueCounter;
    NSString *accessToken;
}

#pragma mark -

- (id)initWithDelegate:(id <MAUdpConnectionDelegate>)delegate {
    self = [super init];
    queueCounter = 0;
    
    self.delegate = delegate;
    
    DDLogVerbose(@"creating socket...");
    socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    DDLogVerbose(@"socket created: %@", socket);
    return self;
}

#pragma mark -

- (BOOL)connect {
    DDLogVerbose(@"connecting socket...");
    NSError *err = nil;
    accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:kMADefaultsAccessTokenKey];
    if (!accessToken) {
        DDLogError(@"Tried to connect without an access token.");
        return NO;
    }
    if (![socket connectToHost:kMapAttackHostname onPort:kMapAttackUdpPort error:&err]) {
        DDLogError(@"error: %@", err);
        return NO;
    }
    DDLogVerbose(@"connected");
    [self beginReceiving];
    return YES;
}

- (void)sendDictionary:(NSDictionary *)dictionary {
    if (![socket isConnected]) {
        if (![self connect]) {
            return;
        }
    }

    queueCounter++;
    NSError *jsonParsingError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&jsonParsingError];
    if (!jsonParsingError) {
        [socket sendData:jsonData withTimeout:MAMapAttackUdpSendDataTimeout tag:queueCounter];
    }
}

- (void)setLastError:(NSError *)lastError {
    DDLogError(@"error: %@", lastError);
    _lastError = lastError;
}

- (void)close {
    [socket close];
}

- (void)beginReceiving {
    DDLogVerbose(@"beginning the receiving...");
    NSError *err = nil;
    if (![socket beginReceiving:&err]) {
        DDLogCError(@"begin receiving failed!");
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
    DDLogError(@"did not connect!");
    if (error) {
        self.lastError = error;
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
                                               fromAddress:(NSData *)address
                                         withFilterContext:(id)filterContext {
    DDLogVerbose(@"received data!");
    NSError *jsonParsingError;
    id unpacked = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParsingError];
    if (jsonParsingError) {
        DDLogError(@"Error parsing json sent from server!");
        return;
    }

    DDLogVerbose(@"unpacked: %@", unpacked);
    
    if ([unpacked isKindOfClass:[NSDictionary class]] && [self.delegate respondsToSelector:@selector(udpConnection:didReceiveDictionary:)]) {
        [self.delegate udpConnection:self didReceiveDictionary:(NSDictionary *)unpacked];
    }
    
    if ([unpacked isKindOfClass:[NSArray class]] && [self.delegate respondsToSelector:@selector(udpConnection:didReceiveArray:)]) {
        [self.delegate udpConnection:self didReceiveArray:(NSArray *)unpacked];
    }
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error {
    DDLogVerbose(@"socket closed!");
    if (error) {
        self.lastError = error;
    }
}

@end