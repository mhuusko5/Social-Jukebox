#import "xAuthTwitterEngine.h"
#import "MGTwitterHTTPURLConnection.h"
#import "OAConsumer.h"
#import "OAMutableURLRequest.h"
#import "OADataFetcher.h"

#define kOAuthAccessTokenKey            @"kOAuthAccessTokenKey"
#define kOAuthAccessTokenSecret         @"kOAuthAccessTokenSecret"
#define kYHOAuthClientName              @"YOURCLIENTNAME"
#define kYHOAuthClientVersion           @"1.0"
#define kYHOAuthClientURL               @"YOURWEBSITEURL"
#define kYHOAuthClientToken             @"YHOAuthTester"
#define kOAuthConsumerKey               @"YOURCONSUMERKEY"
#define kOAuthConsumerSecret            @"YOURCONSUMERSECRET"

#define kYHOAuthTwitterAccessTokenURL   @"https://api.twitter.com/oauth/access_token"



@interface xAuthTwitterEngine (private)

- (void)_fail:(OAServiceTicket *)ticket data:(NSData *)data;
- (void)_setAccessToken:(OAServiceTicket *)ticket withData:(NSData *)data;
- (NSString *)_queryStringWithBase:(NSString *)base parameters:(NSDictionary *)params prefixed:(BOOL)prefixed;

@end


@implementation xAuthTwitterEngine

@synthesize accessToken = accessToken;
@synthesize consumer = consumerObject;

+ (xAuthTwitterEngine *)oAuthTwitterEngineWithDelegate:(NSObject *)theDelegate;
{
	return [[[xAuthTwitterEngine alloc] initOAuthWithDelegate:theDelegate] autorelease];
}


- (xAuthTwitterEngine *)initOAuthWithDelegate:(NSObject *)newDelegate;
{
	if ((self = (xAuthTwitterEngine *)[super initWithDelegate:newDelegate])) {
		self.consumer = [[[OAConsumer alloc] initWithKey:kOAuthConsumerKey secret:kOAuthConsumerSecret] autorelease];
		[self setClientName:kYHOAuthClientName
		            version:kYHOAuthClientVersion
		                URL:kYHOAuthClientURL
		              token:kYHOAuthClientToken];
	}
	return self;
}

#pragma mark OAuth
// --------------------------------------------------------------------------------


- (void)requestAccessToken;
{
	//
	// xAuth doesn't require the request token, so we're just going to pass nil in for the token.
	//
	OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:kYHOAuthTwitterAccessTokenURL] consumer:self.consumer token:nil realm:nil signatureProvider:nil] autorelease];
	if (!request)
		return;
    
	[request setHTTPMethod:@"POST"];
    
	//
	// Here's the parameters for xAuth
	// we're just going to add the extra parameters to the access token request
	//
	[request setParameters:[NSArray arrayWithObjects:
	                        [OARequestParameter requestParameterWithName:@"x_auth_mode" value:@"client_auth"],
	                        [OARequestParameter requestParameterWithName:@"x_auth_username" value:_username],
	                        [OARequestParameter requestParameterWithName:@"x_auth_password" value:_password],
	                        nil]];
    
	OADataFetcher *fetcher = [[[OADataFetcher alloc] init] autorelease];
	[fetcher fetchDataWithRequest:request delegate:self didFinishSelector:@selector(_setAccessToken:withData:) didFailSelector:@selector(_fail:data:)];
}


//
// Clear our access token and removing it from the keychain
//
- (void)clearAccessToken;
{
	self.accessToken = nil;
}


#pragma mark OAuth private
// --------------------------------------------------------------------------------


//
// if the fetch fails this is what will happen
// you'll want to add your own error handling here.
//
- (void)_fail:(OAServiceTicket *)ticket data:(NSData *)data;
{
	if ([_delegate respondsToSelector:@selector(twitterEngineNotReceivedAccessToken)])
		[_delegate performSelector:@selector(twitterEngineNotReceivedAccessToken) withObject:nil];
}



