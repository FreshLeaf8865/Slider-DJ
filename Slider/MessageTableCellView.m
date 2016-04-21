//
//  MessageTableCellView.m
//  Slider
//
//  Created by Dmitry Volkov on 05.07.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import "MessageTableCellView.h"
#import "MessageTableViewController.h"

@implementation MessageTableCellView

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (IBAction)deleteMessageButtonClicked:(id)sender
{
    NSInteger row = [[_messageTextView identifier] intValue];
    [gMessageTableViewController removeMessageAtRow:row];
}

@end
