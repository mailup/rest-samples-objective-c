//
//  MUEAppDelegate.m
//  MailUpExample
//
//  Created by Sergei Inyushkin on 10.07.13.
//  Copyright (c) 2013 MailUp. All rights reserved.
//

#import "MUEAppDelegate.h"
#import "NSData+Base64.h"


@implementation MUEAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [txtCallResult setBackgroundColor:[NSColor colorWithSRGBRed:0 green:0 blue:0 alpha:0]];
    [txtExamplesResult setBackgroundColor:[NSColor colorWithSRGBRed:0 green:0 blue:0 alpha:0]];

    mailUp = [[MailUpClient alloc] initWithClientId:CLIENT_ID clientSecret:CLIENT_SECRET];
    
}

- (IBAction)authorize:(id)sender
{
    NSError *error;
    NSString *token = [mailUp retreiveAccessTokenWithLogin:txtLogin.stringValue password:txtPassword.stringValue error:&error];
    
    if (token) [txtAuthorizationResult setStringValue:[NSString stringWithFormat:@"Authorized. Token: %@", [[token stringByPaddingToLength:30 withString:@"" startingAtIndex:0] stringByAppendingString:@"..."]]];
    else [txtAuthorizationResult setStringValue:@"Unauthorized"];
}

- (IBAction)callMethod:(id)sender
{
    NSError *error;
    NSString *url = [@"Console" isEqualToString:lstEndpoint.titleOfSelectedItem] ? mailUp.consoleEndpoint : mailUp.mailstatisticsEndpoint;
    url = [url stringByAppendingString:[txtPath stringValue]];
    NSString *result = [mailUp callMethodWithUrl:url
                                            verb:lstVerb.titleOfSelectedItem
                                            body:txtBody.string
                                     contentType:[@"JSON" isEqualToString:lstContentType.titleOfSelectedItem] ? kContentTypeJson : kContentTypeXml
                                           error:&error];
    if (result != nil) [txtCallResult setString:result];
}

