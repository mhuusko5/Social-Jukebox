#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>


@interface CAAnimation (MCAdditions)

+(CAAnimation *)flipAnimationWithDuration:(NSTimeInterval)duration forLayerBeginningOnTop:(BOOL)beginsOnTop scaleFactor:(CGFloat)scaleFactor;

@end


@interface NSView (MCAdditions)

-(CALayer *)layerFromContents;

@end


@interface FlipTransitionController : NSObject {
	NSView *hostView, *frontView, *backView;
    NSView *topView, *bottomView;
    CALayer *topLayer, *bottomLayer;
    BOOL isFlipped;
    NSTimeInterval duration;
}

@property (readonly) BOOL isFlipped;
@property NSTimeInterval duration;
@property (readonly) NSView *visibleView;

-(id)initWithHostView:(NSView *)newHost frontView:(NSView *)newFrontView backView:(NSView *)newBackView;

-(IBAction)flip:(id)sender;

@end
