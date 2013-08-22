//
//  PhWebViewController.m
//  PhFacebook
//
//  Created by Philippe on 10-08-27.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import "PhWebViewController.h"
#import "PhFacebook_URLs.h"
#import "PhFacebook.h"

@implementation PhWebViewController

@synthesize window;
@synthesize webView;
@synthesize cancelButton;
@synthesize parent;
@synthesize permissions;

- (void) awakeFromNib
{
    NSBundle *bundle = [NSBundle bundleForClass: [PhFacebook class]];
    self.window.title = [bundle localizedStringForKey: @"Facebook Authentication" value: @"" table: nil];
    self.cancelButton.title = [bundle localizedStringForKey: @"Cancel" value: @"" table: nil];
    self.window.delegate = self;
    self.window.level = NSFloatingWindowLevel;
    self.window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
}

- (void) windowWillClose: (NSNotification*) notification
{
    [self cancel: nil];
}

#pragma mark Delegate

- (void) showUI
{
    // Facebook needs user input, show the window
    [self.window makeKeyAndOrderFront: self];
    [windowViewManager fadeInWindowInNewThread:window];
    // Notify parent that we're about to show UI
    [self.parent webViewWillShowUI];
}


- (void) webView: (WebView*) sender didCommitLoadForFrame: (WebFrame*) frame;
{
    NSString *url = [sender mainFrameURL];
    //DebugLog(@"didCommitLoadForFrame: {%@}", url);
    
    NSString *urlWithoutSchema = [url substringFromIndex: [@"http://" length]];
    if ([url hasPrefix: @"https://"])
        urlWithoutSchema = [url substringFromIndex: [@"https://" length]];
    
    NSString *uiServerURLWithoutSchema = [kFBUIServerURL substringFromIndex: [@"http://" length]];
    NSComparisonResult res = [urlWithoutSchema compare: uiServerURLWithoutSchema options: NSCaseInsensitiveSearch range: NSMakeRange(0, [uiServerURLWithoutSchema length])];
    if (res == NSOrderedSame)
        [self showUI];
}

- (NSString*) extractParameter: (NSString*) param fromURL: (NSString*) url
{
    NSString *res = nil;

    NSRange paramNameRange = [url rangeOfString: param options: NSCaseInsensitiveSearch];
    if (paramNameRange.location != NSNotFound)
    {
        // Search for '&' or end-of-string
        NSRange searchRange = NSMakeRange(paramNameRange.location + paramNameRange.length, [url length] - (paramNameRange.location + paramNameRange.length));
        NSRange ampRange = [url rangeOfString: @"&" options: NSCaseInsensitiveSearch range: searchRange];
        if (ampRange.location == NSNotFound)
            ampRange.location = [url length];
        res = [url substringWithRange: NSMakeRange(searchRange.location, ampRange.location - searchRange.location)];
    }

    return res;
}

- (void) webView: (WebView*) sender didFinishLoadForFrame: (WebFrame*) frame
{
    NSString *url = [sender mainFrameURL];
    //DebugLog(@"didFinishLoadForFrame: {%@}", url);
    
    NSString *urlWithoutSchema = [url substringFromIndex: [@"http://" length]];
    if ([url hasPrefix: @"https://"])
        urlWithoutSchema = [url substringFromIndex: [@"https://" length]];
    
    NSString *loginSuccessURLWithoutSchema = [kFBLoginSuccessURL substringFromIndex: 7];
    NSComparisonResult res = [urlWithoutSchema compare: loginSuccessURLWithoutSchema options: NSCaseInsensitiveSearch range: NSMakeRange(0, [loginSuccessURLWithoutSchema length])];
    if (res == NSOrderedSame)
    {
        NSString *accessToken = [self extractParameter: kFBAccessToken fromURL: url];
        NSString *tokenExpires = [self extractParameter: kFBExpiresIn fromURL: url];
        NSString *errorReason = [self extractParameter: kFBErrorReason fromURL: url];
        
        [self.window orderOut: self];
        
        [parent setAccessToken: accessToken expires: [tokenExpires floatValue] permissions: self.permissions error: errorReason];
    }else{
        [self showUI];
        //THIS ELSE STATEMENT MUST BE HERE - IT MEANS THE UI WILL OPEN IF ANYTHING HAPPENS EXCEPT FOR SUCCESFUL TOKEN GRAB - BEFORE IT WOULD ONLY OPEN IF IT FOUND A LOGIN PAGE, BUT YOU COULD ALREADY BE LOGGED IN WITHOUT BEING AUTHORIZIED....
    }
}

- (IBAction) cancel: (id) sender
{
    [parent performSelector: @selector(didDismissUI)];
    [windowViewManager fadeOutWindowInNewThread:window];
    [self.window orderOut: nil];
}

@end