// EXAMPLE 1 - IMPORT RECIPIENTS INTO NEW GROUP
// List ID = 1 is used in all example calls
- (IBAction)callExample1:(id)sender
{
    NSError *error;
    NSString *output = @"";
    
    // Given a default list id (use idList = 1), request for user visible groups
    NSString *url = [NSString stringWithFormat:@"%@%@", mailUp.consoleEndpoint, @"/Console/List/1/Groups"];
    NSString *result = [mailUp callMethodWithUrl:url verb:@"GET" body:nil contentType:kContentTypeJson error:&error];    
    id object = [NSJSONSerialization JSONObjectWithData:[result dataUsingEncoding:NSUTF8StringEncoding]
                                                options:0
                                                  error:&error];
    groupId = -1;
    if (error && [error code] != 0) {
        output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
    } else {
        output = [output stringByAppendingFormat:@"Given a default list id (use idList = 1), request for user visible groups\nGET %@ - OK\n", url];
    }
    
    if ([object isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *root = object;
        NSArray *groups = (NSArray *)[root objectForKey:@"Items"];
        for (NSDictionary *group in groups)
        {
            NSString *name = [group objectForKey:@"Name"];
            if ([@"test import" isEqualToString:name]) groupId = [(NSNumber *)[group objectForKey:@"idGroup"] intValue];
        }
    }
    
    // If the list does not contain a group named “test import”, create it
    if (groupId == -1)
    {
        groupId = 100;
        url = [NSString stringWithFormat:@"%@%@", mailUp.consoleEndpoint, @"/Console/List/1/Group"];
        NSString *groupRequest = @"{\"Deletable\":true,\"Name\":\"test import\",\"Notes\":\"test import\"}";
        result = [mailUp callMethodWithUrl:url verb:@"POST" body:groupRequest contentType:kContentTypeJson error:&error];
        
        object = [NSJSONSerialization JSONObjectWithData:[result dataUsingEncoding:NSUTF8StringEncoding]
                                                 options:0
                                                   error:&error];
        if (error && [error code] != 0) {
            output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
        } else {
            output = [output stringByAppendingFormat:@"If the list does not contain a group named “test import”, create it\nPOST %@ - OK\n", url];
        }
        
        if ([object isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *root = object;
            NSArray *groups = (NSArray *)[root objectForKey:@"Items"];
            for (NSDictionary *group in groups)
            {
                NSString *name = [group objectForKey:@"Name"];
                if ([@"test import" isEqualToString:name]) groupId = [(NSNumber *)[group objectForKey:@"idGroup"] intValue];
            }
        }
    }
    
    // Request for dynamic fields to map recipient name and surname
    url = [NSString stringWithFormat:@"%@%@", mailUp.consoleEndpoint, @"/Console/Recipient/DynamicFields"];
    result = [mailUp callMethodWithUrl:url verb:@"GET" body:nil contentType:kContentTypeJson error:&error];
    if (error && [error code] != 0) {
        output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
    } else {
        output = [output stringByAppendingFormat:@"Request for dynamic fields to map recipient name and surname\nGET %@ - OK\n", url];
    }
    
    // Import recipients to group
    url = [NSString stringWithFormat:@"%@%@%d%@", mailUp.consoleEndpoint, @"/Console/Group/", groupId, @"/Recipients"];
    NSString *recipientRequest = @"[{\"Email\":\"test@test.test\",\"Fields\":[{\"Description\":\"String description\",\"Id\":1,\"Value\":\"String value\"}],\"MobileNumber\":\"\",\"MobilePrefix\":\"\",\"Name\":\"John Smith\"}]";
    result = [mailUp callMethodWithUrl:url verb:@"POST" body:recipientRequest contentType:kContentTypeJson error:&error];
    if (error && [error code] != 0) {
        output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
    } else {
        output = [output stringByAppendingFormat:@"Import recipients to group - OK\n"];
    }
    int importId = [result intValue];
    
    // Check the import result
    url = [NSString stringWithFormat:@"%@%@%d", mailUp.consoleEndpoint, @"/Console/Import/", importId];
    result = [mailUp callMethodWithUrl:url verb:@"GET" body:nil contentType:kContentTypeJson error:&error];
    if (error && [error code] != 0) {
        output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
    } else {
        output = [output stringByAppendingFormat:@"Check the import result - OK\n"];
    }
    
    output = [output stringByAppendingFormat:@"Example methods completed successfully\n"];
    
    [txtExamplesResult setString:output];
}

// EXAMPLE 2 - UNSUBSCRIBE A RECIPIENT FROM A GROUP
- (IBAction)callExample2:(id)sender
{
    NSError *error;
    NSString *output = @"";
    
    // Request for recipient in a group
    NSString *url = [NSString stringWithFormat:@"%@%@%d%@", mailUp.consoleEndpoint, @"/Console/Group/", groupId, @"/Recipients"];
    NSString *result = [mailUp callMethodWithUrl:url verb:@"GET" body:nil contentType:kContentTypeJson error:&error];
    id object = [NSJSONSerialization JSONObjectWithData:[result dataUsingEncoding:NSUTF8StringEncoding]
                                                options:0
                                                  error:&error];
    if (error && [error code] != 0) {
        output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
    } else {
        output = [output stringByAppendingFormat:@"Request for recipient in a group\nGET %@ - OK\n", url];
    }
    
    if ([object isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *root = object;
        NSArray *recipients = (NSArray *)[root objectForKey:@"Items"];
        if ([recipients count] > 0) {
            NSDictionary *recipient = (NSDictionary *)[recipients objectAtIndex:0];
            int recipientId = [(NSNumber *)[recipient objectForKey:@"idRecipient"] intValue];
            
            // Pick up a recipient and unsubscribe it
            url = [NSString stringWithFormat:@"%@%@%d%@%d", mailUp.consoleEndpoint, @"/Console/Group/", groupId, @"/Unsubscribe/", recipientId];
            [mailUp callMethodWithUrl:url verb:@"DELETE" body:nil contentType:kContentTypeJson error:&error];
            if (error && [error code] != 0) {
                output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
            } else {
                output = [output stringByAppendingFormat:@"Pick up a recipient and unsubscribe it\nGET %@ - OK\n", url];
            }
        }
    }
    
    output = [output stringByAppendingFormat:@"Example methods completed successfully\n"];
    
    [txtExamplesResult setString:output];
}

// EXAMPLE 3 - UPDATE A RECIPIENT DETAIL
- (IBAction)callExample3:(id)sender
{
    NSError *error;
    NSString *output = @"";
    
    // Request for existing subscribed recipients
    NSString *url = [NSString stringWithFormat:@"%@%@", mailUp.consoleEndpoint, @"/Console/List/1/Recipients/Subscribed"];
    NSString *result = [mailUp callMethodWithUrl:url verb:@"GET" body:nil contentType:kContentTypeJson error:&error];
    id object = [NSJSONSerialization JSONObjectWithData:[result dataUsingEncoding:NSUTF8StringEncoding]
                                                options:0
                                                  error:&error];
    if (error && [error code] != 0) {
        output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
    } else {
        output = [output stringByAppendingFormat:@"Request for existing subscribed recipients\nGET %@ - OK\n", url];
    }
    
    if ([object isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *root = object;
        NSArray *recipients = (NSArray *)[root objectForKey:@"Items"];
        if ([recipients count] > 0) {
            NSMutableDictionary *recipient = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)[recipients objectAtIndex:0]];
            NSArray *fields = (NSArray *)[recipient objectForKey:@"Fields"];
            
            // Modify a recipient from the list
            if ([fields count] == 0)
            {
                NSMutableArray *arr = [[NSMutableArray alloc] init];
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                [dict setObject:[NSNumber numberWithInt:1] forKey:@"Id"];
                [dict setObject:@"Updated value" forKey:@"Value"];
                [dict setObject:@"" forKey:@"Description"];
                [arr addObject:dict];
                [recipient setObject:arr forKey:@"Fields"];
            }
            else
            {
                NSMutableArray *arr = [[NSMutableArray alloc] initWithArray:fields];
                NSDictionary *dictOriginal = (NSDictionary *)[arr objectAtIndex:0];
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:dictOriginal];
                [dict setObject:[NSNumber numberWithInt:1] forKey:@"Id"];
                [dict setObject:@"Updated value" forKey:@"Value"];
                [dict setObject:@"" forKey:@"Description"];
                [arr setObject:dict atIndexedSubscript:0];
                [recipient setObject:arr forKey:@"Fields"];
            }
            
            output = [output stringByAppendingFormat:@"Modify a recipient from the list - OK\n"];
            
            // Update the modified recipient
            url = [NSString stringWithFormat:@"%@%@", mailUp.consoleEndpoint, @"/Console/Recipient/Detail"];
            NSString *recipientRequest = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:recipient options:0 error:&error]
                                                               encoding:NSUTF8StringEncoding];
            [mailUp callMethodWithUrl:url verb:@"PUT" body:recipientRequest contentType:kContentTypeJson error:&error];
            if (error && [error code] != 0) {
                output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
            } else {
                output = [output stringByAppendingFormat:@"Update the modified recipient\nPUT %@ - OK\n", url];
            }
        }
    }
    
    output = [output stringByAppendingFormat:@"Example methods completed successfully\n"];
    
    [txtExamplesResult setString:output];
}

