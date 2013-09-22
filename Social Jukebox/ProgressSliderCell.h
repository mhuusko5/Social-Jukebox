#import <Cocoa/Cocoa.h>

@interface ProgressSliderCell : NSSliderCell {
}

- (void)drawHorizontalBarInFrame:(NSRect)frame;
- (void)drawHorizontalKnobInFrame:(NSRect)frame;

@end
