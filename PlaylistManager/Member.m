//
//  Member.m
//  PlaylistManager
//
//  Created by Zachary Jenkins on 11/18/14.
//  Copyright (c) 2014 Elliott Ding. All rights reserved.
//

#import "Member.h"
#import "Parser.h"

/*
@interface NSNetService (QNetworkAdditions)

- (BOOL)qNetworkAdditions_getInputStream:(out NSInputStream **)inputStreamPtr
                            outputStream:(out NSOutputStream **)outputStreamPtr;

@end

@implementation NSNetService (QNetworkAdditions)




- (BOOL)qNetworkAdditions_getInputStream:(out NSInputStream **)inputStreamPtr
                            outputStream:(out NSOutputStream **)outputStreamPtr
// The following works around three problems with
// -[NSNetService getInputStream:outputStream:]:
//
// o <rdar://problem/6868813> -- Currently the returns the streams with
//   +1 retain count, which is counter to Cocoa conventions and results in
//   leaks when you use it in ARC code.
//
// o <rdar://problem/9821932> -- If you create two pairs of streams from
//   one NSNetService and then attempt to open all the streams simultaneously,
//   some of the streams might fail to open.
//
// o <rdar://problem/9856751> -- If you create streams using
//   -[NSNetService getInputStream:outputStream:], start to open them, and
//   then release the last reference to the original NSNetService, the
//   streams never finish opening.  This problem is exacerbated under ARC
//   because ARC is better about keeping things out of the autorelease pool.
{
    BOOL                result;
    CFReadStreamRef     readStream;
    CFWriteStreamRef    writeStream;
    
    result = NO;
    
    readStream = NULL;
    writeStream = NULL;
    
    if ( (inputStreamPtr != NULL) || (outputStreamPtr != NULL) )
    {
        CFNetServiceRef netService;
        
        netService = CFNetServiceCreate(
                                        NULL,
                                        (__bridge CFStringRef) [self domain],
                                        (__bridge CFStringRef) [self type],
                                        (__bridge CFStringRef) [self name],
                                        0
                                        );
        if (netService != NULL)
        {
            CFStreamCreatePairWithSocketToNetService(
                                                     NULL,
                                                     netService,
                                                     ((inputStreamPtr  != nil) ? &readStream  : NULL),
                                                     ((outputStreamPtr != nil) ? &writeStream : NULL)
                                                     );
            CFRelease(netService);
        }
        
        // We have failed if the Memebr requested an input stream and didn't
        // get one, or requested an output stream and didn't get one.  We also
        // fail if the Member requested neither the input nor the output
        // stream, but we don't get here in that case.
        
        result = ! ((( inputStreamPtr != NULL) && ( readStream == NULL)) ||
                    ((outputStreamPtr != NULL) && (writeStream == NULL)));
    }
    if (inputStreamPtr != NULL) {
        *inputStreamPtr  = CFBridgingRelease(readStream);
    }
    if (outputStreamPtr != NULL) {
        *outputStreamPtr = CFBridgingRelease(writeStream);
    }
    
    return result;
}

@end


@interface Member () <NSNetServiceBrowserDelegate, NSStreamDelegate>


-(void) serverStuff;

// stuff for IB

// stuff for bindings


// private properties

// moved to public
//@property (nonatomic, strong, readwrite) NSMutableArray *services;
@property (nonatomic, strong, readwrite) NSNetServiceBrowser *  serviceBrowser;
@property (nonatomic, strong, readwrite) NSInputStream *        inputStream;
@property (nonatomic, strong, readwrite) NSOutputStream *       outputStream;
@property (nonatomic, strong, readwrite) NSMutableData *        inputBuffer;
@property (nonatomic, strong, readwrite) NSMutableData *        outputBuffer;
@property (nonatomic, strong) NSNetService *connectTo;

// forward declarations

- (void)closeStreams;

@end

@implementation Member

//@synthesize responseField = _responseField;
@synthesize services = _serviceList;

@synthesize serviceBrowser = _serviceBrowser;
@synthesize inputStream  = _inputStream;
@synthesize outputStream = _outputStream;
@synthesize inputBuffer  = _inputBuffer;
@synthesize outputBuffer = _outputBuffer;
/*
 -(void) serverStuff
 {
 Server * newServer = [[Server alloc] init];
 if ( [newServer start:@"songroom"] ) {
 NSLog(@"Started server on port %zu.", (size_t) [newServer port]);
 [[NSRunLoop currentRunLoop] run];
 } else {
 NSLog(@"Error starting server");
 }
 }
 */
