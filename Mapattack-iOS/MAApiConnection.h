//
//  MAApiConnection.h
//  Mapattack-iOS
//
//  Created by Kenichi Nakamura on 9/30/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^MAApiSuccessHandler)(NSDictionary *response);
typedef void (^MAApiFailureHandler)(NSError *error);

@interface MAApiConnection : NSObject

@property (strong, nonatomic) NSString *accessToken;

/* posts the params to the path and runs the registered success handler
 */
- (void)postToPath:(NSString *)path
            params:(NSDictionary *)params;

/* registers the handler and posts the params to the path
 */
- (void)postToPath:(NSString *)path
            params:(NSDictionary *)params
           success:(MAApiSuccessHandler)success;

/* registers the handlers and posts the params to the path
 */
- (void)postToPath:(NSString *)path
            params:(NSDictionary *)params
           success:(MAApiSuccessHandler)success
           failure:(MAApiFailureHandler)failure;

/* registers the success handler for the path
 */
- (void)registerSuccessHandler:(MAApiSuccessHandler)handler
                       forPath:(NSString *)path;

/* registers the failure handler for the path
 */
- (void)registerFailureHandler:(MAApiFailureHandler)handler
                       forPath:(NSString *)path;

@end
