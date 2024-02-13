//
//  ViewController+Utility.h
//  Mark_III_WB_Search
//
//  Created by developer on 10.02.2024.
//

#import <Foundation/Foundation.h>
#import "ViewController.h"

typedef NS_ENUM(NSInteger, CompletionStage) {
    inProgress = 0,
    completed
};

typedef struct {
    CompletionStage stage;
    union {
        struct {
            NSInteger count;
            const void* _Nonnull bytes;
            NSUInteger bytesSize;
        } partial;
        struct {
            NSInteger count;
            NSInteger nearestEventIndex;
            NSTimeInterval nearestAbsTimeDelta;
        } final;
    } info;
} CompletionResult;

typedef void (^TextSearchCompletion)(CompletionResult result);

@protocol SearchEnvironment
@property (nonatomic, readonly) NSInteger processingItemsCount;
@property (nonatomic, readonly, nonnull) dispatch_queue_t reportingQueue;
- (_Nonnull dispatch_queue_t)nextProcessingQueue;
@end

@interface ViewController (Utility)
+ (void)getStartRangeDate:(NSDate* _Nullable*_Nullable)start endRangeDate:(NSDate* _Nullable* _Nullable)end forDate:(nonnull NSDate*)date minusYearsDelta:(NSInteger)minusYearsDelta plusYearsDelta:(NSInteger)plusYearsDelta;
+ (void)filterEventsInRange:(NSRange)range searchText:(nonnull NSString*)text definingInterval:(NSTimeInterval)definingInterval events:(Event* _Nonnull __strong* _Nonnull)events resultIndexes:(nonnull NSMutableData*)resultIndexes;
+ (void)performSearchText:(nonnull NSString* )text definingDate:(nullable NSDate*)definingDate events:(Event* _Nonnull  __strong* _Nonnull)events eventsCount:(NSInteger)eventsCount environment:(nonnull id<SearchEnvironment>)environment completion:(nonnull TextSearchCompletion)completion;
@end

static const NSInteger searchDeltaInYears = 10;
static const NSInteger startMinusSearchDeltaInYears = 5;
static const NSInteger startPlusSearchDeltaInYears = 5;

// MARK: -
NS_INLINE
CompletionResult MakeCompletionResultPartial(NSInteger count, const void* _Nonnull bytes, NSUInteger bytesSize) {
    CompletionResult result;
    result.stage = inProgress;
    result.info.partial.count = count;
    result.info.partial.bytes = bytes;
    result.info.partial.bytesSize = bytesSize;

    return result;
}

NS_INLINE
CompletionResult MakeCompletionResultFinal(NSInteger count, NSInteger nearestEventIndex, NSTimeInterval nearestAbsTimeDelta) {
    CompletionResult result;
    result.stage = completed;
    result.info.final.count = count;
    result.info.final.nearestEventIndex = nearestEventIndex;
    result.info.final.nearestAbsTimeDelta = nearestAbsTimeDelta;

    return result;
}
