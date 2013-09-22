#import "MGTwitterEngine.h"

@class OAToken;
@class OAConsumer;

@interface xAuthTwitterEngine : MGTwitterEngine {
	OAConsumer *consumerObject;
	OAToken *accessToken;
}

+ (xAuthTwitterEngine *)oAuthTwitterEngineWithDelegate:(NSObject *)theDelegate;
- (xAuthTwitterEngine *)initOAuthWithDelegate:(NSObject *)newDelegate;

- (void)requestAccessToken;
- (void)clearAccessToken;

@property (retain)  OAConsumer *consumer;
@property (retain)  OAToken *accessToken;

@end


@protocol YHOAuthTwitterEngineDelegate

- (void)twitterEngineReceivedAccessToken:(id)sender;

@end
