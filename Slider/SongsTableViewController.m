//
//  TableViewController.m
//  Slider
//
//  Created by Dmitry Volkov on 15.03.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import "SongsTableViewController.h"
#include "AppDelegate.h"

SongsTableViewController* gSongsTableViewController = NULL;

@implementation SongsTableViewController
{
    //NSString* jsonString;
}

- (void)awakeFromNib
{
    gSongsTableViewController = self;
    [_tableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
}

- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row
{
    return _jsonArray.jsonArray[row];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [_jsonArray count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    JSONItem* jsonItem = [_jsonArray itemAtIndex:rowIndex];
    NSString* itemString = [NSString stringWithFormat:@"%@ - %@", [jsonItem artist], [jsonItem title]];
    return itemString;//[item title];
}

-(void) updateSongsList:(const char *) str
{
    _jsonArray = [JSONArray jsonArrayFromCString:str];
    [_tableView reloadData];
}

-(void) reloadJSONFile:(NSString*)path
{
    //_jsonArray = [JSONArray jsonArrayFromFile:path];
    //[_tableView reloadData];
}

-(void) updateDataEvent
{
    
}

@end