/*
-(void)browserThread {
    self.serviceBrowser = [[NSNetServiceBrowser alloc] init];
    self.services = [[NSMutableArray alloc] init];
    [self.serviceBrowser setDelegate:self];  
    [self.serviceBrowser searchForServicesOfType:@"_PlayLister._tcp." inDomain:@""];
    [[NSRunLoop currentRunLoop] run];
    

}

- (void)startBrowser {
    
    [NSThread detachNewThreadSelector:@selector(browserThread) toTarget:self withObject:nil];
    
}



#pragma mark -
#pragma mark NSNetServiceBrowser delegate methods

-(void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser{
    NSLog(@"started browsing");
    
}

// We broadcast the willChangeValueForKey: and didChangeValueForKey: for the NSTableView binding to work.

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
#pragma unused(moreComing)
#pragma unused(aNetServiceBrowser)
    
    NSLog(@"found service:%@", aNetService.name);
    if (![self.services containsObject:aNetService]) {
        [self willChangeValueForKey:@"services"];
        [self.services addObject:aNetService];
        [self didChangeValueForKey:@"services"];
    }
    
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
#pragma unused(aNetServiceBrowser)
#pragma unused(moreComing)
    NSLog(@"removed service: %@", aNetService.name);
    
    if ([self.services containsObject:aNetService]) {
        [self willChangeValueForKey:@"services"];
        [self.services removeObject:aNetService];
        [self didChangeValueForKey:@"services"];
    }
}

#pragma mark -
#pragma mark Stream methods


-(void)connect{
    for(NSNetService *it in self.services){
        if([it.name isEqualToString: @"songroom"]){
            [self openStreamsToNetService: it];
            [[NSRunLoop currentRunLoop] run];
            
        }
        //[self.serviceBrowser removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
    
}

- (void)openStreamsToNetService:(NSNetService *)netService
{
    self.connectTo = netService;
    [self openStreamThread];
    //[[NSRunLoop currentRunLoop] run];


}


// try staring a thread to manage these?
- (void)openStreamThread
{
    NSLog(@"Member opening stream");
    NSInputStream * istream;
    NSOutputStream * ostream;
    
    [self closeStreams];
    
    if ([self.connectTo qNetworkAdditions_getInputStream:&istream outputStream:&ostream]) {
        self.inputStream = istream;
        self.outputStream = ostream;
        [self.inputStream  setDelegate:self];
        [self.outputStream setDelegate:self];
        //[self.inputStream  scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
       // [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.inputStream  open];
        [self.outputStream open];

    }
   // [self outputText: [Parser makeSigninString:self.username]];
    [self outputText: @"transmitted data\r\n"];
   // [[NSRunLoop currentRunLoop] run];

}

- (void)closeStreams
{
    NSLog(@"Member: closed stream");
    [self.inputStream  setDelegate:nil];
    [self.outputStream setDelegate:nil];
    [self.inputStream  close];
    [self.outputStream close];
    [self.inputStream  removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.inputStream  = nil;
    self.outputStream = nil;
    self.inputBuffer  = nil;
    self.outputBuffer = nil;
}

- (void)startOutput
{
    assert([self.outputBuffer length] != 0);
    NSLog(@"%@", _outputBuffer);
    
    NSInteger actuallyWritten = [self.outputStream write:[self.outputBuffer bytes] maxLength:[self.outputBuffer length]];
    if (actuallyWritten > 0) {
        NSLog(@"sending buffer");
          //[self.outputBuffer replaceBytesInRange:NSMakeRange(0, (NSUInteger) actuallyWritten) withBytes:NULL length:0];
        // If we didn't write all the bytes we'll continue writing them in response to the next
        // has-space-available event.
    } else {
        NSLog(@"send unsuccessful");
        // handle errors here
        //[self closeStreams];
    }
}

- (void)outputText:(NSString *)text
{
    self.inputBuffer = [[NSMutableData alloc] init];
    self.outputBuffer = [[NSMutableData alloc] init];
    NSData * dataToSend = [text dataUsingEncoding:NSUTF8StringEncoding];
    if (self.outputBuffer != nil) {
        BOOL wasEmpty = ([self.outputBuffer length] == 0);
        [self.outputBuffer appendData:dataToSend];
        if (wasEmpty) {
            [self startOutput];
        }
    }
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)streamEvent
{
    NSLog(@"Member: stream event");

    assert(aStream == self.inputStream || aStream == self.outputStream);

    switch(streamEvent) {
        case NSStreamEventOpenCompleted: {
            // We don't create the input and output buffers until we get the open-completed events.
            // This is important for the output buffer because -outputText: is a no-op until the
            // buffer is in place, which avoids us trying to write to a stream that's still in the
            // process of opening.
            NSLog(@"Member: opened stream successful");
            //if (aStream == self.inputStream) {
            self.inputBuffer = [[NSMutableData alloc] init];
            // } else {
            self.outputBuffer = [[NSMutableData alloc] init];
            //  }
        } break;
        case NSStreamEventHasSpaceAvailable: {
            if ([self.outputBuffer length] != 0) {
                [self startOutput];
            }
        } break;
        case NSStreamEventHasBytesAvailable: {
            NSLog(@"Member: recieved bytes");
            uint8_t buffer[2048];
            NSInteger actuallyRead = [self.inputStream read:buffer maxLength:sizeof(buffer)];
            NSLog(@"Member: server sending stuff: %ld bytes", (long)actuallyRead);
            if (actuallyRead > 0) {
                [self.inputBuffer appendBytes:buffer length: (NSUInteger)actuallyRead];
                // If the input buffer ends with CR LF, show it to the user.
               // if ([self.inputBuffer length] >= 2 && memcmp((const char *) [self.inputBuffer bytes] + [self.inputBuffer length] - 2, "\r\n", 2) == 0) {
                    NSString *string = [[NSString alloc] initWithData:self.inputBuffer encoding:NSUTF8StringEncoding];
                    if (string == nil) {
                        NSLog(@"response not UTF-8");
                    } else {
                        NSLog(@"actually proccessed stuff successfully");
                        NSLog(@"%@", string);
                    }
                    [self.inputBuffer setLength:0];
               // }
            } else {
                // A non-positive value from -read:maxLength: indicates either end of file (0) or
                // an error (-1).  In either case we just wait for the corresponding stream event
                // to come through.
            }
        } break;
        case NSStreamEventErrorOccurred:
        case NSStreamEventEndEncountered: {
            [self closeStreams];
        } break;
        default:
            break;
    }
}

// we will verify server side that the vote is legitimate
-(void) Vote:(NSString *)songURI withDirection:(int)upDown
{
    NSString *vote = [Parser makeVoteString:self.username updown:upDown songURI: songURI];
    [self outputText:vote];
}
// Either queue should include the username or vote should not
// this should be consistant. also, it can be inferred by the server so
// it is unneccesary

-(void)QueueSong:(NSString *)songURI{
    NSString *queueRequest = [Parser makeQueueString:songURI];
    [self outputText:queueRequest];
}

*/


