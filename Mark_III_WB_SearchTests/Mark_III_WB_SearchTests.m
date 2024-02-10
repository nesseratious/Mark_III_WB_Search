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
#import "SimpleSearchEnvironment.h"
#import "ConcurrentSearchEnvironment.h"
#import "GlobalSearchEnvironment.h"

@interface Mark_III_WB_SearchTests : XCTestCase
@end

@implementation Mark_III_WB_SearchTests

const NSUInteger duplicationCount = 200;
const NSUInteger baseEventsCount = 10000;

static NSData* bigEventsData = nil;
static NSDate* definingDate = nil;

+ (void)setUp {
    NSDate* startDate = nil;
    NSDate* endDate = nil;
    [ViewController getStartRangeDate:&startDate endRangeDate:&endDate forDate:[NSDate new] minusYearsDelta:0 plusYearsDelta:10];

    Event* __strong* baseEvents = fetchEvents(startDate, endDate);

    NSMutableData* bigResult = [NSMutableData.alloc initWithLength:sizeof(Event*) * baseEventsCount * duplicationCount];
    void* baseAddress = bigResult.mutableBytes;
    for (NSUInteger idx = 0; idx < duplicationCount; idx++) {
        memcpy(baseAddress + idx * baseEventsCount * sizeof(Event*), (void*)baseEvents, baseEventsCount * sizeof(Event*));
    }

    bigEventsData = bigResult;
    definingDate = NSDate.date;
}

+ (void)tearDown {
    bigEventsData = nil;
}

- (void)testPerformanceSimple {
    id<SearchEnvironment> environment = [SimpleSearchEnvironment new];
    [self basePerformanceCheckingWithEnvironment:environment];
}

- (void)testPerformanceConcurrent {
    id<SearchEnvironment> environment = [ConcurrentSearchEnvironment new];
    [self basePerformanceCheckingWithEnvironment:environment];
}

- (void)testPerformanceGlobal {
    id<SearchEnvironment> environment = [GlobalSearchEnvironment new];
    [self basePerformanceCheckingWithEnvironment:environment];
}

- (void)basePerformanceCheckingWithEnvironment:(id<SearchEnvironment>)environment {
    const void* baseAddress = bigEventsData.bytes;
    NSString* sampleText = [((Event* __strong*)baseAddress)[0].title componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].firstObject;

    [self measureBlock:^{
        __block NSInteger finalCount = 0;
        __block NSInteger nearestEventIndex = -1;
        __block NSTimeInterval nearestAbsTimeDelta = DBL_MAX;

        XCTestExpectation* expectation = [XCTestExpectation.alloc initWithDescription:@"Waiting"];
        [ViewController performSearchText:sampleText definingDate:definingDate events:(Event* __strong*)baseAddress eventsCount:baseEventsCount * duplicationCount environment:environment completion:^(CompletionResult result) {
            if (completed != result.stage)
                return;

            finalCount = result.info.final.count;
            nearestEventIndex = result.info.final.nearestEventIndex;
            nearestAbsTimeDelta = result.info.final.nearestAbsTimeDelta;

            [expectation fulfill];
        }];

        [self waitForExpectations:@[expectation]];
        NSLog(@"Items count: %d; nearest event index: %d (time abs delta is %f)", (int)finalCount, (int)nearestEventIndex, (0 < nearestEventIndex) ? nearestAbsTimeDelta : -1.0);

        XCTAssertNotEqual(finalCount, 0);
        XCTAssertEqual(finalCount % duplicationCount, 0);

        XCTAssertNotEqual(nearestEventIndex, -1);
    }];
}

@end