// EXAMPLE 4 - CREATE A MESSAGE FROM TEMPLATE
- (IBAction)callExample4:(id)sender
{
    NSError *error;
    NSString *output = @"";
    
    // Get the available template list
    NSString *url = [NSString stringWithFormat:@"%@%@", mailUp.consoleEndpoint, @"/Console/List/1/Templates"];
    NSString *result = [mailUp callMethodWithUrl:url verb:@"GET" body:nil contentType:kContentTypeJson error:&error];
    id object = [NSJSONSerialization JSONObjectWithData:[result dataUsingEncoding:NSUTF8StringEncoding]
                                                options:0
                                                  error:&error];
    if (error && [error code] != 0) {
        output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
    } else {
        output = [output stringByAppendingFormat:@"Get the available template list\nGET %@ - OK\n", url];
    }
    
    int templateId = -1;
    if ([object isKindOfClass:[NSArray class]])
    {
        NSArray *templates = (NSArray *)object;
        NSDictionary *template = (NSDictionary *)[templates objectAtIndex:0];
        templateId = [(NSNumber *)[template objectForKey:@"Id"] intValue];
    }
    
    // Create the new message
    url = [NSString stringWithFormat:@"%@%@%d", mailUp.consoleEndpoint, @"/Console/List/1/Email/Template/", templateId];
    result = [mailUp callMethodWithUrl:url verb:@"POST" body:nil contentType:kContentTypeJson error:&error];
    object = [NSJSONSerialization JSONObjectWithData:[result dataUsingEncoding:NSUTF8StringEncoding]
                                             options:0
                                               error:&error];
    if (error && [error code] != 0) {
        output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
    } else {
        output = [output stringByAppendingFormat:@"Create the new message\nPOST %@ - OK\n", url];
    }
    
    if ([object isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *root = object;
        NSArray *emails = (NSArray *)[root objectForKey:@"Items"];
        NSDictionary *email = (NSDictionary *)[emails objectAtIndex:0];
        emailId = [(NSNumber *)[email objectForKey:@"idMessage"] intValue];
    }
    
    // Request for messages list
    url = [NSString stringWithFormat:@"%@%@", mailUp.consoleEndpoint, @"/Console/List/1/Emails"];
    result = [mailUp callMethodWithUrl:url verb:@"GET" body:nil contentType:kContentTypeJson error:&error];
    if (error && [error code] != 0) {
        output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
    } else {
        output = [output stringByAppendingFormat:@"Request for messages list\nGET %@ - OK\n", url];
    }
    
    output = [output stringByAppendingFormat:@"Example methods completed successfully\n"];
    
    [txtExamplesResult setString:output];
}

// EXAMPLE 5 - CREATE A MESSAGE WITH IMAGES AND ATTACHMENTS
- (IBAction)callExample5:(id)sender
{
    NSError *error;
    NSString *output = @"";
    
    // Image bytes can be obtained from file, database or any other source
    NSData *imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: @"http://images.apple.com/home/images/ios_title_small.png"]];
    NSString *imageStr = [imageData base64EncodedString];
    
    // Upload an image
    NSString *url = [NSString stringWithFormat:@"%@%@", mailUp.consoleEndpoint, @"/Console/List/1/Images"];
    NSString *imageRequest = [NSString stringWithFormat:@"{\"Base64Data\":\"%@\",\"Name\":\"Avatar\"}", imageStr];
    NSString *result = [mailUp callMethodWithUrl:url verb:@"POST" body:imageRequest contentType:kContentTypeJson error:&error];
    if (error && [error code] != 0) {
        output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
    } else {
        output = [output stringByAppendingFormat:@"Upload an image\nPOST %@ - OK\n", url];
    }

    // Get the images available
    url = [NSString stringWithFormat:@"%@%@", mailUp.consoleEndpoint, @"/Console/Images"];
    result = [mailUp callMethodWithUrl:url verb:@"GET" body:nil contentType:kContentTypeJson error:&error];
    id object = [NSJSONSerialization JSONObjectWithData:[result dataUsingEncoding:NSUTF8StringEncoding]
                                                options:0
                                                  error:&error];
    if (error && [error code] != 0) {
        output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
    } else {
        output = [output stringByAppendingFormat:@"Get the images available\nGET %@ - OK\n", url];
    }
    
    NSString *imgSrc = @"";
    if ([object isKindOfClass:[NSArray class]])
    {
        NSArray *images = (NSArray *)object;
        if ([images count] > 0) imgSrc = (NSString *)[images objectAtIndex:0];
    }
    
    // Create and save "hello" message
    NSString *message = [NSString stringWithFormat:@"<html><body><p>Hello</p><img src=\"%@\" /></body></html>", imgSrc];
    url = [NSString stringWithFormat:@"%@%@", mailUp.consoleEndpoint, @"/Console/List/1/Email"];
    
    NSMutableDictionary *email = [[NSMutableDictionary alloc] init];
    [email setObject:@"Test Message Objective-C" forKey:@"Subject"];
    [email setObject:[NSNumber numberWithInt:1] forKey:@"idList"];
    [email setObject:message forKey:@"Content"];
    [email setObject:[NSNumber numberWithBool:YES] forKey:@"Embed"];
    [email setObject:[NSNumber numberWithBool:YES] forKey:@"IsConfirmation"];
    [email setObject:[[NSArray alloc] init] forKey:@"Fields"];
    [email setObject:@"Some notes" forKey:@"Notes"];
    [email setObject:[[NSArray alloc] init] forKey:@"Tags"];
    NSMutableDictionary *trackingInfo = [[NSMutableDictionary alloc] init];
    [trackingInfo setObject:@"" forKey:@"CustomParams"];
    [trackingInfo setObject:[NSNumber numberWithBool:YES] forKey:@"Enabled"];
    [trackingInfo setObject:[NSArray arrayWithObjects:@"http", nil] forKey:@"Protocols"];
    [email setObject:trackingInfo forKey:@"TrackingInfo"];
    
    NSString *emailRequest = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:email options:0 error:&error]
                                                       encoding:NSUTF8StringEncoding];
    result = [mailUp callMethodWithUrl:url verb:@"POST" body:emailRequest contentType:kContentTypeJson error:&error];
    object = [NSJSONSerialization JSONObjectWithData:[result dataUsingEncoding:NSUTF8StringEncoding]
                                                options:0
                                                  error:&error];
    if (error && [error code] != 0) {
        output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
    } else {
        output = [output stringByAppendingFormat:@"Create and save \"hello\" message\nPOST %@ - OK\n", url];
    }
    
    if ([object isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *root = object;
        NSArray *emails = (NSArray *)[root objectForKey:@"Items"];
        NSDictionary *email = (NSDictionary *)[emails objectAtIndex:0];
        emailId = [(NSNumber *)[email objectForKey:@"idMessage"] intValue];
    }
    
    // Add an attachment
    url = [NSString stringWithFormat:@"%@%@%d%@", mailUp.consoleEndpoint, @"/Console/List/1/Email/", emailId, @"/Attachment/1"];
    NSString *attachment = @"QmFzZSA2NCBTdHJlYW0="; // Base64 String
    NSString *attachmentRequest = [NSString stringWithFormat:@"{\"Base64Data\":\"%@\",\"Name\":\"TestFile.txt\",\"Slot\":1,\"idList\":1,\"idMessage\":%d}", attachment, emailId];
    result = [mailUp callMethodWithUrl:url verb:@"POST" body:attachmentRequest contentType:kContentTypeJson error:&error];
    if (error && [error code] != 0) {
        output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
    } else {
        output = [output stringByAppendingFormat:@"Add an attachment\nPOST %@ - OK\n", url];
    }
    
    // Retreive message details
    url = [NSString stringWithFormat:@"%@%@%d", mailUp.consoleEndpoint, @"/Console/List/1/Email/", emailId];
    result = [mailUp callMethodWithUrl:url verb:@"GET" body:nil contentType:kContentTypeJson error:&error];
    if (error && [error code] != 0) {
        output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
    } else {
        output = [output stringByAppendingFormat:@"Retreive message details\nGET %@ - OK\n", url];
    }
    
    output = [output stringByAppendingFormat:@"Example methods completed successfully\n"];
    
    [txtExamplesResult setString:output];
}

