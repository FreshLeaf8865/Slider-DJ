//
//  TableViewController.h
//  Slider
//
//  Created by Dmitry Volkov on 15.03.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "JSONArray.h"

@interface SongsTableViewController : NSObject<NSTableViewDataSource, NSTableViewDelegate>

@property (weak)  IBOutlet NSTableView *tableView;
@property (strong) JSONArray *jsonArray;

-(void) reloadJSONFile:(NSString*)path;

-(void) updateSongsList:(const char*) str;

@end

extern SongsTableViewController* gSongsTableViewController;
