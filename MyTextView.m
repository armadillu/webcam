#import "MyTextView.h"

@implementation MyTextView

-(void) awakeFromNib{
//	NSLog(@"aaaaaaWOOA! new window!!!!!!!!");	
	[self setBackgroundColor: [NSColor colorWithCalibratedWhite:1 alpha:0.5]];
	[self setDrawsBackground:NO];
	[super setDrawsBackground:NO];
	[super setBackgroundColor: [NSColor colorWithCalibratedWhite:1 alpha:0.5]];
//	[[self window] setOpaque:NO];

}

- (BOOL)isOpaque{

//	NSLog(@"opaque!!!!!!");	
    return NO;
}

@end
