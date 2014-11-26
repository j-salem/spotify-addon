//
//  PlaylistTableViewController.m
//  PlaylistManager
//
//  Created by Elliott Ding on 11/25/14.
//  Copyright (c) 2014 Elliott Ding. All rights reserved.
//

#import "PlaylistTableViewController.h"

#import "SongTableViewCell.h"

#import "PlaylistTableView.h"

#import "PlaylistNavigationController.h"

#import "SongView.h"

@interface PlaylistTableViewController ()

@end

@implementation PlaylistTableViewController

- (instancetype)initWithSongQueue:(SongQueue *)songQueue
{
    self = [super init];
    if (self)
    {
        self.songQueue = songQueue;
        [self setupAddButton];
        self.title = @"Playlist";
    }
    return self;
}

- (void)setupAddButton
{
    PlaylistNavigationController *nav = (PlaylistNavigationController *)self.navigationController;
    UIBarButtonItem *addButton;
    addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                              target:nav
                                                              action:@selector(pushSearchViewController)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    // TODO: The below doesn't work, not sure why
    // [self setToolbarItems:@[addButton] animated:NO];
}

- (void)reloadView
{
    [self.tableView reloadData];
}

- (void)loadView
{
    CGRect tableViewFrame = [[UIScreen mainScreen] applicationFrame];
    PlaylistTableView *ptv = [[PlaylistTableView alloc] initWithFrame:tableViewFrame
                                                                style:UITableViewStylePlain];
    ptv.delegate = self;
    ptv.dataSource = self;
    [ptv reloadData];
    self.view = ptv;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Register the cell class for a reuse identifier
    [self.tableView registerClass:[SongTableViewCell class] forCellReuseIdentifier:@"SongCell"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

// Two sections: first for preferred queue, second for regular queue
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return self.songQueue.preferredQueue.songs.count;
    }
    else if (section == 1)
    {
        return self.songQueue.songs.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdentifier = @"SongCell";
    SongTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier
                                                              forIndexPath:indexPath];
    
    // Initialize a new cell if one was not dequeued
    if (cell == nil)
    {
        cell = [[SongTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                        reuseIdentifier:reuseIdentifier];
    }
    
    // Set the song of the cell
    Song *song;
    if (indexPath.section == 0)
    {
        song = self.songQueue.preferredQueue.songs[indexPath.row];
    }
    else if (indexPath.section == 1)
    {
        song = self.songQueue.songs[indexPath.row];
    }
    else
    {
        [NSException raise:@"Index error" format:@"indexPath section %ld is invalid", indexPath.section];
    }

    // NSArray *sectionTrackIdentifiers = self.trackIdentifiers[indexPath.section];
    // NSString *trackIdentifier = sectionTrackIdentifiers[indexPath.row];
    
    //SongView *songView = [[SongView alloc] initWithSong:song frame:];
    //[cell.contentView addSubview:songView];
    // [cell loadTrackWithIdentifier:trackIdentifier];
    
    cell.song = song;
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return @"Preferred Queue";
    }
    else
    {
        return @"Regular Queue";
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Song *selectedSong;
    if (indexPath.section == 0)
    {
        selectedSong = self.songQueue.preferredQueue.songs[indexPath.item];
    }
    else if (indexPath.section == 1)
    {
        selectedSong = self.songQueue.songs[indexPath.item];
    }
    PlaylistNavigationController *pnc = (PlaylistNavigationController *)self.navigationController;
    [pnc pushSongDetailViewControllerWithSong:selectedSong];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
