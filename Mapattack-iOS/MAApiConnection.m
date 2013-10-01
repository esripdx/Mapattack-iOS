//
//  MAApiConnection.m
//  Mapattack-iOS
//
//  Created by Kenichi Nakamura on 9/30/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MAApiConnection.h"
#import <AFNetworking/AFNetworking.h>

@implementation MAApiConnection {
    AFHTTPSessionManager *_tcpConnection;
    NSMutableDictionary *_successHandlers;
    NSMutableDictionary *_errorHandlers;
}

- (MAApiConnection *)init {
    self = [super init];
    if (self) {
        _successHandlers = [NSMutableDictionary new];
        _errorHandlers = [NSMutableDictionary new];
        _tcpConnection = [[AFHTTPSessionManager manager] initWithBaseURL:[NSURL URLWithString:MAPATTACK_URL]];
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
    
    MAApiSuccessHandler successHandler = _successHandlers[path];
    if (successHandler) {
        
        MAApiErrorHandler errorHandler = _errorHandlers[path];
        
        NSMutableDictionary *paramsWithToken = [NSMutableDictionary dictionaryWithDictionary:params];
        [paramsWithToken setValue:self.accessToken forKey:kMAApiAccessTokenKey];
        
        [_tcpConnection POST:path
                  parameters:paramsWithToken
                     success:^(NSURLSessionTask *task, NSDictionary *responseObject) {
                         NSDictionary *errorResponse = responseObject[kMAApiErrorKey];
                         if (errorResponse) {
                             if (errorHandler) {
                                 errorHandler([NSError errorWithDomain:kMADefaultsDomain
                                                                  code:(int)errorResponse[kMAApiErrorCodeKey]
                                                              userInfo:errorResponse]);
                             } else {
                                 DDLogError(@"api error for path '%@': %@", path, errorResponse);
                                 DDLogError(@"--- params: %@", paramsWithToken);
                             }
                         } else {
                             successHandler(responseObject);
                         }
                     }
                     failure:^(NSURLSessionTask *task, NSError *error) {
                         DDLogError(@"api request failure for path '%@': %@", path, error);
                         DDLogError(@"--- params: %@", paramsWithToken);
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
           error:(MAApiErrorHandler)error {
    [self registerSuccessHandler:success forPath:path];
    [self registerErrorHandler:error forPath:path];
    [self postToPath:path params:params];
}

#pragma mark -

- (void)registerSuccessHandler:(MAApiSuccessHandler)handler
                       forPath:(NSString *)path {
    [_successHandlers setValue:handler forKey:path];
}

- (void)registerErrorHandler:(MAApiErrorHandler)handler
                       forPath:(NSString *)path {
    [_errorHandlers setValue:handler forKey:path];
}

@end
