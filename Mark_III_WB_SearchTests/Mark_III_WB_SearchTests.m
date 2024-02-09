//
//  Mark_III_WB_SearchTests.m
//  Mark_III_WB_SearchTests
//
//  Created by developer on 09.02.2024.
//

#import <XCTest/XCTest.h>
#import "Event.h"
#import "ViewController.h"
#import "ViewController+Utility.h"
#import "FakeDataBase.h"

@interface Mark_III_WB_SearchTests : XCTestCase
@end

@interface SimpleSearchEnvironment: NSObject<SearchEnvironment>
@property (nonatomic, direct) dispatch_queue_t loadingQueue;
@property (nonatomic, direct) NSArray<dispatch_queue_t>* processingQueues;
@property (nonatomic, direct) NSUInteger currentProcessingQueue;
@end

@implementation Mark_III_WB_SearchTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testPerformanceExample {
    const NSUInteger duplicationCount = 200;
    const NSUInteger baseEventsCount = 10000;

    NSDate* startDate = nil;
    NSDate* endDate = nil;
    [ViewController getStartRangeDate:&startDate endRangeDate:&endDate forDate:[NSDate new] minusYearsDelta:0 plusYearsDelta:10];

    Event* __strong* baseEvents = fetchEvents(startDate, endDate);

    NSMutableData* bigResult = [NSMutableData.alloc initWithLength:sizeof(Event*) * baseEventsCount * duplicationCount];
    void* baseAddress = bigResult.mutableBytes;
    for (NSUInteger idx = 0; idx < duplicationCount; idx++) {
        memcpy(baseAddress + idx * baseEventsCount * sizeof(Event*), (void*)baseEvents, baseEventsCount * sizeof(Event*));
    }

    NSString* sampleText = [((Event* __strong*)baseAddress)[0].title componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].firstObject;
    SimpleSearchEnvironment* environment = [SimpleSearchEnvironment new];

    [self measureBlock:^{
        XCTestExpectation* expectation = [XCTestExpectation.alloc initWithDescription:@"Waiting"];
        [ViewController performSearchText:sampleText events:(Event* __strong*)baseAddress eventsCount:baseEventsCount * duplicationCount environment:environment completion:^(NSInteger count, BOOL finished, const void *partialBytes, NSUInteger length) {
            if (!finished)
                return;

            NSLog(@"Items count: %d", (int)count);
            [expectation fulfill];
        }];

        [self waitForExpectations:@[expectation]];
    }];
}

@end

// MARK: -

@implementation SimpleSearchEnvironment

- (instancetype)init {
    self = [super init];

    if (nil == self)
        return nil;

    self.loadingQueue = dispatch_queue_create("com.mark_III_WB_SearchTests.loadingQueue", DISPATCH_QUEUE_SERIAL);

    const NSUInteger queuesCount = NSProcessInfo.processInfo.processorCount / 2;

    NSMutableArray* array = [NSMutableArray.alloc initWithCapacity:queuesCount];
    const dispatch_queue_attr_t attributes = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, -1);
    for (NSUInteger idx = 0; idx < queuesCount; idx++) {
        [array addObject:dispatch_queue_create([NSString stringWithFormat:@"com.mark_III_WB_SearchTests.processingQueues%d", (int)idx].UTF8String, attributes)];
    }
    self.processingQueues = array;

    return self;
}

@synthesize reportingQueue;

- (dispatch_queue_t)reportingQueue {
    return self.loadingQueue;
}

- (dispatch_queue_t)nextProcessingQueue {
    dispatch_queue_t result = self.processingQueues[self.currentProcessingQueue % self.processingQueues.count];
    self.currentProcessingQueue++;
    return result;
}

@end
