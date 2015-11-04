////////////
//  Camera.h
////////////////////////////
//  Generic Sequence Grabber
////////////////////////////////////////////////
//  Created by David Towey - dave@oxidise.com.au
//  December 2004
//  Copyright 2004 Oxidise/Fabrica. All rights reserved.
////////////////////////////////////////////////////////
////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>


@interface Camera : NSObject

{
    NSTimer 		*myTimer;						// Camera timer
	Ptr				myvideoBaseAddress;				// Pointer to Pixel map base address
	GWorldPtr		myvideogworld;					// Pointer to the Sequence Grabber's gworld
	CFStringRef		inKey;
	int				w,h;
	Rect			myRect;
	
}

- (SeqGrabComponent)MakeSequenceGrabber;
- (void)initCapture; // call to make the camera start
- (int)MakeGrabChannels:(SeqGrabComponent) anSG theVideoChan:(SGChannel *) videoChannel theRect:(Rect *) bounds record:(Boolean) willRecord;
- (void)refresh;
- (void)settings;
- (void)SaveSettingsPreference;
- (void)GetSettingsPreference;
- (void)acquire;
- (Ptr)base;
- (GWorldPtr)pointer;

@end
