#import "DTView.h"
#include "stuff.h"

float CAPTURE = 9;
float REFRESH = 1;
float JPEG = .7;

@implementation DTView

- (id)initWithFrame:(NSRect)frameRect{
	
	[NSColor setIgnoresAlpha:NO];
	[super initWithFrame:frameRect];

	w = WIDTH;
	h = HEIGHT;
	MacSetRect(&myRect,0,0,w,h);

	myport = [self qdPort];
	
	[self makeTimer];
	[self initCamera];

	return self;
}

-(IBAction)setRefresh:(id) sender{
	REFRESH = [sender floatValue];
//	NSLog(@"%f",REFRESH);
}

-(IBAction)setCapture:(id) sender{
	CAPTURE = [sender floatValue];
//	NSLog(@"%f",CAPTURE);
}

-(IBAction)setJPEG:(id) sender{
	JPEG = [sender floatValue] / 100.0;
}

-(IBAction)prefs:(id) sender{
	[myCamera settings];
}


-(void)makeTimer{

	// make the camera timer
	myTimer = [NSTimer scheduledTimerWithTimeInterval:REFRESH target:self selector:@selector(refresh) userInfo:nil repeats:NO];
	myCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:CAPTURE target:self selector:@selector(capture) userInfo:nil repeats:NO];

}

-(void) initCamera{
	
	myCamera = [[Camera alloc] init];		// create the camera
	[myCamera initCapture];				// initialise the 
	[myCamera acquire];				// start the timer
	
	camGWorld = [myCamera pointer];

	PixMapHandle tempPixMap;
	tempPixMap=GetGWorldPixMap(camGWorld);
	LockPixels(tempPixMap);			
	camPixels = GetPixBaseAddr(tempPixMap );
}


- (void)drawRect:(NSRect)rect{

	NSImage * img = [self imageFromGworld:camGWorld];

	NSRect viewR = NSMakeRect(0, 0, rect.size.width, rect.size.height);
	NSRect camR = NSMakeRect(0, 0, WIDTH, HEIGHT);

	//[img lockFocusFlipped:false];
	[img setFlipped:true];
	[img drawInRect:viewR
		   fromRect:camR
		  operation:NSCompositeCopy
		   fraction:1.0
	 respectFlipped:false
			  hints: @{NSImageHintInterpolation: [NSNumber numberWithInt:NSImageInterpolationLow]}
	 ];


//	CopyBits(GetPortBitMapForCopyBits(camGWorld),
//	GetPortBitMapForCopyBits(myport),
//	&myRect,
//	&myRect,
//	srcCopy,
//	NULL);

}


-(void) refresh{
	
	myTimer = [NSTimer scheduledTimerWithTimeInterval:REFRESH target:self selector:@selector(refresh) userInfo:nil repeats:NO];
   [self setNeedsDisplay:YES];

}


- (void) capture{

	//myCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:CAPTURE target:self selector:@selector(capture) userInfo:nil repeats:NO];

//	NSBitmapImageRep *bmRep;
//	[textOverlay lockFocus];
//	bmRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect: [textOverlay bounds]];
//	[textOverlay unlockFocus];
//	NSImage * textOverlayImg = [[NSImage alloc] initWithSize:[textOverlay frame].size];

	NSImage * img = [self imageFromGworld:camGWorld];
	NSRect crect = NSMakeRect(0,0,WIDTH, HEIGHT);

	[img lockFocus];

	NSImage * overlayImg = [overlay image];
	NSPoint p = NSMakePoint(WIDTH - [overlayImg size].width, 0);
	[overlayImg drawAtPoint:p fromRect:crect operation:NSCompositeSourceOver fraction:1.0];

	NSBitmapImageRep *tempfile = [[NSBitmapImageRep alloc] initWithFocusedViewRect:crect];
	NSData *imageData = [tempfile representationUsingType:NSJPEGFileType properties: 
		[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat: JPEG], NSImageCompressionFactor, nil]
	];

	[img unlockFocus];

	NSBundle *appBundle = [NSBundle mainBundle];
	NSString *basePath = [[appBundle bundlePath] stringByDeletingLastPathComponent];
	
	NSString *file = [[NSString alloc] initWithFormat: @"/image.jpg"];	
	NSString *myDataPath = [basePath stringByAppendingString:file];

	[imageData writeToFile:myDataPath atomically:YES];

	[tempfile release];
	[file release];
	//[textOverlayImg release];

}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication{
	return YES;
}


