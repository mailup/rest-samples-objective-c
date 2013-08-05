//
//  MailUpClient.h
//  MailUpExample
//
//  Created by Sergei Inyushkin on 11.07.13.
//  Copyright (c) 2013 MailUp. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum MailUpContentType : NSUInteger {
    kContentTypeJson,
    kContentTypeXml
} MailUpContentType;

@interface MailUpClient : NSObject
{
    NSString *logonEndpoint;
    NSString *authorizationEndpoint;
    NSString *tokenEndpoint;
    NSString *consoleEndpoint;
    NSString *mailstatisticsEndpoint;
    
    NSString *clientId;
    NSString *clientSecret;
    NSString *callbackUri;
    NSString *accessToken;
    NSString *refreshToken;
}

@property(retain) NSString *logonEndpoint;
@property(retain) NSString *authorizationEndpoint;
@property(retain) NSString *tokenEndpoint;
@property(retain) NSString *consoleEndpoint;
@property(retain) NSString *mailstatisticsEndpoint;

@property(retain) NSString *clientId;
@property(retain) NSString *clientSecret;
@property(retain) NSString *callbackUri;
@property(retain) NSString *accessToken;
@property(retain) NSString *refreshToken;

-(id)init;
-(id)initWithClientId:(NSString *)inClientId clientSecret:(NSString *)inClientSecret;
-(NSString *)retreiveAccessTokenWithCode:(NSString *)code error:(NSError**)error;
-(NSString *)retreiveAccessTokenWithLogin:(NSString *)login password:(NSString *)password error:(NSError**)error;
-(NSString *)refreshAccessTokenWithError:(NSError**)error;
-(NSString *)callMethodWithUrl:(NSString *)url verb:(NSString *)verb body:(NSString *)body
                   contentType:(MailUpContentType)contentType refresh:(BOOL)refresh error:(NSError**)error;
-(NSString *)callMethodWithUrl:(NSString *)url verb:(NSString *)verb body:(NSString *)body
                   contentType:(MailUpContentType)contentType error:(NSError**)error;
-(NSString *)getContentTypeString:(MailUpContentType)contentType;

@end
