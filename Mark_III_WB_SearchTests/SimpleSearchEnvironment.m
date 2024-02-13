//
//  SimpleSearchEnvironment.m
//  Mark_III_WB_SearchTests
//
//  Created by developer on 10.02.2024.
//

#import "SimpleSearchEnvironment.h"

@interface SimpleSearchEnvironment ()
@property (nonatomic, direct) NSArray<dispatch_queue_t>* processingQueues;
@property (nonatomic, direct) NSUInteger currentProcessingQueue;
@end

@implementation SimpleSearchEnvironment
@synthesize reportingQueue = _reportingQueue;
@synthesize processingItemsCount = _processingItemsCount;

- (instancetype)init {
    self = [super init];

    if (nil == self)
        return nil;

    _processingItemsCount = 2500;
    _reportingQueue = dispatch_queue_create("com.mark_III_WB_SearchTests.reportingQueue", DISPATCH_QUEUE_SERIAL);

    const NSUInteger queuesCount = NSProcessInfo.processInfo.processorCount;

    NSMutableArray* array = [NSMutableArray.alloc initWithCapacity:queuesCount];
    const dispatch_queue_attr_t attributes = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, -1);
    for (NSUInteger idx = 0; idx < queuesCount; idx++) {
        [array addObject:dispatch_queue_create([NSString stringWithFormat:@"com.mark_III_WB_SearchTests.processingQueues%d", (int)idx].UTF8String, attributes)];
    }
    self.processingQueues = array;

    return self;
}

- (dispatch_queue_t)nextProcessingQueue {
    dispatch_queue_t result = self.processingQueues[self.currentProcessingQueue % self.processingQueues.count];
    self.currentProcessingQueue++;
    return result;
}

@end
