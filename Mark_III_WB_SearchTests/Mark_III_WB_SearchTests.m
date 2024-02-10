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

@interface Mark_III_WB_SearchTests : XCTestCase
@property (nonatomic, direct) NSData* bigEventsData;
@end

@implementation Mark_III_WB_SearchTests

const NSUInteger duplicationCount = 200;
const NSUInteger baseEventsCount = 10000;

- (void)setUp {
    NSDate* startDate = nil;
    NSDate* endDate = nil;
    [ViewController getStartRangeDate:&startDate endRangeDate:&endDate forDate:[NSDate new] minusYearsDelta:0 plusYearsDelta:10];

    Event* __strong* baseEvents = fetchEvents(startDate, endDate);

    NSMutableData* bigResult = [NSMutableData.alloc initWithLength:sizeof(Event*) * baseEventsCount * duplicationCount];
    void* baseAddress = bigResult.mutableBytes;
    for (NSUInteger idx = 0; idx < duplicationCount; idx++) {
        memcpy(baseAddress + idx * baseEventsCount * sizeof(Event*), (void*)baseEvents, baseEventsCount * sizeof(Event*));
    }

    self.bigEventsData = bigResult;
}

- (void)tearDown {
    self.bigEventsData = nil;
}

- (void)testPerformanceSimple {
    id<SearchEnvironment> environment = [SimpleSearchEnvironment new];
    [self basePerformanceCheckingWithEnvironment:environment];
}

- (void)basePerformanceCheckingWithEnvironment:(id<SearchEnvironment>)environment {
    const void* baseAddress = self.bigEventsData.bytes;
    NSString* sampleText = [((Event* __strong*)baseAddress)[0].title componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].firstObject;

    [self measureBlock:^{
        __block NSInteger finalCount = 0;
        XCTestExpectation* expectation = [XCTestExpectation.alloc initWithDescription:@"Waiting"];
        [ViewController performSearchText:sampleText events:(Event* __strong*)baseAddress eventsCount:baseEventsCount * duplicationCount environment:environment completion:^(NSInteger count, BOOL finished, const void *partialBytes, NSUInteger length) {
            if (!finished)
                return;

            finalCount = count;
            [expectation fulfill];
        }];

        [self waitForExpectations:@[expectation]];
        NSLog(@"Items count: %d", (int)finalCount);

        XCTAssertNotEqual(finalCount, 0);
        XCTAssertEqual(finalCount % duplicationCount, 0);
    }];
}

@end
