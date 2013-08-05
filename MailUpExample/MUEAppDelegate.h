//
//  MUEAppDelegate.h
//  MailUpExample
//
//  Created by Sergei Inyushkin on 10.07.13.
//  Copyright (c) 2013 MailUp. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MailUpClient.h"

#define CLIENT_ID                   @"37b4046e-59c6-4a10-8afc-061918ef64b5"
#define CLIENT_SECRET               @"1a104f35-ce85-443a-b827-b90586beec7a"

#define MAIL_UP_LOGON               @"http://prenlb01.ss.mailup.it:9990/OAuth/LogOn";
#define MAIL_UP_AUTHORIZATION       @"http://prenlb01.ss.mailup.it:9990/OAuth/Authorization";
#define MAIL_UP_TOKEN               @"http://prenlb01.ss.mailup.it:9990/OAuth/Token";

#define MAIL_UP_CONSOLE_ENDPOINT    @"http://prenlb01.ss.mailup.it:9900/Rest/ConsoleService.svc";
#define MAIL_UP_STATS_ENDPOINT      @"http://prenlb01.ss.mailup.it:9900/Rest/MailStatisticsService.svc";

@interface MUEAppDelegate : NSObject <NSApplicationDelegate>
{
    IBOutlet NSTextField *txtLogin;
    IBOutlet NSTextField *txtPassword;
    IBOutlet NSTextField *txtAuthorizationResult;
    
    IBOutlet NSPopUpButton *lstVerb;
    IBOutlet NSPopUpButton *lstContentType;
    IBOutlet NSPopUpButton *lstEndpoint;
    IBOutlet NSTextField *txtPath;
    IBOutlet NSTextView *txtBody;
    IBOutlet NSTextView *txtCallResult;
    IBOutlet NSTextView *txtExamplesResult;
    
    MailUpClient *mailUp;
    
    int groupId;
    int emailId;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction)authorize:(id)sender;
- (IBAction)callMethod:(id)sender;
- (IBAction)callExample1:(id)sender;
- (IBAction)callExample2:(id)sender;
- (IBAction)callExample3:(id)sender;
- (IBAction)callExample4:(id)sender;
- (IBAction)callExample5:(id)sender;
- (IBAction)callExample6:(id)sender;
- (IBAction)callExample7:(id)sender;
- (IBAction)callExample8:(id)sender;

@end
