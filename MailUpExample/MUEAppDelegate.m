//
//  MUEAppDelegate.m
//  MailUpExample
//
//  Created by Sergei Inyushkin on 10.07.13.
//  Copyright (c) 2013 MailUp. All rights reserved.
//

#import "MUEAppDelegate.h"


@implementation MUEAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [txtCallResult setBackgroundColor:[NSColor colorWithSRGBRed:0 green:0 blue:0 alpha:0]];
    [txtExamplesResult setBackgroundColor:[NSColor colorWithSRGBRed:0 green:0 blue:0 alpha:0]];

    mailUp = [[MailUpClient alloc] initWithClientId:CLIENT_ID clientSecret:CLIENT_SECRET];
    //mailUp.logonEndpoint = MAIL_UP_LOGON;
    //mailUp.authorizationEndpoint = MAIL_UP_AUTHORIZATION;
    //mailUp.tokenEndpoint = MAIL_UP_TOKEN;
    //mailUp.consoleEndpoint = MAIL_UP_CONSOLE_ENDPOINT;
    //mailUp.mailstatisticsEndpoint = MAIL_UP_STATS_ENDPOINT;
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
            if ([@"migo test import" isEqualToString:name]) groupId = [(NSNumber *)[group objectForKey:@"idGroup"] intValue];
        }
    }
    
    // If the list does not contain a group named “test import”, create it
    if (groupId == -1)
    {
        groupId = 100;
        url = [NSString stringWithFormat:@"%@%@", mailUp.consoleEndpoint, @"/Console/List/1/Group"];
        NSString *groupRequest = @"{\"Deletable\":true,\"Name\":\"migo test import\",\"Notes\":\"test import\"}";
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
                if ([@"migo test import" isEqualToString:name]) groupId = [(NSNumber *)[group objectForKey:@"idGroup"] intValue];
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
    if ([object isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *root = (NSDictionary *)object; 
        NSArray *templates = (NSArray *)[root objectForKey:@"Items"];
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
    NSString *imageBase64Str = @"iVBORw0KGgoAAAANSUhEUgAAAR4AAACnCAMAAADwpcPtAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAYBQTFRFKSkphYWFeHh4GhoaYWFhJSUlVVVV3t7ePT09XV1doKCgdXV1np6ezMzMrq6upqamxMTEWVlZz8/Po6OjoqKilpaWZ2dnNjY2SEhIbm5usLCwysrKtra2AAAAZWVlvLy8h4eHx8fHqampmpqawsLC1NTUxsbGmJiYlJSUs7OzfHx8nJycRERERkZGiYmJwMDAq6urS0tL0dHRISEhrKysjIyMcnJyj4+PuLi4NDQ0KioqZGRkkJCQTExMODg4urq6kpKSUFBQQEBAU1NTMTExioqKcHBwLCwsCgoKQkJCTk5OOjo6Ly8vgICAgoKCFhYW0tLSLi4ufn5+ERERa2trbGxs2tra7+/v5ubm+vr68fHx+fn5tbW1/Pz8/f394uLi7u7u9PT08PDw+/v75OTk/v7+8/Pz4+Pj8vLy9vb29/f32NjY6+vr3d3d19fX6Ojo5eXl3Nzc7e3t5+fn+Pj49fX14ODgvr6+v7+/7Ozs6enp2dnZ4eHh6urqtLS0////r2s4NAAAAIB0Uk5T/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////wA4BUtnAAAU8klEQVR42uyd+UPaSBvHoxJEFBAtBKyzHuh6YVvWlQoKLZAWLB7r0kWBggoigvd9O//6mwtIQiCJpTV9m/mhRchMnnwy88yTme9MEKimBglREah4VDwqHhWPiuf/DM9lz1Rnh5ZM5s/j3WeSSs3E9W5tKBTSmju7ei7rHZVPSU0XCWXiSf9pnwHstOrr2xMrc9fkIQ+NxGIR8v+ZzrjwcRvIjKSEIohbiXjSExh5eZoF45+nD1eGCYs1TPzd9qZhFUr3tgHgnx0p3CazB4dPb4IEoz+uhI48aZOWUABsL4cnV6/mGnQEi1YDu3EkDi048aU+XbfAYyeItJ5yKokDAcuCTXBbSrq8eA/A3y+G57UnPCH0S2mZ4DC+VfN9boCg5izU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";

    // Upload an image
    NSString *url = [NSString stringWithFormat:@"%@%@", mailUp.consoleEndpoint, @"/Console/List/1/Images"];
    NSString *imageRequest = [NSString stringWithFormat:@"{\"Base64Data\":\"%@\",\"Name\":\"Avatar\"}", imageBase64Str];
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
        emailId = [(NSNumber *)[root objectForKey:@"idMessage"] intValue];
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
    NSString *url = [NSString stringWithFormat:@"%@%@%d%@", mailUp.mailstatisticsEndpoint, @"/Message/", emailId, @"/List/Views?pageSize=5&pageNum=0"];
    [mailUp callMethodWithUrl:url verb:@"GET" body:nil contentType:kContentTypeJson error:&error];
    
    if (error && [error code] != 0) {
        output = [output stringByAppendingFormat:@"Error %d\n", (int)error.code];
    } else {
        output = [output stringByAppendingFormat:@"Request (to MailStatisticsService.svc) for paged message views list for the previously sent message\nGET %@ - OK\n", url];
    }
    
    output = [output stringByAppendingFormat:@"Example methods completed successfully\n"];
    
    [txtExamplesResult setString:output];
}

@end
