#import "WindowViewManager.h"

@implementation WindowViewManager

- (void)toggleBetweenSubview:(NSView *)subview1 andSubview:(NSView *)subview2 ofSuperview:(NSView *)superview
{
    if([[superview subviews] containsObject:subview1]){
        [subview1 removeFromSuperview];
        [superview addSubview:subview2];
    }else{
        [superview addSubview:subview1];
        [subview2 removeFromSuperview];
    }
}

- (void)slideBetweenSubview:(NSView *)subview1 andSubview:(NSView *)subview2 ofSuperview:(NSView *)superview
{
    if([superview wantsLayer])
    {
        if([[superview subviews] containsObject:subview1]){
            CATransition *transition = [CATransition animation];
            [transition setType:kCATransitionPush];
            [transition setSubtype:kCATransitionFromRight];
            [superview setAnimations:[NSDictionary dictionaryWithObject:transition forKey:@"subviews"]];
            [[superview animator]addSubview:subview2];
            [subview1 removeFromSuperview];
        }else{
            CATransition *transition = [CATransition animation];
            [transition setType:kCATransitionPush];
            [transition setSubtype:kCATransitionFromLeft];
            [superview setAnimations:[NSDictionary dictionaryWithObject:transition forKey:@"subviews"]];
            [[superview animator]addSubview:subview1];
            [subview2 removeFromSuperview];
        }
    }else 
    {
        [self toggleBetweenSubview:subview1 andSubview:subview2 ofSuperview:superview];
    }
}

- (void)toggleChildWindow:(NSWindow *)child ofParentWindow:(NSWindow *)parent withFade:(BOOL)fade
{
    BOOL open;
    if([[parent childWindows] containsObject:child]){
        open = TRUE;
    }else{
        open = FALSE;
    }
    
    if(fade == TRUE){
        if(open == FALSE) {
            [parent addChildWindow:child ordered:NSWindowAbove];
            [NSThread detachNewThreadSelector:@selector(fadeInWindow:) toTarget:self withObject:child];
        }else{
            [NSThread detachNewThreadSelector:@selector(fadeOutWindow:) toTarget:self withObject:child];
        }
    }else{
        if(open == FALSE) {
            [parent addChildWindow:child ordered:NSWindowAbove];
            [child setAlphaValue:1.0];
        }else{
            [child setAlphaValue:0.0];
            [parent removeChildWindow:child];
            [child orderOut:self];
        }
    }
}

- (void)fadeInWindowInNewThread:(NSWindow *)window
{
    [NSThread detachNewThreadSelector:@selector(fadeInWindow:) toTarget:self withObject:window];
}

- (void)fadeInWindow:(NSWindow *)window
{
    if(windowFading == FALSE){
        windowFading = TRUE;
        float alpha = 0.0;
        [window makeKeyAndOrderFront:self];
        [window setAlphaValue:alpha];
        while([window alphaValue] <= 1.0){
            alpha += 0.05;
            [window setAlphaValue:alpha];
            [NSThread sleepForTimeInterval:0.015];
        }
        windowFading = FALSE;
    }
}

- (void)fadeOutWindowInNewThread:(NSWindow *)window
{
    [NSThread detachNewThreadSelector:@selector(fadeOutWindow:) toTarget:self withObject:window];
}

- (void)fadeOutWindow:(NSWindow *)window
{
    if(windowFading == FALSE){
        windowFading = TRUE;
        float alpha = 1.0;
        [window setAlphaValue:alpha];
        while([window alphaValue] > 0.0){
            alpha -= 0.05;
            [window setAlphaValue:alpha];
            [NSThread sleepForTimeInterval:0.015];
        }
        [[window parentWindow] removeChildWindow:window];
        [window orderOut:self];
        windowFading = FALSE;
    }
}

- (void)fadeInOutWindowInNewThread:(NSWindow *)window withDelay:(double)delay
{
    NSMutableArray *windowAndDelay = [[NSMutableArray alloc] initWithCapacity:2];
    [windowAndDelay addObject:window];
    [windowAndDelay addObject:[NSNumber numberWithDouble:delay]];
    [NSThread detachNewThreadSelector:@selector(fadeInOutWindowComposite:) toTarget:self withObject:windowAndDelay];
}

- (void)fadeInOutWindow:(NSWindow *)window withDelay:(double)delay
{
    NSMutableArray *windowAndDelay = [[NSMutableArray alloc] initWithCapacity:2];
    [windowAndDelay addObject:window];
    [windowAndDelay addObject:[NSNumber numberWithDouble:delay]];
    [self fadeInOutWindowComposite:windowAndDelay];
}

- (void)fadeInOutWindowComposite:(NSMutableArray *)windowAndDelay
{
    NSWindow *window = [windowAndDelay objectAtIndex:0];
    double delay = [[windowAndDelay objectAtIndex:1] doubleValue];
    
    [self fadeInWindow:window];
    
    [NSThread sleepForTimeInterval:delay];
    
    [self fadeOutWindow:window];
}

- (void)fadeInViewInNewThread:(NSView *)view
{
    [NSThread detachNewThreadSelector:@selector(fadeInView:) toTarget:self withObject:view];
}

- (void)fadeInView:(NSView *)view
{
    [[view animator] setAlphaValue:1.0];
}

- (void)fadeOutViewInNewThread:(NSView *)view
{
    [NSThread detachNewThreadSelector:@selector(fadeOutView:) toTarget:self withObject:view];
}

- (void)fadeOutView:(NSView *)view
{
    [[view animator] setAlphaValue:0.0];
}

@end
