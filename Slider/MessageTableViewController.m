//
//  MessageTablveViewController.m
//  Slider
//
//  Created by Dmitry Volkov on 28.06.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import "MessageTableViewController.h"
#import "MessageTableCellView.h"
#import "AppDelegate.h"

MessageTablveViewController* gMessageTableViewController = 0;

@implementation MessageTablveViewController
{
    NSMutableArray* messageArray;
    //NSLock *arrayLock;
    NSTimer* dataUpdateTimer;
}

-(id) init
{
    self = [super self];
    gMessageTableViewController = self;
    messageArray = [[NSMutableArray alloc] init];
    
    dataUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.50
                                                       target:self
                                                     selector:@selector(updateData)
                                                     userInfo:nil
                                                      repeats:YES];
    
    //arrayLock = [[NSLock alloc] init];
    
    return self;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [self countOfMessages];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    MessageTableCellView *cellView = [tableView makeViewWithIdentifier:@"MessageCell" owner:self];
    cellView.backgroundStyle = NSBackgroundStyleDark;
    cellView.messageTextView.string= [messageArray objectAtIndex:row];
    cellView.messageTextView.identifier = [NSString stringWithFormat:@"%ld", (long)row];
    return cellView;
}

-(void) updateData
{
    [_tableView reloadData];
    _countOfMessagesField.stringValue = [NSString stringWithFormat:@"%ld", (long)[self countOfMessages]];
}

-(void)addNewMessage:(NSString*)messageString
{
    //[arrayLock lock];
    [messageArray addObject:messageString];
    //[arrayLock unlock];
}

-(void)removeMessageAtRow:(NSInteger)row
{
    //[arrayLock lock];
    [messageArray removeObjectAtIndex:row];
    //[arrayLock unlock];
}

-(NSInteger) countOfMessages
{
    //NSInteger count = [messageArray count];
    return [messageArray count];
}


@end