// EXAMPLE 6 - TAG A MESSAGE
- (IBAction)callExample6:(id)sender
{
    NSError *error;
    NSString *output = @"";
    
    // Create a new tag
    NSString *url = [NSString stringWithFormat:@"%@%@", mailUp.consoleEndpoint, @"/Console/List/1/Tag"];
    NSString *result = [mailUp callMethodWithUrl:url verb:@"POST" body:@"\"test tag\"" contentType:kContentTypeJson error:&error];
    id object = [NSJSONSerialization JSONObjectWithData:[result dataUsingEncoding:NSUTF8StringEncoding]
                                                options:0
                                                  error:&error];
    if (error && [error code] != 0) {
        output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
    } else {
        output = [output stringByAppendingFormat:@"Create a new tag\nPOST %@ - OK\n", url];
    }
    
    int tagId = -1;
    if ([object isKindOfClass:[NSArray class]])
    {
        NSArray *tags = (NSArray *)object;
        NSDictionary *tag = (NSDictionary *)[tags objectAtIndex:0];
        tagId = [(NSNumber *)[tag objectForKey:@"Id"] intValue];
    }
    
    // Pick up a message and retrieve detailed informations
    url = [NSString stringWithFormat:@"%@%@%d", mailUp.consoleEndpoint, @"/Console/List/1/Email/", emailId];
    result = [mailUp callMethodWithUrl:url verb:@"GET" body:nil contentType:kContentTypeJson error:&error];
    object = [NSJSONSerialization JSONObjectWithData:[result dataUsingEncoding:NSUTF8StringEncoding]
                                             options:0
                                               error:&error];
    if (error && [error code] != 0) {
        output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
    } else {
        output = [output stringByAppendingFormat:@"Pick up a message and retrieve detailed informations\nGET %@ - OK\n", url];
    }
    
    // Add the tag to the message details and save
    if ([object isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *root = object;
        NSArray *tags = (NSArray *)[root objectForKey:@"Tags"];
        NSMutableDictionary *email = [[NSMutableDictionary alloc] initWithDictionary:root];
        NSMutableArray *arr = [[NSMutableArray alloc] initWithArray:tags];
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:[NSNumber numberWithInt:tagId] forKey:@"Id"];
        [dict setObject:[NSNumber numberWithBool:YES] forKey:@"Enabled"];
        [dict setObject:@"test tag" forKey:@"Name"];
        [arr addObject:dict];
        [email setObject:arr forKey:@"Tags"];
        
        url = [NSString stringWithFormat:@"%@%@%d", mailUp.consoleEndpoint, @"/Console/List/1/Email/", emailId];
        NSString *tagRequest = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:email options:0 error:&error]
                                                               encoding:NSUTF8StringEncoding];
        [mailUp callMethodWithUrl:url verb:@"PUT" body:tagRequest contentType:kContentTypeJson error:&error];
        if (error && [error code] != 0) {
            output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
        } else {
            output = [output stringByAppendingFormat:@"Add the tag to the message details and save\nPUT %@ - OK\n", url];
        }
    }
    
    output = [output stringByAppendingFormat:@"Example methods completed successfully\n"];
    
    [txtExamplesResult setString:output];
}

