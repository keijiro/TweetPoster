#import "TPAsynchronousDataFetcher.h"

@implementation TPAsynchronousDataFetcher

#pragma mark Initialization

+ (id)asynchronousFetcherWithRequest:(OAMutableURLRequest *)aRequest
                         resultBlock:(TPFetcherResultBlock)aResultBlock
                        failureBlock:(TPFetcherFailureBlock)aFailureBlock {
	return [[[TPAsynchronousDataFetcher alloc] initWithRequest:aRequest resultBlock:aResultBlock failureBlock:aFailureBlock] autorelease];
}

- (id)initWithRequest:(OAMutableURLRequest *)aRequest
          resultBlock:(TPFetcherResultBlock)aResultBlock
         failureBlock:(TPFetcherFailureBlock)aFailureBlock {
	if ((self = [super init])) {
		request = [aRequest retain];
        resultBlock = Block_copy(aResultBlock);
        failureBlock = Block_copy(aFailureBlock);
	}
	return self;
}

#pragma mark Public methods

- (void)start {
    [request prepare];
	
	if (connection) [connection release];
	
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
	if (connection) {
		if (responseData) [responseData release];
		responseData = [[NSMutableData data] retain];
	} else {
        OAServiceTicket *ticket = [[OAServiceTicket alloc] initWithRequest:request response:nil didSucceed:NO];
    	failureBlock(ticket, nil);
		[ticket release];
	}
}

- (void)cancel {
	if (connection) {
		[connection cancel];
		[connection release];
		connection = nil;
	}
}

#pragma mark Cleanup

- (void)dealloc {
	if (request) [request release];
	if (connection) [connection release];
	if (response) [response release];
	if (responseData) [responseData release];
    if (resultBlock) Block_release(resultBlock);
    if (failureBlock) Block_release(failureBlock);
	[super dealloc];
}

#pragma mark -
#pragma mark NSURLConnection methods

- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSURLResponse *)aResponse {
	if (response) [response release];
	response = [aResponse retain];
	[responseData setLength:0];
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data {
	[responseData appendData:data];
}

- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
	OAServiceTicket *ticket= [[OAServiceTicket alloc] initWithRequest:request response:response didSucceed:NO];
    failureBlock(ticket, error);
	[ticket release];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection
{
	OAServiceTicket *ticket = [[OAServiceTicket alloc] initWithRequest:request
															  response:response
															didSucceed:[(NSHTTPURLResponse *)response statusCode] < 400];
    resultBlock(ticket, responseData);
	[ticket release];
}

@end
