#import "ScrollingTextView.h"

#define kFBScrollingTextViewSpacing 0.5

#define kFBScrollingTextViewDefaultScrollingSpeed 2
#define kFBScrollingTextViewStartScrollingDelay 0.3

@implementation ScrollingTextView
@synthesize scrollingSpeed;
@synthesize string;
@synthesize fontcolor;
@synthesize statusitem;
@synthesize font;
@synthesize yoffset;

- (void)scrollText {
	cursor.x -= 1;
	[self setNeedsDisplay:YES];
}

- (void)startScrolling {
	if (!tickTockScroll) {
		tickTockScroll = [NSTimer scheduledTimerWithTimeInterval:refreshRate / scrollingSpeed target:self selector:@selector(scrollText) userInfo:nil repeats:YES];
		[[NSRunLoop currentRunLoop] addTimer:tickTockScroll forMode:NSEventTrackingRunLoopMode];
	}
	[tickTockStartScrolling release];
	tickTockStartScrolling = nil;
}

- (CGFloat)stringWidth {
	if (!string) return 0;
	NSSize stringSize = [string sizeWithAttributes:attrs];
	return stringSize.width;
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:NSRectFromCGRect(frame)];
	if (self) {
		// Initialization code.
		scrollingSpeed = kFBScrollingTextViewDefaultScrollingSpeed;
		refreshRate = 0.05;
		cursor = NSMakePoint(0, 0);
		yoffset = 0;
		self.font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
		if (fontcolor) {
			attrs = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, fontcolor, NSForegroundColorAttributeName, nil];
		}
		else {
			attrs = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, nil];
		}
	}
	return self;
}

- (void)setString:(NSString *)_string {
	if (![[self string] isEqualToString:_string]) {
		if (tickTockScroll) {
			[tickTockScroll invalidate];
			[tickTockScroll release];
			tickTockScroll = nil;
		}
		if (tickTockStartScrolling) {
			[tickTockStartScrolling invalidate];
			[tickTockStartScrolling release];
			tickTockStartScrolling = nil;
		}
        
		[string release];
		string = [_string retain];
		CGRect thisFrame = NSRectToCGRect([super frame]);
		if ([self stringWidth] > thisFrame.size.width) {
			if (!tickTockStartScrolling) {
				tickTockStartScrolling = [NSTimer scheduledTimerWithTimeInterval:kFBScrollingTextViewStartScrollingDelay target:self selector:@selector(startScrolling) userInfo:nil repeats:NO];
			}
		}
		cursor = NSMakePoint((thisFrame.size.width - [self stringWidth]) / 2, yoffset);
		[self setNeedsDisplay:YES];
	}
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:NSRectFromCGRect(rect)];
	// Drawing code.
	CGFloat sWidth = round([self stringWidth]);
	CGFloat rWidth = round(rect.size.width);
	CGFloat spacing = round(rWidth * kFBScrollingTextViewSpacing);
    
	if (fontcolor) {
		attrs = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, fontcolor, NSForegroundColorAttributeName, nil];
	}
	else {
		attrs = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, nil];
	}
    
	if ((cursor.x * -1) >= sWidth) {
		CGFloat diff = spacing - (sWidth + cursor.x);
		cursor.x = rWidth - diff;
	}
    
	[string drawAtPoint:cursor withAttributes:attrs];
    
	CGFloat diff = spacing - (sWidth + cursor.x);
	if (diff >= 0) {
		NSPoint point = NSMakePoint(rWidth - diff, cursor.y);
		[string drawAtPoint:point withAttributes:attrs];
	}
}

- (void)mouseDown:(NSEvent *)theEvent {
	[[self superview] mouseDown:theEvent];
	if (statusitem) {
		[statusitem popUpStatusItemMenu:[statusitem menu]];
	}
}

@end