// EXAMPLE 7 - SEND A MESSAGE
- (IBAction)callExample7:(id)sender
{
    NSError *error;
    NSString *output = @"";
    
    // Get the list of the existing messages
    NSString *url = [NSString stringWithFormat:@"%@%@", mailUp.consoleEndpoint, @"/Console/List/1/Emails"];
    NSString *result = [mailUp callMethodWithUrl:url verb:@"GET" body:nil contentType:kContentTypeJson error:&error];
    id object = [NSJSONSerialization JSONObjectWithData:[result dataUsingEncoding:NSUTF8StringEncoding]
                                                options:0
                                                  error:&error];
    if (error && [error code] != 0) {
        output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
    } else {
        output = [output stringByAppendingFormat:@"Get the list of the existing messages\nGET %@ - OK\n", url];
    }
    
    if ([object isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *root = object;
        NSArray *emails = (NSArray *)[root objectForKey:@"Items"];
        NSDictionary *email = (NSDictionary *)[emails objectAtIndex:0];
        emailId = [(NSNumber *)[email objectForKey:@"idMessage"] intValue];
    }
    
    // Send email to all recipients in the list
    url = [NSString stringWithFormat:@"%@%@%d%@", mailUp.consoleEndpoint, @"/Console/List/1/Email/", emailId, @"/Send"];
    result = [mailUp callMethodWithUrl:url verb:@"POST" body:nil contentType:kContentTypeJson error:&error];
    if (error && [error code] != 0) {
        output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
    } else {
        output = [output stringByAppendingFormat:@"Send email to all recipients in the list\nPOST %@ - OK\n", url];
    }
    
    output = [output stringByAppendingFormat:@"Example methods completed successfully\n"];
    
    [txtExamplesResult setString:output];
}

// EXAMPLE 8 - DISPLAY STATISTICS FOR A MESSAGE SENT AT EXAMPLE 7
- (IBAction)callExample8:(id)sender
{
    NSError *error;
    NSString *output = @"";
    
    // Request (to MailStatisticsService.svc) for paged message views list for the previously sent message
    int hours = 4;
    NSString *url = [NSString stringWithFormat:@"%@%@%d%@%d%@", mailUp.mailstatisticsEndpoint, @"/Message/", emailId, @"/Views/List/Last/", hours,
                     @"?pageSize=5&pageNum=0"];
    NSString *result = [mailUp callMethodWithUrl:url verb:@"GET" body:nil contentType:kContentTypeJson error:&error];
    
    if (error && [error code] != 0) {
        output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
    } else {
        output = [output stringByAppendingFormat:@"Request (to MailStatisticsService.svc) for paged message views list for the previously sent message\nGET %@ - OK\n", url];
    }
    
    output = [output stringByAppendingFormat:@"Example methods completed successfully\n"];
    
    [txtExamplesResult setString:output];
}

@end