@interface NSNetService (QNetworkAdditions)

- (BOOL)qNetworkAdditions_getInputStream:(out NSInputStream **)inputStreamPtr
                            outputStream:(out NSOutputStream **)outputStreamPtr;

@end

@implementation NSNetService (QNetworkAdditions)




- (BOOL)qNetworkAdditions_getInputStream:(out NSInputStream **)inputStreamPtr
                            outputStream:(out NSOutputStream **)outputStreamPtr
// The following works around three problems with
// -[NSNetService getInputStream:outputStream:]:
//
// o <rdar://problem/6868813> -- Currently the returns the streams with
//   +1 retain count, which is counter to Cocoa conventions and results in
//   leaks when you use it in ARC code.
//
// o <rdar://problem/9821932> -- If you create two pairs of streams from
//   one NSNetService and then attempt to open all the streams simultaneously,
//   some of the streams might fail to open.
//
// o <rdar://problem/9856751> -- If you create streams using
//   -[NSNetService getInputStream:outputStream:], start to open them, and
//   then release the last reference to the original NSNetService, the
//   streams never finish opening.  This problem is exacerbated under ARC
//   because ARC is better about keeping things out of the autorelease pool.
{
    BOOL                result;
    CFReadStreamRef     readStream;
    CFWriteStreamRef    writeStream;
    
    result = NO;
    
    readStream = NULL;
    writeStream = NULL;
    
    if ( (inputStreamPtr != NULL) || (outputStreamPtr != NULL) )
    {
        CFNetServiceRef netService;
        
        netService = CFNetServiceCreate(
                                        NULL,
                                        (__bridge CFStringRef) [self domain],
                                        (__bridge CFStringRef) [self type],
                                        (__bridge CFStringRef) [self name],
                                        0
                                        );
        if (netService != NULL)
        {
            CFStreamCreatePairWithSocketToNetService(
                                                     NULL,
                                                     netService,
                                                     ((inputStreamPtr  != nil) ? &readStream  : NULL),
                                                     ((outputStreamPtr != nil) ? &writeStream : NULL)
                                                     );
            CFRelease(netService);
        }
        
        // We have failed if the client requested an input stream and didn't
        // get one, or requested an output stream and didn't get one.  We also
        // fail if the client requested neither the input nor the output
        // stream, but we don't get here in that case.
        
        result = ! ((( inputStreamPtr != NULL) && ( readStream == NULL)) ||
                    ((outputStreamPtr != NULL) && (writeStream == NULL)));
    }
    if (inputStreamPtr != NULL) {
        *inputStreamPtr  = CFBridgingRelease(readStream);
    }
    if (outputStreamPtr != NULL) {
        *outputStreamPtr = CFBridgingRelease(writeStream);
    }
    
    return result;
}

