#import "ProfileHolderView.h"

@implementation ProfileHolderView

- (id)init
{
    self = [super init];
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)drawRect:(NSRect)rect
{
    [NSGraphicsContext saveGraphicsState];
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:4 yRadius:4];
    [path addClip];
    
    [super drawRect:rect];
    
    [[NSColor whiteColor] setStroke];
    [path setLineWidth:2];
    [path stroke];
    
    [NSGraphicsContext restoreGraphicsState];
}

@end
