//
//  SongRoomTests.m
//  Playlist Manager
//
//  Created by Mark Landgrebe on 11/4/14.
//
//

#import <UIKit/UIKit.h>

#import <XCTest/XCTest.h>

#import "SongRoom.h"

#import "User.h"

@interface SongRoomTests : XCTestCase
{
    SongRoom *r;
    SongRoom *r2;
    User *user1;
    User *user2;
}

@end

@implementation SongRoomTests

- (void)setUp
{
    [super setUp];
    r = [[SongRoom alloc] initWithName:@"songroom"];
    r2 = [[SongRoom alloc] initWithName:@"songroom2"];
    user1 = [[User alloc] initWithUsername:@"user1"];
    user2 = [[User alloc] initWithUsername:@"user2"];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)test_initWithName
{
    XCTAssertEqualObjects(@"songroom", r.name, @"name not correctly initialized");
    XCTAssertNotNil(r.songQueue, @"SongQueue should not be nil after initialization");
}

- (void)test_containsUser
{
    XCTAssertFalse([r containsUser:user1], @"returned true before user1 was registered");
    [r registerUser:user1];
    XCTAssert([r containsUser:user1], @"returned false after user1 was registered");
    XCTAssertFalse([r containsUser:user2], @"returned true before user2 was registered");
}

- (void)test_containsUsername
{
    XCTAssertFalse([r containsUsername:@"user1"], @"returned true before user1 was registered");
    [r registerUser:user1];
    XCTAssert([r containsUsername:@"user1"], @"returned false after user1 was registered");
    XCTAssertFalse([r containsUsername:@"user2"], @"returned true before user2 was registered");
}

- (void)test_registerUser
{
    [r registerUser:user1];
    XCTAssert([r containsUsername:@"user1"], @"returned false after user1 was registered");
    
    XCTAssertEqualObjects(r, user1.songRoom, @"registered user's song room property is incorrect");
    
    [r2 registerUser:user1];
    XCTAssert([r2 containsUsername:@"user1"], @"returned false after user1 was registered");
    XCTAssertEqualObjects(r2, user1.songRoom, @"registered user's song room property is incorrect");
    // This is correct behavior
    // XCTAssertFalse([r containsUser:user1], @"first song room still contains a user that was registered to a different song room");
}

- (void)test_unregisterUser
{
    [r registerUser:user1];
    [r unregisterUser:user1];
    XCTAssertFalse([r containsUser:user1], @"returned true after user1 was unregistered");
    
    [r unregisterUser:user2];
    XCTAssertFalse([r containsUser:user2], @"returned true even though user2 is unregistered");
    
    XCTAssertNil(user1.songRoom, @"user1's song room was not properly set to nil after unregistration");
}

- (void)test_unregisterUsername
{
    [r registerUser:user1];
    [r unregisterUsername:@"user1"];
    XCTAssertFalse([r containsUsername:@"user1"], @"returned true after user1 was unregistered");
    
    [r unregisterUsername:@"user2"];
    XCTAssertFalse([r containsUsername:@"user2"], @"returned true even though user2 is unregistered");
}

- (void)test_userWithUsername
{
    [r registerUser:user1];
    XCTAssertEqualObjects(user1, [r userWithUsername:@"user1"], @"user1 objects do not match");
    XCTAssertNil([r userWithUsername:@"user2"], @"user2 user not nil even though not registered in SongRoom");
}

@end
