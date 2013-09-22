#import "HUDPopupWindow.h"


@implementation HUDPopupWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation {
	if ((self = [super initWithContentRect:contentRect
	                             styleMask:NSBorderlessWindowMask
	                               backing:NSBackingStoreBuffered defer:deferCreation])) {
		[self setAlphaValue:0.0];
		[self setOpaque:NO];
		[self setLevel:NSFloatingWindowLevel];
		[self setExcludedFromWindowsMenu:YES];
		[self setBackgroundColor:[NSColor clearColor]];
	}
	return self;
}

@end
