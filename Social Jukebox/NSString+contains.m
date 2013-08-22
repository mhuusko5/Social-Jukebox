#import "NSString+contains.h"

@implementation NSString ( containsCategory )

- (BOOL) containsString: (NSString*) substring
{    
    NSRange range = [self rangeOfString : substring];
    
    BOOL found = ( range.location != NSNotFound );
    
    return found;
}

@end