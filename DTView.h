/* View */

#import <Cocoa/Cocoa.h>


#import "Camera.h"
#import "NSView+ImageRepresentation.h"

@interface DTView : NSQuickDrawView
{

	bool FullScreenOn;
	int w, h;
	Rect		myRect;
    
    NSWindow *FullScreenWindow;
    NSWindow *StartingWindow;

	NSTimer		*myTimer;
	NSTimer		*myCaptureTimer;
	Camera		*myCamera;
	
	GrafPtr		myport; 
	
	GWorldPtr	displayGWorld;
	Ptr			displayPixels;
	
	GWorldPtr camGWorld;
	
	Ptr camPixels;

	IBOutlet NSImageView * overlay;
	IBOutlet NSScrollView * textOverlay;
	
	
}

- (id) initWithFrame:(NSRect)frameRect;

- (void) refresh;
- (void) makeTimer;
- (void) initCamera;
- (void) capture;

- (NSImage*) imageFromGworld:(GWorldPtr) gworld;
@end
