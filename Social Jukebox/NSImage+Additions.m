#import "NSImage+Additions.h"

@implementation NSImage (Additions)

+(NSImage*)reflectedImage:(NSImage*)source amountReflected:(float)fraction
{
	NSRect imageRect = NSMakeRect(0.0f, 0.0f, [source size].width, [source size].height*fraction);
	NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor whiteColor] 
														 endingColor:[NSColor clearColor]];
	
	NSImage* reflection = [[NSImage alloc] initWithSize:imageRect.size];
	[reflection setFlipped:YES];
	[reflection lockFocus];
	[gradient drawInRect:imageRect angle:90.0f];
	[source drawAtPoint:NSMakePoint(0,0) 
			   fromRect:NSZeroRect 
			  operation:NSCompositeSourceIn 
			   fraction:0.8];
	[reflection unlockFocus];				
	[gradient release];
	return reflection;
}

+(NSImage*)imageWithReflection:(NSImage*)source amountReflected:(float)fraction {
	
	NSImage *reflection = [NSImage reflectedImage:source amountReflected:fraction];
	NSSize resultSize = [source size];
	resultSize.height += [reflection size].height;
	
	NSImage *result = [[NSImage alloc] initWithSize:resultSize];
	[result lockFocus];
	
	[source drawInRect:NSMakeRect(0, [reflection size].height, [source size].width, [source size].height) 
		   fromRect:NSZeroRect 
		  operation:NSCompositeCopy 
		   fraction:1.0];
	[reflection drawInRect:NSMakeRect(0, 0, [reflection size].width, [reflection size].height) 
				  fromRect:NSZeroRect 
				 operation:NSCompositeCopy
				  fraction:1.0];
	[result unlockFocus];
	[reflection release];
	return [result autorelease];
	
	
}

@end
