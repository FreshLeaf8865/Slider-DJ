//
//  MessageTableCellView.h
//  Slider
//
//  Created by Dmitry Volkov on 05.07.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MessageTableCellView : NSTableCellView

@property (unsafe_unretained) IBOutlet NSTextView *messageTextView;


@end
