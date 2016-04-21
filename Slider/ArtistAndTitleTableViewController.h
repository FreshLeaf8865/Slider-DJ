//
//  ArtistAndTitleTableViewController.h
//  Slider
//
//  Created by Dmitry Volkov on 29.08.15.
//  Copyright (c) 2015 Automatic System Metering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface ArtistAndTitleTableViewController : NSObject<NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTableView *tableView;

-(void) addNewSong:(NSString*) artist andTitle:(NSString*)title andPath:(NSString*)path;


@end

extern ArtistAndTitleTableViewController* gArtistAndTitleTableViewController;
