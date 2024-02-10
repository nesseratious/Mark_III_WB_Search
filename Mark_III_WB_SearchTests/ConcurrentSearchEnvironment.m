//
//  ConcurrentSearchEnvironment.m
//  Mark_III_WB_SearchTests
//
//  Created by developer on 10.02.2024.
//

#import "ConcurrentSearchEnvironment.h"

@interface ConcurrentSearchEnvironment ()
@property (nonatomic, direct) NSArray<dispatch_queue_t>* processingQueues;
@property (nonatomic, direct) dispatch_queue_t concurrentQueue;
@property (nonatomic, direct) NSUInteger currentProcessingQueue;
@end

@implementation ConcurrentSearchEnvironment
@synthesize reportingQueue = _reportingQueue;
@synthesize processingItemsCount = _processingItemsCount;

- (instancetype)init {
    self = [super init];

    if (nil == self)
        return nil;

    _processingItemsCount = 2500;
    _reportingQueue = dispatch_queue_create("com.mark_III_WB_SearchTests.loadingQueue", DISPATCH_QUEUE_SERIAL);

    const dispatch_queue_attr_t concurrentAttributes = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT, QOS_CLASS_USER_INITIATED, -1);
    self.concurrentQueue = dispatch_queue_create("com.mark_III_WB_SearchTests.concurrentQueue", concurrentAttributes);

    const NSUInteger queuesCount = NSProcessInfo.processInfo.processorCount;

    NSMutableArray* array = [NSMutableArray.alloc initWithCapacity:queuesCount];
    const dispatch_queue_attr_t attributes = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, -1);
    for (NSUInteger idx = 0; idx < queuesCount; idx++) {
        dispatch_queue_t queue = dispatch_queue_create([NSString stringWithFormat:@"com.mark_III_WB_SearchTests.processingQueues%d", (int)idx].UTF8String, attributes);
        dispatch_set_target_queue(queue, self.concurrentQueue);

        [array addObject:queue];
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
