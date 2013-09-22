#import "HUDPopupView.h"

@implementation HUDPopupView

- (id)initWithFrame:(NSRect)frame {
	if ((self = [super initWithFrame:frame])) {
	}
	return self;
}

- (void)drawRect:(NSRect)frame {
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:frame xRadius:22.0 yRadius:22.0];
	[[NSColor colorWithDeviceRed:0.250f green:0.250f blue:0.250f alpha:0.75f] set];
	[path fill];
}

@end