@end


@interface Member () <NSNetServiceBrowserDelegate, NSStreamDelegate>


-(void) serverStuff;

// stuff for IB

// stuff for bindings


// private properties


@property (nonatomic, strong, readwrite) NSNetServiceBrowser *  serviceBrowser;
@property (nonatomic, strong, readwrite) NSInputStream *        inputStream;
@property (nonatomic, strong, readwrite) NSOutputStream *       outputStream;
@property (nonatomic, strong, readwrite) NSMutableData *        inputBuffer;
@property (nonatomic, strong, readwrite) NSMutableData *        outputBuffer;

// forward declarations

- (void)closeStreams;

@end

@implementation Member

//@synthesize responseField = _responseField;
@synthesize services = _serviceList;

@synthesize serviceBrowser = _serviceBrowser;
@synthesize inputStream  = _inputStream;
@synthesize outputStream = _outputStream;
@synthesize inputBuffer  = _inputBuffer;
@synthesize outputBuffer = _outputBuffer;
/*
 -(void) serverStuff
 {
 Server * newServer = [[Server alloc] init];
 if ( [newServer start:@"songroom"] ) {
 NSLog(@"Started server on port %zu.", (size_t) [newServer port]);
 [[NSRunLoop currentRunLoop] run];
 } else {
 NSLog(@"Error starting server");
 }
 }
 */

- (void) browserThread {
    self.serviceBrowser = [[NSNetServiceBrowser alloc] init];
    self.services = [[NSMutableArray alloc] init];
    [self.serviceBrowser setDelegate:self];
    // [self.serviceBrowser scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    
    [self.serviceBrowser searchForServicesOfType:@"_PlayLister._tcp." inDomain:@"local."];
    [self.serviceBrowser scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] run];
    
    
}

- (void)startBrowser {
    [NSThread detachNewThreadSelector:@selector(browserThread) toTarget:self withObject:nil];
    
}



#pragma mark -
#pragma mark NSNetServiceBrowser delegate methods

-(void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser{
    NSLog(@"started browsing");
    
}

// We broadcast the willChangeValueForKey: and didChangeValueForKey: for the NSTableView binding to work.

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
#pragma unused(moreComing)
#pragma unused(aNetServiceBrowser)
    
    NSLog(@"found service:%@", aNetService.name);
    if (![self.services containsObject:aNetService]) {
        [self willChangeValueForKey:@"services"];
        [self.services addObject:aNetService];
        [self didChangeValueForKey:@"services"];
    }
    /*if([aNetService.name isEqualToString: self.connectTo]){
     [self openStreamsToNetService:aNetService];
     [self.serviceBrowser removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
     
     }*/
    
}
-(void)connect{
    for(NSNetService *it in self.services){
        if([it.name isEqualToString: self.connectTo]){
            [self openStreamsToNetService: it];
            [[NSRunLoop currentRunLoop] run];
            
        }
        //[self.serviceBrowser removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
    
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
#pragma unused(aNetServiceBrowser)
#pragma unused(moreComing)
    NSLog(@"removed service: %@", aNetService.name);
    
    if ([self.services containsObject:aNetService]) {
        [self willChangeValueForKey:@"services"];
        [self.services removeObject:aNetService];
        [self didChangeValueForKey:@"services"];
    }
}

#pragma mark -
#pragma mark Stream methods

- (void)openStreamsToNetService:(NSNetService *)netService {
    NSInputStream * istream;
    NSOutputStream * ostream;
    
    [self closeStreams];
    // [self.serviceBrowser removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    if ([netService qNetworkAdditions_getInputStream:&istream outputStream:&ostream]) {
        self.inputStream = istream;
        self.outputStream = ostream;
        [self.inputStream  setDelegate:self];
        [self.outputStream setDelegate:self];
        [self.inputStream  scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.inputStream  open];
        [self.outputStream open];
        self.inputBuffer = [[NSMutableData alloc] init];
        self.outputBuffer = [[NSMutableData alloc] init];
        //[[NSRunLoop currentRunLoop] run];
    }
    [self outputText: @"single client\r\n"];
    
}