//
// access token callback
// when twitter sends us an access token this callback will fire
// we store it in our ivar as well as writing it to the keychain
//
- (void)_setAccessToken:(OAServiceTicket *)ticket withData:(NSData *)data;
{
	if (!ticket.didSucceed) {
		if ([_delegate respondsToSelector:@selector(twitterEngineNotReceivedAccessToken)])
			[_delegate performSelector:@selector(twitterEngineNotReceivedAccessToken) withObject:nil];
		NSLog(@"access token exchange failed");
		return;
	}
    
	if (!data) {
		if ([_delegate respondsToSelector:@selector(twitterEngineNotReceivedAccessToken)])
			[_delegate performSelector:@selector(twitterEngineNotReceivedAccessToken) withObject:nil];
		NSLog(@"access token said it succeeded but no data was returned");
		return;
	}
    
	NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (!dataString) {
		if ([_delegate respondsToSelector:@selector(twitterEngineNotReceivedAccessToken)])
			[_delegate performSelector:@selector(twitterEngineNotReceivedAccessToken) withObject:nil];
		return;
	}
    
	self.accessToken = [[[OAToken alloc] initWithHTTPResponseBody:dataString] autorelease];
	[dataString release];
	dataString = nil;
	if ([_delegate respondsToSelector:@selector(twitterEngineReceivedAccessToken:)])
		[_delegate performSelector:@selector(twitterEngineReceivedAccessToken:) withObject:self];
}


#pragma mark MGTwitterEngine Changes


#define SET_AUTHORIZATION_IN_HEADER 1

- (NSString *)_sendRequestWithMethod:(NSString *)method
                                path:(NSString *)path
                     queryParameters:(NSDictionary *)params
                                body:(NSString *)body
                         requestType:(MGTwitterRequestType)requestType
                        responseType:(MGTwitterResponseType)responseType {
	NSString *fullPath = path;
    
	BOOL isPOST = (method && [method isEqualToString:@"POST"]);
	if ((!isPOST) && (params))
		fullPath = [self _queryStringWithBase:fullPath parameters:params prefixed:YES];
    
    
	NSString *urlString = [NSString stringWithFormat:@"%@://%@/%@",
	                       (_secureConnection) ? @"https":@"http",
	                       _APIDomain, fullPath];
	NSURL *finalURL = [NSURL URLWithString:urlString];
	if (!finalURL) {
		return nil;
	}
    
	OAMutableURLRequest *theRequest = [[[OAMutableURLRequest alloc] initWithURL:finalURL
	                                                                   consumer:self.consumer token:self.accessToken realm:nil
	                                                          signatureProvider:nil] autorelease];
	if (method) {
		[theRequest setHTTPMethod:method];
	}
	[theRequest setHTTPShouldHandleCookies:NO];
	[theRequest setValue:_clientName forHTTPHeaderField:@"X-Twitter-Client"];
	[theRequest setValue:_clientVersion forHTTPHeaderField:@"X-Twitter-Client-Version"];
	[theRequest setValue:_clientURL forHTTPHeaderField:@"X-Twitter-Client-URL"];
    
	if (isPOST) {
		NSString *finalBody = @"";
		if (body) {
			finalBody = [finalBody stringByAppendingString:body];
		}
		if (_clientSourceToken) {
			finalBody = [finalBody stringByAppendingString:[NSString stringWithFormat:@"%@source=%@",
			                                                (body) ? @"&"            :@"?",
			                                                _clientSourceToken]];
		}
        
		if (finalBody) {
			[theRequest setHTTPBody:[finalBody dataUsingEncoding:NSUTF8StringEncoding]];
		}
	}
    
    
	[theRequest prepare];
    
	MGTwitterHTTPURLConnection *connection;
	connection = [[MGTwitterHTTPURLConnection alloc] initWithRequest:theRequest
	                                                        delegate:self
	                                                     requestType:requestType
	                                                    responseType:responseType];
    
	if (!connection) {
		return nil;
	}
	else {
		[_connections setObject:connection forKey:[connection identifier]];
		[connection release];
	}
    
	return [connection identifier];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	// --------------------------------------------------------------------------------
	// modificaiton from the base clase
	// instead of answering the authentication challenge, we just ignore it.
	// --------------------------------------------------------------------------------
    
	[[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
	return;
}

@end