- (NSImage*) imageFromGworld:(GWorldPtr) gworld;{

	// PixMapHandleを取得します
	PixMapHandle    pixMapH;
	pixMapH = GetGWorldPixMap(gworld);

	// PixMapHandleをロックします
	if (!LockPixels(pixMapH)) {
		return nil;
	}

	// PixMapHandleの情報を取得します
	Rect    portRect;
	int     pixelsWide;
	int     pixelsHigh;
	void*   baseAddr;
	long    rowBytes;
	GetPortBounds(gworld, &portRect);
	pixelsWide = portRect.right - portRect.left;
	pixelsHigh = portRect.bottom - portRect.top;
	baseAddr = GetPixBaseAddr(pixMapH);
	rowBytes = GetPixRowBytes(pixMapH);

	// Source画像を作成します
	CGColorSpaceRef     srcColorSpaceRef;
	CGDataProviderRef   dataProviderRef;
	CGImageRef          srcImageRef;
	srcColorSpaceRef = CGColorSpaceCreateDeviceRGB();
	dataProviderRef = CGDataProviderCreateWithData(
												   NULL, baseAddr, rowBytes * pixelsHigh, NULL);
	srcImageRef = CGImageCreate(
								pixelsWide,
								pixelsHigh,
								8,
								32,
								rowBytes,
								srcColorSpaceRef,
								kCGImageAlphaPremultipliedFirst,
								dataProviderRef,
								NULL,
								NO,
								kCGRenderingIntentDefault);

	// 空のNSBitmapImageのインスタンスを作成します
	NSBitmapImageRep*   bitmapImageRep;
	bitmapImageRep = [[[NSBitmapImageRep alloc]
					   initWithBitmapDataPlanes:NULL
					   pixelsWide:pixelsWide
					   pixelsHigh:pixelsHigh
					   bitsPerSample:8
					   samplesPerPixel:4
					   hasAlpha:YES
					   isPlanar:NO
					   colorSpaceName:NSDeviceRGBColorSpace
					   bytesPerRow:NULL
					   bitsPerPixel:NULL] autorelease];

	// Destinationのコンテキストを作成します
	CGColorSpaceRef     dstColorSpaceRef;
	CGContextRef        dstContextRef;
	dstColorSpaceRef = CGColorSpaceCreateDeviceRGB();
	dstContextRef = CGBitmapContextCreate(
            [bitmapImageRep bitmapData],
            pixelsWide,
            pixelsHigh,
            8,
            [bitmapImageRep bytesPerRow],
            dstColorSpaceRef,
            kCGImageAlphaPremultipliedLast);

	// Source画像をdestinationコンテキストに描きます
	CGContextDrawImage(
					   dstContextRef,
					   CGRectMake(0, 0, pixelsWide, pixelsHigh),
					   srcImageRef);

	// 各種データを解放します
	CGColorSpaceRelease(srcColorSpaceRef);
	CGDataProviderRelease(dataProviderRef);
	CGImageRelease(srcImageRef);
	CGColorSpaceRelease(dstColorSpaceRef);
	CGContextRelease(dstContextRef);

	// PixMapHandleをアンロックします
	UnlockPixels(pixMapH);

	// NSImageのインスタンスを作成します
	NSImage*    image;
	image = [[NSImage alloc]
			 initWithSize:NSMakeSize(pixelsWide, pixelsHigh)];
	[image addRepresentation:bitmapImageRep];
	[image autorelease];

	return image;
}

@end
