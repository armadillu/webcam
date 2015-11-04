////////////
//  Camera.m
////////////////////////////
//  Generic Sequence Grabber
////////////////////////////////////////////////
//  Created by David Towey - dave@oxidise.com.au
////////////////////////////////////////////////////////
////////////////////////////////////////////////////////

#import "Camera.h"
#include "stuff.h"

SeqGrabComponent 			mySGC;
SGChannel					vChan, sChan;
Boolean						active,paused,gQuit,record;
EventHandlerRef 			evHRef;
NSString					*ptr_FileName;
int							*ptr_NbClip;
Camera						*globalController;
Rect						myRect;

VideoDigitizerComponent		myVDC;
UserData					mySGVideoSettings; // myvideo settings user data

@implementation Camera

/////////////////////////
//Initialise the capture
/////////////////////////

- (void)initCapture
{ 
    
	w = WIDTH;
	h = HEIGHT;
	
	MacSetRect(&myRect,0,0,w,h);
	mySGVideoSettings = NULL;
    
	mySGC = [self MakeSequenceGrabber]; // create the sequence grabber
	inKey = CFSTR("sgVideoSettings");
	
	if(mySGC){
	
	    int result = [self MakeGrabChannels:mySGC theVideoChan:&vChan theRect:&myRect record:true];
	    if(!result)
	    {
		//SGStartPreview(mySGC);
			    SGStartPreview(mySGC);
		active = TRUE;
	    }
	}
	
	PixMapHandle videoPixmap;       
	videoPixmap=GetGWorldPixMap(myvideogworld);                                 
	myvideoBaseAddress = GetPixBaseAddr(videoPixmap );

}


//////////////////////////////////
// Creation of the sequence grabber
//////////////////////////////////

- (SeqGrabComponent) MakeSequenceGrabber
{

	OSErr err;
    SeqGrabComponent anSG;
    ComponentDescription theDesc;
	Component sgCompID;
	
	NewGWorld ( &myvideogworld, 24, &myRect, nil, nil,0 );
	
	anSG = 0L;                                                                                                                  
	theDesc.componentType = SeqGrabComponentType;                                 
	theDesc.componentSubType = 0L;                                                
	theDesc.componentManufacturer = 0L; 
    theDesc.componentFlags = 0L;                                                  
    theDesc.componentFlagsMask = 0L;                                              
    sgCompID = FindNextComponent(NULL, &theDesc);  
	if (sgCompID != 0L)                                
    anSG = OpenComponent(sgCompID); 
	
    if(anSG)
    {
        err = SGInitialize(anSG);
        if(err == noErr)
        {	
			
			err = SGSetGWorld(anSG,myvideogworld, nil);
        }else {
			NSAlert *alert = [[NSAlert alloc] init];
			[alert addButtonWithTitle:@"OK"];
			[alert setMessageText:@"No Camera Connected!"];
			[alert setAlertStyle:NSCriticalAlertStyle];
			[alert runModal];
			[alert release];
			exit(0);
		}			
    }
        
    if(err && anSG)
    {
        CloseComponent(anSG);
        anSG = nil;
    }
        
    return anSG;
}

//////////////////////
//Create the channels
//////////////////////

- (int)MakeGrabChannels:(SeqGrabComponent) anSG theVideoChan:(SGChannel *) videoChannel theRect:(Rect *) bounds record:(Boolean) willRecord

{
    OSErr err;
    long usage;
    
    usage = seqGrabPreview;
    if(willRecord)
        usage |= seqGrabRecord;
		err = SGNewChannel(anSG,VideoMediaType,videoChannel);

        if(err == noErr)
        {
            err = SGSetChannelBounds(*videoChannel,bounds);

            if(err == noErr)
                err = SGSetChannelUsage(*videoChannel,usage | seqGrabPlayDuringRecord);
            else
                return -1;

            if(err)
            {
                SGDisposeChannel(anSG,*videoChannel);
                *videoChannel = nil;
                return -1;
            }
        }
        else
            return -1;
			

        return 0;
}


///////////////////////
// Timer
///////////////////////

- (void)acquire{
    myTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(refresh) userInfo:nil repeats:YES];
} 



///////////////////////
// Refresh
///////////////////////

- (void)refresh
{
	
    if((active) && (paused != seqGrabPause))
        SGIdle(mySGC);
    if(gQuit)
        [myTimer invalidate];
    if(!active)
        [self initCapture];

}

/////////////////////////////////
// Return the pixel base address
/////////////////////////////////

- (Ptr)base
{

return myvideoBaseAddress;

}

/////////////////////////////////
// Return the pointer to the gworld
/////////////////////////////////

- (GWorldPtr)pointer;
{

return myvideogworld;

}


////////////////////////////////////////
// Call the Quicktime Settings Dialogue 
////////////////////////////////////////

- (void) settings {


[self GetSettingsPreference];

//VDRestoreSettingsFromUserData(myVDC,mySGVideoSettings,0);

if (mySGVideoSettings) {
  
  // use the saved settings preference to configure the SGChannel
	SGSetChannelSettings(mySGC, vChan, mySGVideoSettings, 0);

}


SGSettingsDialog(mySGC, vChan, 0, 0, seqGrabSettingsPreviewOnly, 0, 0);

// get the SGChannel settings cofigured by the user
SGGetChannelSettings(mySGC, vChan, &mySGVideoSettings, 0);

// save the settings using the key "sgVideoSettings" 
[self SaveSettingsPreference];

//VDSaveSettingstoUserData(myVDC,mySGVideoSettings,0);

// clean up after yourself
DisposeUserData(mySGVideoSettings);

}

///////////////////////////////
// Save the Quicktime Settings 
///////////////////////////////

- (void) SaveSettingsPreference
{

	CFDataRef theCFSettings;
	Handle    hSettings;
	OSErr     err;

	// if (NULL == inUserData) return paramErr;

    hSettings = NewHandle(0);
	err = MemError();

    if (noErr == err) {
		err = PutUserDataIntoHandle(mySGVideoSettings, hSettings); 

		if (noErr == err) {
			HLock(hSettings);
				
				theCFSettings = CFDataCreate(kCFAllocatorDefault,
                                   (UInt8 *)*hSettings,
                                   GetHandleSize(hSettings));
      if (theCFSettings) {

        CFPreferencesSetAppValue(inKey, theCFSettings,
                                 kCFPreferencesCurrentApplication);


		CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);

        CFRelease(theCFSettings);

      }

    }


    DisposeHandle(hSettings);

  }
}

///////////////////////////
// GetSettingsPreference
// Returns a preference for a specified key as QuickTime UserData
// It is your responsibility to dispose of the returned UserData
///////////////////////////

- (void) GetSettingsPreference

{

  CFPropertyListRef theCFSettings;

	Handle            theHandle = NULL;
	UserData          theUserData = NULL;
	OSErr             err = paramErr;



  // read the new setttings from our preferences
//CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);


  theCFSettings = CFPreferencesCopyAppValue(inKey,
                                         kCFPreferencesCurrentApplication);
CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);

  if (theCFSettings) {
    err = PtrToHand(CFDataGetBytePtr((CFDataRef)theCFSettings), &theHandle,
                    CFDataGetLength((CFDataRef)theCFSettings));

        

    CFRelease(theCFSettings);

    if (theHandle) {

      err = NewUserDataFromHandle(theHandle, &mySGVideoSettings);

      if (theUserData) {
        mySGVideoSettings = theUserData;
		SGSetChannelSettings(mySGC, vChan, mySGVideoSettings, 0);
		
      }

      DisposeHandle(theHandle);

    }

  }

}



@end