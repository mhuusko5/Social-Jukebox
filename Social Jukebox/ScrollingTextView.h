#import <Cocoa/Cocoa.h>
#import "AttachedPopupWindow.h"

@interface ScrollingTextView : NSView {
	NSString *string;
	CGFloat scrollingSpeed;
	NSFont *font;
	NSColor *fontcolor;
	NSDictionary *attrs;
	NSStatusItem *statusitem;
	int yoffset;
@private
	CGFloat refreshRate;
	NSTimer *tickTockStartScrolling;
	NSTimer *tickTockScroll;
	NSPoint cursor;
}
@property (readwrite, retain, nonatomic) NSFont *font;
@property (readwrite) int yoffset;
@property (readwrite, retain, nonatomic) NSStatusItem *statusitem;
@property (readwrite, retain, nonatomic) NSColor *fontcolor;
@property (readwrite) CGFloat scrollingSpeed;
@property (readwrite, retain, nonatomic) NSString *string;

@end
