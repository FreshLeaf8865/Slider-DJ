//
//  SelectPathWindowController.m
//  Slider
//
//  Created by Dmitry Volkov on 28.07.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import "SelectPathWindowController.h"
#import "CurlHelper.h"
#import "AppDelegate.h"
#import <tag/fileref.h>
#import <tag/tstring.h>
#import <tag/popularimeterframe.h>

@implementation SelectPathWindowController
{
    NSMutableArray* directoryArray;
    NSMutableArray* jsonDictionaryArray;
    NSMutableArray* statesArray;
    NSInvocationOperation* searchingSongsOperation;
    NSOperationQueue* queue;
    
    
    //NSMutableArray* existingFilesStatesArray;
    NSMutableArray* filesForAddToCollectionArray;
    NSMutableArray* existingFilesInCollectionArray;
}

@synthesize filesForAddToCollectionTableView;
@synthesize existingFilesTableView;
@synthesize searchSongField;

-(void) updateExistingSongsCounter
{
    [self.songsCountExisting setIntValue:(int)[existingFilesInCollectionArray count]];
}

-(void) updateNewSongsCounter
{
    [self.songsCountNew setIntValue:(int)[filesForAddToCollectionArray count]];
}

-(id) initWithWindowNibName:(NSString*) windowNibName
{
    self = [super initWithWindowNibName:windowNibName];
    
    directoryArray = [[NSMutableArray alloc] init];
    statesArray = [[NSMutableArray alloc] init];
    jsonDictionaryArray = [[NSMutableArray alloc] init];
    queue = [NSOperationQueue new];
    
    filesForAddToCollectionArray = [[NSMutableArray alloc] init];
   // existingFilesInCollection = [[NSMutableArray alloc] init];
    gCurlHelper->reset();
    std::string buffer = gCurlHelper->inventoryJSON([[gAppDelegate currentPartyId]UTF8String]).c_str();
    
    NSLog(@"Path %s", buffer.c_str());

    NSData* jsonData = [NSData dataWithBytes:buffer.c_str() length:buffer.length()];
    
    if (!jsonData)
    {
        NSLog(@"Error");
    }
    
    NSError *error = nil;
    
   // existingFilesStatesArray = [[NSMutableArray alloc] init];
    
    
    
   // NSMutableArray *jsonDictionary
    
    existingFilesInCollectionArray = //[[NSMutableArray alloc] init];
    
    [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    
    NSLog(@"Ex files %lu ", (unsigned long)existingFilesInCollectionArray.count);
    
    
    [existingFilesTableView setDoubleAction:@selector(doubleClickInTableView:)];
    
    return self;
}

- (void)setSortDescriptors:(NSArray *)array
{
    NSLog(@"SSSS");
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if ([[aTableView identifier] isEqualToString:@"FileForAddToCollectionTable"])
    {
        return  [filesForAddToCollectionArray count];
    }
    
    if ([[aTableView identifier] isEqualToString:@"ExistingFilesTable"])
    {
        return [existingFilesInCollectionArray count];
    }
    
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSDictionary* dictionary;
    
    if([[aTableView identifier] isEqualToString:@"FileForAddToCollectionTable"])
    {
        dictionary = [filesForAddToCollectionArray objectAtIndex:rowIndex];
        
        if([[aTableColumn identifier] isEqualToString:@"Title"])
        {
            return [dictionary valueForKey:@"title"];
        }
        
        if([[aTableColumn identifier] isEqualToString:@"Artist"])
        {
            return [dictionary valueForKey:@"artist"];
        }
        
        if([[aTableColumn identifier] isEqualToString:@"Filepath"])
        {
            
            return [dictionary valueForKey:@"filename"];
        }
    }
    
    if([[aTableView identifier] isEqualToString:@"ExistingFilesTable"])
    {
        dictionary = [existingFilesInCollectionArray objectAtIndex:rowIndex];
        
        if([[aTableColumn identifier] isEqualToString:@"Title"])
        {
            return [dictionary valueForKey:@"title"];
        }
        
        if([[aTableColumn identifier] isEqualToString:@"Artist"])
        {
            return [dictionary valueForKey:@"artist"];
        }
        
        if([[aTableColumn identifier] isEqualToString:@"Filepath"])
        {
            return [dictionary valueForKey:@"filename"];
        }
    }
    
    return nil;
}

-(void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange: (NSArray *)oldDescriptors
{
    if([[aTableView identifier] isEqualToString:@"FileForAddToCollectionTable"])
    {
        NSArray *newDescriptors = [filesForAddToCollectionTableView sortDescriptors];
        [filesForAddToCollectionArray sortUsingDescriptors:newDescriptors];
        [filesForAddToCollectionTableView reloadData];
    }
    
    if([[aTableView identifier] isEqualToString:@"ExistingFilesTable"])
    {
        NSArray *newDescriptors = [existingFilesTableView sortDescriptors];
        [existingFilesInCollectionArray sortUsingDescriptors:newDescriptors];
        [existingFilesTableView reloadData];
    }
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row
{
}

-(void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
    NSLog(@"DDDD");
    
}



- (IBAction)addPathButtonClicked:(id)sender
{
    NSOpenPanel* selectPanel = [NSOpenPanel openPanel];
    
    selectPanel.title = @"Select directory for searhing mp3 files";
    selectPanel.showsResizeIndicator = YES;
    selectPanel.showsHiddenFiles = NO;
    selectPanel.canChooseDirectories = YES;
    selectPanel.canChooseFiles = NO;
    selectPanel.allowsMultipleSelection = NO;
    
    [selectPanel setPrompt:@"Select"];
    [selectPanel runModal];
    
    NSURL *directoryURL = [selectPanel URL];
    
    searchingSongsOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(operationMethodForSearchingFiles:) object:directoryURL];
    [queue addOperation:searchingSongsOperation];
}

- (IBAction)selectAllFilesForAddToCollection:(id)sender
{
    [filesForAddToCollectionTableView selectAll:self];
}
- (IBAction)unselectAllFilesForAddToCollection:(id)sender
{
    [filesForAddToCollectionTableView deselectAll:self];
}

- (IBAction)selectAllFileInCollection:(id)sender
{
    [existingFilesTableView selectAll:self];
}

- (IBAction)unselectAllFilesInCollection:(id)sender
{
    [existingFilesTableView deselectAll:self];
}

- (IBAction)removeSelectedetFilesFromAddToCollection:(id)sender
{
    NSIndexSet* selectedRowIndexes = [filesForAddToCollectionTableView selectedRowIndexes];
    [filesForAddToCollectionArray removeObjectsAtIndexes:selectedRowIndexes];
    [filesForAddToCollectionTableView reloadData];
    [self updateNewSongsCounter];
}

- (IBAction)removeSelectedFilesFromCollection:(id)sender
{
    NSIndexSet* selectedRowIndexes = [existingFilesTableView selectedRowIndexes];
    [existingFilesInCollectionArray removeObjectsAtIndexes:selectedRowIndexes];
    [existingFilesTableView reloadData];
    [self updateExistingSongsCounter];
}

- (IBAction)addToCollectionSelectedFiles:(id)sender
{
//    NSIndexSet* selectedRowIndexes = [filesForAddToCollectionTableView selectedRowIndexes];
//    
//    [selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
//     {
//         NSDictionary* dictionry = [filesForAddToCollectionArray objectAtIndex:idx];
//         [existingFilesInCollectionArray addObject:dictionry];
//     }];
    
    
    [existingFilesInCollectionArray addObjectsFromArray:filesForAddToCollectionArray];
    
    [existingFilesTableView reloadData];
    [self updateExistingSongsCounter];
}


- (IBAction)searchSongFieldEditing:(id)sender
{
    
}

- (IBAction)uploadButtonClicked:(id)sender
{

//    NSIndexSet* selectedRowIndexes = [existingFilesTableView selectedRowIndexes];
    NSMutableArray* selectedFiles = [[NSMutableArray alloc] init];
//    
//    [selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
//     {
//         NSDictionary* dictionry = [ existingFilesInCollectionArray objectAtIndex:idx];
//         [selectedFiles addObject:dictionry];
//     }];
    
    selectedFiles = existingFilesInCollectionArray;

    NSError *error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:selectedFiles
                                                       options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [jsonString writeToFile:@"inventory.json" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    
    if (error)
    {
        NSLog(@"Genereate json file error file: %s, line: %d", __FILE__, __LINE__);
    }
   
    gCurlHelper->uploadSongs([[gAppDelegate currentPartyId] UTF8String]);
    
    [self.window close];
    [gAppDelegate.window orderFrontRegardless];
}

- (IBAction)cancelButtonClicked:(id)sender
{
    [self.window close];
    [gAppDelegate.window orderFrontRegardless];
}

-(BOOL) isSongFileExtension:(NSString*)pathExtension
{
    // Add here other files extensions for allow songs window(middle window) accept relate songs format
    
    //NSLog(@"Path extension %@", pathExtension);
    
    if ([pathExtension isEqualToString:@"mp3"])
        return YES;
    
    if ([pathExtension isEqualToString:@"m4a"])
         return YES;
    
    if ([pathExtension isEqualToString:@"aif"])
        return YES;
    
    if ([pathExtension isEqualToString:@"wav"])
        return YES;
    
    if ([pathExtension isEqualToString:@"wma"])
        return YES;
    
    if ([pathExtension isEqualToString:@"flac"])
        return YES;
    
    if ([pathExtension isEqualToString:@"ogg"])
        return YES;
    
    return NO;
}

-(void) operationMethodForSearchingFiles:(NSURL*) directoryURL
{
    //for (NSURL *directoryURL in directoryArray)
    //{
         NSFileManager *fileManager = [[NSFileManager alloc] init];
         NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    
         NSDirectoryEnumerator *enumerator = [fileManager
         enumeratorAtURL:directoryURL
         includingPropertiesForKeys:keys
         options:0
         errorHandler:^(NSURL *url, NSError *error){
         // Handle the error.
         // Return YES if the enumeration should continue after the error.
             return YES;
         }];
    
         for (NSURL *url in enumerator)
         {
             
             NSError *error;
             NSNumber *isDirectory = nil;
             if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error])
             {
                 // handle error
             }
             else if ((![isDirectory boolValue]) &&  [self isSongFileExtension:[url pathExtension]])
             {
                 NSMutableDictionary* dictionary = [[NSMutableDictionary alloc]init];
                 
                 //********************** MUST BE FIXED:fileRef return null ptr for .ogg & .wma file formats **********//
                 TagLib::FileRef fileRef([[url path]UTF8String]);
                 
                 TagLib::Tag* tag = fileRef.tag();
                 NSLog(@"File: %@", [url path]);
                 [dictionary setObject:[url path] forKey:@"filename"];
                 
                 if (tag)
                 {

                     NSString* str;

                     str = [NSString stringWithUTF8String:tag->artist().to8Bit(true).c_str()];
                     [dictionary setObject:str forKey:@"artist"];

                     str = [NSString stringWithUTF8String:tag->title().to8Bit(true).c_str()];
                     [dictionary setObject:str forKey:@"title"];

                     dispatch_async(dispatch_get_main_queue(), ^{
            //             [existingFilesTableView reloadData];
            //             [existingFilesTableView.window update];
                         [filesForAddToCollectionTableView reloadData];
                         [filesForAddToCollectionTableView.window update];
                         [self updateNewSongsCounter];
                     });
                 }
                
                 [filesForAddToCollectionArray addObject:dictionary];
             }
         }
    //}
}

@end
