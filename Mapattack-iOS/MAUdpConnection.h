//
//  MAUdpConnection.h
//  Mapattack-iOS
//
//  Created by kenichi nakamura on 9/18/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

/*
 
 quick start example:
 
    MAUdpConnection *udp = [MAUdpConnection getConnectionForHostname:@"192.168.56.160" delegate:self];
    [udp connect];
    [udp beginReceiving];
    [udp sendDictionary:@{@"foo": @42, @"bar": @[@1,@2,@3], @"bat": @YES}];
 
 */

#import <Foundation/Foundation.h>
#import "GCDAsyncUdpSocket.h"

extern NSString *const MAMapAttackHostname;
extern const int MAMapAttackPort;

@class MAUdpConnection;

@protocol MAUdpConnectionDelegate <NSObject>
@optional
- (void)udpConnection:(MAUdpConnection *)udpConnection didReceiveDictionary:(NSDictionary *)dictionary;
- (void)udpConnection:(MAUdpConnection *)udpConnection didReceiveArray:(NSArray *)array;
@end

@interface MAUdpConnection : NSObject <GCDAsyncUdpSocketDelegate>

@property (strong, nonatomic) NSString *hostname;
@property (strong, nonatomic) NSError *lastError;
@property (strong, nonatomic) id <MAUdpConnectionDelegate> delegate;

+ (MAUdpConnection *)getConnectionForHostname:(NSString *)hostname;
+ (MAUdpConnection *)getConnectionForHostname:(NSString *)hostname delegate:(id <MAUdpConnectionDelegate>)delegate;
+ (MAUdpConnection *)getConnection;
+ (MAUdpConnection *)getConnectionWithDelegate:(id <MAUdpConnectionDelegate>)delegate;

- (BOOL)connect;
- (void)sendDictionary:(NSDictionary *)dictionary;
- (void)beginReceiving;

@end

