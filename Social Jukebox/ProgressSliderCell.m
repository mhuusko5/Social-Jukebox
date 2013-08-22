#import "ProgressSliderCell.h"

@implementation ProgressSliderCell

- (void)drawBarInside:(NSRect)aRect flipped:(BOOL)flipped {
	[self drawHorizontalBarInFrame: aRect];
}

- (void)drawKnob:(NSRect)aRect {
	NSBezierPath *clipPath = [[NSBezierPath new] autorelease];
	[clipPath appendBezierPathWithRect:aRect];
	[clipPath addClip];
    [self drawHorizontalKnobInFrame: aRect];
}

- (void)drawHorizontalBarInFrame:(NSRect)frame {
        
    frame.origin.y = frame.origin.y + (((frame.origin.y + frame.size.height) /2) - 2.5f);
    
    frame.origin.x += 0.5f;
    frame.origin.y += 0.5f;
    frame.size.width -= 1;
    frame.size.height = 9;
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect: frame xRadius: 3.6 yRadius: 3.6];
	NSColor *blackish = [NSColor colorWithDeviceRed: 0.220f green: 0.220f blue: 0.220f alpha: 0.75f];
    NSColor *whitishcolor = [NSColor colorWithDeviceRed: 0.749f green: 0.761f blue: 0.788f alpha: 0.9f];
    [blackish  set];
    [path fill];
    [whitishcolor  set];
    [path stroke];
}

- (void)drawHorizontalKnobInFrame:(NSRect)frame {
    
    frame.origin.x += 2;
    frame.origin.y += 6;
    frame.size.height = 8;
    frame.size.width = 8;
    
	NSBezierPath *pathOuter = [[NSBezierPath alloc] init];
	NSBezierPath *pathInner = [[NSBezierPath alloc] init];
    
    [pathOuter appendBezierPathWithOvalInRect: frame];
    
    frame = NSInsetRect(frame, 1, 1);
    
    [pathInner appendBezierPathWithOvalInRect: frame];
		
    [NSGraphicsContext saveGraphicsState];

    [[NSColor blackColor]  set];
    [pathOuter fill];

    [[NSColor whiteColor]  set];
    [pathInner fill];
        
    [NSGraphicsContext restoreGraphicsState];
}

- (BOOL)_usesCustomTrackImage {
	
	return YES;
}

@end
