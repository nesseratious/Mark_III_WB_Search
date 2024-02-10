//
//  GlobalSearchEnvironment.m
//  Mark_III_WB_SearchTests
//
//  Created by developer on 10.02.2024.
//

#import "GlobalSearchEnvironment.h"

@interface GlobalSearchEnvironment ()
@end

@implementation GlobalSearchEnvironment
@synthesize reportingQueue = _reportingQueue;
@synthesize processingItemsCount = _processingItemsCount;

- (instancetype)init {
    self = [super init];

    if (nil == self)
        return nil;

    _processingItemsCount = 2500;
    _reportingQueue = dispatch_queue_create("com.mark_III_WB_SearchTests.reportingQueue", DISPATCH_QUEUE_SERIAL);

    return self;
}

- (dispatch_queue_t)nextProcessingQueue {
    return dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);
}

@end
