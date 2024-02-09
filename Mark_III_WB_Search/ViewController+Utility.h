//
//  ViewController+Utility.h
//  Mark_III_WB_Search
//
//  Created by developer on 10.02.2024.
//

#import <Foundation/Foundation.h>

typedef void (^TextSearchCompletion)(NSInteger count, BOOL finished, const void* partialBytes, NSUInteger length);

@protocol SearchEnvironment
@property (nonatomic) dispatch_queue_t reportingQueue;
- (dispatch_queue_t)nextProcessingQueue;
@end

@interface ViewController (Utility)
+ (void)getStartRangeDate:(NSDate**)start endRangeDate:(NSDate**)end forDate:(NSDate*)date minusYearsDelta:(NSInteger)minusYearsDelta plusYearsDelta:(NSInteger)plusYearsDelta;
+ (void)filterEventsInRange:(NSRange)range searchText:(NSString*)text events:(Event* __strong*)events resultIndexes:(NSMutableData*)resultIndexes;
+ (void)performSearchText:(NSString* )text events:(Event* __strong*)events eventsCount:(NSInteger)eventsCount environment:(id<SearchEnvironment>)environment completion: (TextSearchCompletion)completion;
@end

static const NSInteger searchDeltaInYears = 10;
static const NSInteger startMinusSearchDeltaInYears = 5;
static const NSInteger startPlusSearchDeltaInYears = 5;
