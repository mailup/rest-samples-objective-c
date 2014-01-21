//
//  MailUpClient.m
//  MailUpExample
//
//  Created by Sergei Inyushkin on 11.07.13.
//  Copyright (c) 2013 MailUp. All rights reserved.
//

#import "MailUpClient.h"

@implementation MailUpClient

@synthesize logonEndpoint, authorizationEndpoint, tokenEndpoint, consoleEndpoint, mailstatisticsEndpoint,
            clientId, clientSecret, callbackUri, accessToken, refreshToken;
            
-(id)init
{
    if (self == [super init])
    {
        self.logonEndpoint = @"https://services.mailup.com/Authorization/OAuth/LogOn";
        self.authorizationEndpoint = @"https://services.mailup.com/Authorization/OAuth/Authorization";
        self.tokenEndpoint = @"https://services.mailup.com/Authorization/OAuth/Token";
        self.consoleEndpoint = @"https://services.mailup.com/API/v1.1/Rest/ConsoleService.svc";
        self.mailstatisticsEndpoint = @"https://services.mailup.com/API/v1.1/Rest/MailStatisticsService.svc";
    }
    return self;
}

-(id)initWithClientId:(NSString *)inClientId clientSecret:(NSString *)inClientSecret
{
    if (self == [self init])
    {
        self.clientId = inClientId;
        self.clientSecret = inClientSecret;
    }
    return self;
}

-(NSString *)retreiveAccessTokenWithCode:(NSString *)code error:(NSError**)error
{
    NSString *url = self.tokenEndpoint;
    url = [url stringByAppendingFormat:@"?code=%@&grant_type=authorization_code", code];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"GET"];
    
    NSHTTPURLResponse *response = nil;
    NSError *err;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:&response
                                                             error:&err];
    if (err && [err code] != 0) {
        *error = err;
        return nil;
    }
    
    id object = [NSJSONSerialization
                 JSONObjectWithData:responseData
                 options:0
                 error:&err];
    if (err && [err code] != 0) {
        *error = err;
        return nil;
    }
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *root = object;
        self.accessToken = [root objectForKey:@"access_token"];
        self.refreshToken = [root objectForKey:@"refresh_token"];
        
        return self.accessToken;
    }
    
    return nil;
}

-(NSString *)retreiveAccessTokenWithLogin:(NSString *)login password:(NSString *)password error:(NSError**)error
{
    NSString *url = self.authorizationEndpoint;
    url = [url stringByAppendingFormat:@"?client_id=%@&client_secret=%@&response_type=code&username=%@&password=%@",
        self.clientId, self.clientSecret, login, password];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"GET"];
    
    NSHTTPURLResponse *response = nil;
    NSError *err;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:&response
                                                             error:&err];
    if (err && [err code] != 0) {
        *error = err;
        return nil;
    }
    
    id object = [NSJSONSerialization
                 JSONObjectWithData:responseData
                 options:0
                 error:&err];
    if (err && [err code] != 0) {
        *error = err;
        return nil;
    }
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *root = object;
        NSString *code = [root objectForKey:@"code"];
        
        return [self retreiveAccessTokenWithCode:code error:error];
    }
    
    return nil;
}

-(NSString *)refreshAccessTokenWithError:(NSError**)error
{
    NSString *url = self.tokenEndpoint;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSString *body = [NSString stringWithFormat:@"client_id=%@&client_secret=%@&refresh_token=%@&grant_type=refresh_token",
                      self.clientId, self.clientSecret, self.refreshToken];
    
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    [request setValue:[[NSNumber numberWithLong:body.length] stringValue] forHTTPHeaderField:@"Content-Length"];
    
    NSHTTPURLResponse *response = nil;
    NSError *err;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:&response
                                                             error:&err];
    if (err && [err code] != 0) {
        *error = err;
        return nil;
    }
    
    id object = [NSJSONSerialization
                 JSONObjectWithData:responseData
                 options:0
                 error:&err];
    if (err && [err code] != 0) {
        *error = err;
        return nil;
    }
    
    if([object isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *root = object;
        self.accessToken = [root objectForKey:@"access_token"];
        self.refreshToken = [root objectForKey:@"refresh_token"];
        
        return self.accessToken;
    }
    
    return nil;
}

-(NSString *)callMethodWithUrl:(NSString *)url verb:(NSString *)verb body:(NSString *)body
                   contentType:(MailUpContentType)contentType refresh:(BOOL)refresh error:(NSError**)error
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:verb];
    [request setValue:[self getContentTypeString:contentType] forHTTPHeaderField:@"Content-Type"];
    [request setValue:[self getContentTypeString:contentType] forHTTPHeaderField:@"Accept"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", self.accessToken] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"0" forHTTPHeaderField:@"Content-Length"];
    
    if (body != nil && [@"" isEqualToString:body] == NO) {
        [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
        [request setValue:[[NSNumber numberWithLong:body.length] stringValue] forHTTPHeaderField:@"Content-Length"];
    }
    
    NSHTTPURLResponse *response = nil;
    NSError *err;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:&response
                                                             error:&err];
    if (err && [err code] != 0) {
        *error = err;
        return nil;
    }
    
    if (response.statusCode == 401 && refresh) {
        [self refreshAccessTokenWithError:error];
        [self callMethodWithUrl:url verb:verb body:body contentType:contentType refresh:NO error:error];
    }
    
    return [[NSString alloc] initWithData:responseData encoding:NSASCIIStringEncoding];
}

-(NSString *)callMethodWithUrl:(NSString *)url verb:(NSString *)verb body:(NSString *)body
                   contentType:(MailUpContentType)contentType error:(NSError**)error
{
    return [self callMethodWithUrl:url verb:verb body:body contentType:contentType refresh:YES error:error];
}

-(NSString *)getContentTypeString:(MailUpContentType)contentType
{
    if (contentType == kContentTypeJson) return @"application/json";
    else return @"application/xml";
}

@end
