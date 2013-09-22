#import <Foundation/Foundation.h>


@interface ClearBorderlessPanel : NSPanel {
@private
	NSPoint initialLocation;
}

@property (assign) NSPoint initialLocation;

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag;
- (BOOL)canBecomeKeyWindow;
- (BOOL)isMainWindow;
- (void)mouseDown:(NSEvent *)theEvent;
- (void)mouseDragged:(NSEvent *)theEvent;

@end
