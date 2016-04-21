//
//  SliderWindowController.h
//  Slider
//
//  Created by Dmitry Volkov on 05.03.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import <Cocoa/Cocoa.h>


#define defUnknownSide (0)
#define defLeftSide (1)
#define defRightSide (2)

@interface SliderWindowController : NSWindowController

@property(readwrite) BOOL isVisible;
@property(readwrite) BOOL isFirstShow;
@property(readwrite) int side;
@property (readwrite) float panelWidth;

-(void) showWindowAndStick;
-(void) moveWindowAndHide;

-(BOOL) isMouseInAreaForShow;
-(BOOL) isMouseInAreaForHide;

-(void) updatePanelWidth;
-(void) updateMouseLocation;

-(void) startSliderThread;
-(void) stopSliderThread;


@end

