#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface WindowViewManager : NSObject {
@private
	BOOL windowFading;
}

- (void)toggleBetweenSubview:(NSView *)subview1 andSubview:(NSView *)subview2 ofSuperview:(NSView *)superview;
- (void)slideBetweenSubview:(NSView *)subview1 andSubview:(NSView *)subview2 ofSuperview:(NSView *)superview;
- (void)toggleChildWindow:(NSWindow *)child ofParentWindow:(NSWindow *)parent withFade:(BOOL)fade;
- (void)fadeInWindowInNewThread:(NSWindow *)window;
- (void)fadeInWindow:(NSWindow *)window;
- (void)fadeOutWindowInNewThread:(NSWindow *)window;
- (void)fadeOutWindow:(NSWindow *)window;
- (void)fadeInOutWindowInNewThread:(NSWindow *)window withDelay:(double)delay;
- (void)fadeInOutWindow:(NSWindow *)window withDelay:(double)delay;
- (void)fadeInOutWindowComposite:(NSMutableArray *)windowAndDelay;
- (void)fadeInViewInNewThread:(NSView *)view;
- (void)fadeInView:(NSView *)view;
- (void)fadeOutViewInNewThread:(NSView *)view;
- (void)fadeOutView:(NSView *)view;

@end