- (void)closeStreams {
    NSLog(@"Member: closed stream");
    [self.inputStream  setDelegate:nil];
    [self.outputStream setDelegate:nil];
    [self.inputStream  close];
    [self.outputStream close];
    [self.inputStream  removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.inputStream  = nil;
    self.outputStream = nil;
    self.inputBuffer  = nil;
    self.outputBuffer = nil;
}

- (void)startOutput
{
    assert([self.outputBuffer length] != 0);
    
    NSInteger actuallyWritten = [self.outputStream write:[self.outputBuffer bytes] maxLength:[self.outputBuffer length]];
    if (actuallyWritten > 0) {
        //  [self.outputBuffer replaceBytesInRange:NSMakeRange(0, (NSUInteger) actuallyWritten) withBytes:NULL length:0];
        // If we didn't write all the bytes we'll continue writing them in response to the next
        // has-space-available event.
    } else {
        // A non-positive result from -write:maxLength: indicates a failure of some form; in this
        // simple app we respond by simply closing down our connection.
        [self closeStreams];
    }
}

- (void)outputText:(NSString *)text
{
    NSData * dataToSend = [text dataUsingEncoding:NSUTF8StringEncoding];
    if (self.outputBuffer != nil) {
        
        BOOL wasEmpty = ([self.outputBuffer length] == 0);
        [self.outputBuffer appendData:dataToSend];
        if (wasEmpty) {
            [self startOutput];
        }
    }
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)streamEvent {
    assert(aStream == self.inputStream || aStream == self.outputStream);
    switch(streamEvent) {
        case NSStreamEventOpenCompleted: {
            // We don't create the input and output buffers until we get the open-completed events.
            // This is important for the output buffer because -outputText: is a no-op until the
            // buffer is in place, which avoids us trying to write to a stream that's still in the
            // process of opening.
            NSLog(@"Client: opened stream successful");
            //if (aStream == self.inputStream) {
            self.inputBuffer = [[NSMutableData alloc] init];
            // } else {
            self.outputBuffer = [[NSMutableData alloc] init];
            //  }
        } break;
        case NSStreamEventHasSpaceAvailable: {
            if ([self.outputBuffer length] != 0) {
                [self startOutput];
            }
        } break;
        case NSStreamEventHasBytesAvailable: {
            uint8_t buffer[2048];
            NSInteger actuallyRead = [self.inputStream read:buffer maxLength:sizeof(buffer)];
            NSLog(@"Client: server sending stuff: %ld bytes", (long)actuallyRead);
            if (actuallyRead > 0) {
                [self.inputBuffer appendBytes:buffer length: (NSUInteger)actuallyRead];
                // If the input buffer ends with CR LF, show it to the user.
                if ([self.inputBuffer length] >= 2){// && memcmp((const char *) [self.inputBuffer bytes] + [self.inputBuffer length] - 2, "\r\n", 2) == 0) {
                    NSString *string = [[NSString alloc] initWithData:self.inputBuffer encoding:NSUTF8StringEncoding];
                    if (string == nil) {
                        NSLog(@"response not UTF-8");
                    } else {
                        NSLog(@"%@", string);
                    }
                    [self.inputBuffer setLength:0];
                }
            } else {
                // A non-positive value from -read:maxLength: indicates either end of file (0) or
                // an error (-1).  In either case we just wait for the corresponding stream event
                // to come through.
            }
        } break;
        case NSStreamEventErrorOccurred:
        case NSStreamEventEndEncountered: {
            [self closeStreams];
        } break;
        default:
            break;
    }
}

// we will verify server side that the vote is legitimate
-(void) Vote:(NSString *)songURI withDirection:(int)upDown
{
    NSString *vote = [Parser makeVoteString:self.username updown:upDown songURI: songURI];
    [self outputText:vote];
}
// Either queue should include the username or vote should not
// this should be consistant. also, it can be inferred by the server so
// it is unneccesary

-(void)QueueSong:(NSString *)songURI{
    NSString *queueRequest = [Parser makeQueueString:songURI];
    [self outputText:queueRequest];
}



@end
