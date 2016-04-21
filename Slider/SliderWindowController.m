//
//  SliderWindowController.m
//  Slider
//
//  Created by Dmitry Volkov on 05.03.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import "SliderWindowController.h"
#import "AppDelegate.h"

extern AppDelegate* gAppDelegate;

@interface SliderWindowController ()
{
    float screenWidth;
    NSRect windowFrame;
    NSPoint mouseLocation;
}

@property (readwrite) NSThread* wathThread;

@end

@implementation SliderWindowController

@synthesize isVisible;
@synthesize side;
@synthesize isFirstShow;
@synthesize panelWidth;

-(id)initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];
    
    const float divideCoeff = 6.0;
    
    NSScreen* screen = [NSScreen mainScreen];
    screenWidth = screen.frame.size.width;
    panelWidth = screenWidth/divideCoeff;
    
    float screenHeight = screen.frame.size.height;
    
    windowFrame.size.height = screenHeight - screenHeight*0.1;
    windowFrame.size.width = panelWidth;
    windowFrame.origin.x = screenWidth/2.0;
    windowFrame.origin.y = screenHeight;
    
    [self.window setMaxSize:NSMakeSize(screenWidth/2.5, screenHeight - screenHeight*0.1)];
    [self.window setMinSize:NSMakeSize(screenWidth/10.0, screenHeight - screenHeight*0.1)];
    
    [self.window setMovable:NO];
    [self setIsVisible:NO];
    
    return self;
}

-(void) showWindowAndStick
{
    if (defLeftSide == [self side])
    {
        windowFrame.origin.x = 0.0;
    }
    else if (defRightSide == [self side])
    {
        windowFrame.origin.x = screenWidth - panelWidth;
    }
    
    if (isFirstShow)
    {
        [self.window setAlphaValue:0.0];
        isFirstShow = NO;
    }
    else
    {
        [self.window setAlphaValue:1.0];
    }
    
    [self setIsVisible:YES];
    [self.window setFrame:windowFrame display:YES animate:YES];
    [self.window makeKeyAndOrderFront:self];
    [self.window orderFrontRegardless];
}

-(void) moveWindowAndHide
{
    panelWidth = self.window.frame.size.width;
    windowFrame.size.width = panelWidth;
    
    if ([self side] == defLeftSide)
         windowFrame.origin.x = 1.0 - panelWidth;
    else if ([self side] == defRightSide)
        windowFrame.origin.x = screenWidth - 1.0;
    
   [self setIsVisible:NO];
   [self.window setFrame:windowFrame display:YES animate:YES];
   [self.window setAlphaValue:0.0];
}

-(BOOL) isMouseInAreaForShow;
{
    if (mouseLocation.x >= 0.0f && mouseLocation.x <= 1.0f && side == defLeftSide)
        return YES;
    
    if (mouseLocation.x >= screenWidth - 1.0f && side == defRightSide)
        return YES;
    
    return NO;
}

-(BOOL) isMouseInAreaForHide
{
    if (mouseLocation.x > panelWidth && defLeftSide == side)
        return YES;
    
    if (mouseLocation.x < screenWidth - panelWidth && defRightSide == side)
        return YES;
    
    return NO;
}

-(void) updateMouseLocation
{
    mouseLocation = [NSEvent mouseLocation];
}

-(void) updatePanelWidth
{
    panelWidth = self.window.frame.size.width;
}

-(void) startSliderThread
{
    if (_wathThread && [_wathThread isExecuting])
    {
        [_wathThread cancel];
    }
    else
    {
        _wathThread = [[NSThread alloc] initWithTarget:self selector:@selector(threadMethod) object:nil];
        [_wathThread start];
    }
}

-(void) stopSliderThread
{
    [_wathThread cancel];
}

-(void) threadMethod
{
    const float sleepTimeOut = 0.25;
    const short maxTicks = 1.0/sleepTimeOut;
    short currentTicks = maxTicks;
    
    [NSThread setThreadPriority:1.0];
    
    /***We call this method befor run loop to suppress bug when sliding window first show at display***/
    [self setIsFirstShow:YES];
    [self performSelectorOnMainThread:@selector(showWindowAndStick)
                                              withObject:nil
                                            waitUntilDone:YES];
    //-----------------------------------------------------------------------------------------------//
    
    while (![_wathThread isCancelled])
    {
        
//        if ([NSEvent pressedMouseButtons] == 1)
//        {
//            currentTicks = 0;
//            [self updatePanelWidth];
//            [NSThread sleepForTimeInterval:sleepTimeOut];
//            continue;
//        }
        
        [self updateMouseLocation];
        
        [NSThread sleepForTimeInterval:sleepTimeOut];
        if ([self isMouseInAreaForShow] && ![self isVisible])
        {
            currentTicks = 0;
            [self setIsVisible:YES];
            [self performSelectorOnMainThread:@selector(showWindowAndStick)
                                                      withObject:nil
                                                   waitUntilDone:YES];
        }
        else if ([self isMouseInAreaForHide] && [self isVisible])
        {
            if (currentTicks < maxTicks)
            {
                currentTicks++;
                continue;
            }
            
            [self setIsVisible:NO];
            [self performSelectorOnMainThread:@selector(moveWindowAndHide)
                                                      withObject:nil
                                                   waitUntilDone:YES];
        } else if ([self isVisible] && ![self isMouseInAreaForHide] )
        {
            // we accumulate ticks without this and eventually moving the mouse out of the panel just for a fraction of a second would be enough to make it hide
            currentTicks = 0;
        }
    }
}

- (IBAction)backButtonPressed:(id)sender
{
    [self stopSliderThread];
    [self close];
    [self moveWindowAndHide];
    [gAppDelegate closeSlider];
}

@end
