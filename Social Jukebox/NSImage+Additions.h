#import <Cocoa/Cocoa.h>


@interface NSImage (Additions)

+ (NSImage *)reflectedImage:(NSImage *)source amountReflected:(float)fraction;
+ (NSImage *)imageWithReflection:(NSImage *)source amountReflected:(float)fraction;
@end
