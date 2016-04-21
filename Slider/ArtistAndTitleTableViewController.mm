//
//  ArtistAndTitleTableViewController.m
//  Slider
//
//  Created by Dmitry Volkov on 29.08.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import "ArtistAndTitleTableViewController.h"
#import <tag/fileref.h>
#import <tag/tstring.h>
#import <tag/popularimeterframe.h>
#import <tag/id3v2frame.h>
#import <tag/id3v2header.h>
#import <tag/id3v1tag.h>
#import <tag/mp4file.h>
#import <tag/tag.h>
#import <tag/tmap.h>
#import <tag/tstringlist.h>
#import <tag/textidentificationframe.h>
#include <tag/id3v2tag.h>
#import "CurlHelper.h"
#import "AppDelegate.h"

ArtistAndTitleTableViewController *gArtistAndTitleTableViewController;

@implementation ArtistAndTitleTableViewController
{
    NSMutableArray* songArray;
    
    NSTimer* timeForWebRequest;
    
    
    NSUInteger lastSelectedRow;
}

@synthesize tableView;

- (void)awakeFromNib
{
    gArtistAndTitleTableViewController = self;
    
    songArray = [[NSMutableArray alloc] init];
    
    [tableView registerForDraggedTypes:[NSArray arrayWithObject:(NSString*)kUTTypeFileURL]];
    
    //timeForWebRequest = [NSTimer tim]
}


- (BOOL)tableView:(NSTableView*)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op
{
    NSPasteboard* pb = info.draggingPasteboard;
    NSArray* acceptedTypes = [NSArray arrayWithObject:(NSString*)kUTTypeAudio];
    
    NSArray* urls = [pb readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]]
                                                           options:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                    [NSNumber numberWithBool:YES],NSPasteboardURLReadingFileURLsOnlyKey,
                                                                    acceptedTypes, NSPasteboardURLReadingContentsConformToTypesKey,
                                                                    nil]];
    if(urls.count != 1)
        return NSDragOperationNone;
    
    NSString* path = [[urls objectAtIndex:0] path];
    
    TagLib::FileRef fileRef([path UTF8String]);
    
    NSString* artist = [NSString stringWithUTF8String:fileRef.tag()->artist().toCString()];
    NSString* title = [NSString stringWithUTF8String:fileRef.tag()->title().toCString()];
    
    //<------------------------------------------------------------------------------------------>
    //<==========================================================================================>
    
    [self addNewSong:artist andTitle:title andPath:path];
    
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    return NSDragOperationEvery;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [songArray count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSDictionary* dictionary = [songArray objectAtIndex:rowIndex];
    return [dictionary valueForKey:@"title"];
}

-(void) timerForWebRequestMethod
{
    
    if ([tableView selectedRow] == lastSelectedRow)
    {
        NSLog(@"Try make send web request %ld", (long)[tableView selectedRow]);
        
        NSDictionary* dictionary = [songArray objectAtIndex:[tableView selectedRow]];
        
        NSString* artist = [dictionary objectForKey:@"artist"];
        NSString* title = [dictionary objectForKey:@"title"];
        NSString* path = [dictionary objectForKey:@"path"];
        
        NSLog(@"Song info for web request-> Artist:%@, Title:%@, Path:%@",artist, title, path);
        
        NSString* partyId = [gAppDelegate currentPartyId];
        
        NSTimeInterval timeInMiliseconds = [[NSDate date] timeIntervalSince1970];
        
        NSString* time = [NSString stringWithFormat:@"%d", (int) timeInMiliseconds];
        
        gCurlHelper->postSelectedSong([partyId UTF8String],
                                      [artist UTF8String],
                                      [title UTF8String],
                                      [path UTF8String],
                                      [time UTF8String]);
    }
}


- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    NSLog(@"current row %d, last row %d", [tableView selectedRow], lastSelectedRow);
    
    //if ([tableView selectedRow] != lastSelectedRow)
    //{
        [timeForWebRequest invalidate];
        timeForWebRequest = nil;
        
        lastSelectedRow = [tableView selectedRow];
        
        timeForWebRequest = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                           target:self
                                                           selector:@selector(timerForWebRequestMethod)
                                                           userInfo:nil
                                                           repeats:NO];
    //}
}


-(void) addNewSong:(NSString*)artist andTitle:(NSString*)title andPath:(NSString*)path
{
    const NSInteger maxSongs = 5;
    
    //NSString* artisAndTitle = [NSString stringWithFormat:@"%@ - %@", title, artist];
    
    if (songArray.count >= maxSongs)
    {
        [songArray removeLastObject];
    }
    
    NSMutableDictionary* dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setObject:artist forKey:@"artist"];
    [dictionary setObject:title forKey:@"title"];
    [dictionary setObject:path forKey:@"path"];
    
    [songArray insertObject:dictionary atIndex:0];
    [tableView reloadData];
}

@end
