//
//  MAApiConnection.m
//  Mapattack-iOS
//
//  Created by Kenichi Nakamura on 9/30/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MAApiConnection.h"
#import <AFNetworking/AFNetworking.h>

@interface MAApiRequest : NSObject
@property (weak, atomic) NSString *path;
@property (weak, atomic) NSDictionary *params;
@property (copy, nonatomic) MAApiSuccessHandler success;
@property (copy, nonatomic) MAApiFailureHandler failure;
@end

@implementation MAApiRequest
@end

@implementation MAApiConnection {
    AFHTTPSessionManager *_tcpConnection;
    NSMutableDictionary *_successHandlers;
    NSMutableDictionary *_failureHandlers;
}

- (MAApiConnection *)init {
    self = [super init];
    if (self) {
        _successHandlers = [NSMutableDictionary new];
        _failureHandlers = [NSMutableDictionary new];
        _tcpConnection = [[AFHTTPSessionManager manager] initWithBaseURL:[NSURL URLWithString:kMapAttackURL]];
        _tcpConnection.requestSerializer = [AFHTTPRequestSerializer serializer];
        _tcpConnection.responseSerializer = [AFJSONResponseSerializer serializer];
    }
    return self;
}

- (NSString *)accessToken {
    if (!_accessToken) {
        _accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:kMADefaultsAccessTokenKey];
    }
    return _accessToken;
}

#pragma mark -

- (void)postToPath:(NSString *)path
            params:(NSDictionary *)params {
    
    MAApiSuccessHandler success = _successHandlers[path];
    if (success) {
        
        MAApiFailureHandler failure = _failureHandlers[path];
        
        NSMutableDictionary *paramsWithToken = [NSMutableDictionary dictionaryWithDictionary:params];
        [paramsWithToken setValue:self.accessToken forKey:kMAApiAccessTokenKey];
        
        [_tcpConnection POST:path
                  parameters:paramsWithToken
                     success:^(NSURLSessionTask *task, NSDictionary *responseObject) {
                         NSDictionary *error = responseObject[kMAApiErrorKey];
                         if (error && failure) {
                             failure([NSError errorWithDomain:kMADefaultsDomain
                                                         code:(int)error[kMAApiErrorCodeKey]
                                                     userInfo:error]);
                         } else {
                             success(responseObject);
                         }
                     }
                     failure:^(NSURLSessionTask *task, NSError *error) {
                         DDLogError(@"api request failure for path '%@': %@", path, error);
                         if (failure) {
                             failure(error);
                         }
                     }];
        
    } else {
        DDLogError(@"success handler not found for path '%@'", path);
    }
    
}

- (void)postToPath:(NSString *)path
            params:(NSDictionary *)params
           success:(MAApiSuccessHandler)success {
    [self registerSuccessHandler:success forPath:path];
    [self postToPath:path params:params];
}

- (void)postToPath:(NSString *)path
            params:(NSDictionary *)params
           success:(MAApiSuccessHandler)success
           failure:(MAApiFailureHandler)failure {
    [self registerSuccessHandler:success forPath:path];
    [self registerFailureHandler:failure forPath:path];
    [self postToPath:path params:params];
}

#pragma mark -

- (void)registerSuccessHandler:(MAApiSuccessHandler)handler
                       forPath:(NSString *)path {
    [_successHandlers setValue:handler forKey:path];
}

- (void)registerFailureHandler:(MAApiFailureHandler)handler
                       forPath:(NSString *)path {
    [_failureHandlers setValue:handler forKey:path];
}

@end
