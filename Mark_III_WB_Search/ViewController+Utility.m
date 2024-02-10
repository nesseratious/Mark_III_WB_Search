//
//  ViewController+Utility.m
//  Mark_III_WB_Search
//
//  Created by developer on 10.02.2024.
//

#import "ViewController.h"
#import "ViewController+Utility.h"
#import "Event.h"

@implementation ViewController (Utility)

+ (void)getStartRangeDate:(NSDate* _Nullable*_Nullable)start endRangeDate:(NSDate* _Nullable* _Nullable)end forDate:(nonnull NSDate*)date minusYearsDelta:(NSInteger)minusYearsDelta plusYearsDelta:(NSInteger)plusYearsDelta {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:date];

    const NSInteger thisYear = [components valueForComponent:NSCalendarUnitYear];
    components.calendar = calendar;

    if (NULL != end) {
        [components setValue:thisYear + plusYearsDelta - 1 forComponent:NSCalendarUnitYear];
        [components setValue:12 forComponent:NSCalendarUnitMonth];
        [components setValue:31 forComponent:NSCalendarUnitDay];
        [components setValue:23 forComponent:NSCalendarUnitHour];
        [components setValue:59 forComponent:NSCalendarUnitMinute];
        [components setValue:59 forComponent:NSCalendarUnitSecond];

        *end = components.date;
    }

    if (NULL != start) {
        [components setValue:thisYear - minusYearsDelta forComponent:NSCalendarUnitYear];
        [components setValue:1 forComponent:NSCalendarUnitMonth];
        [components setValue:1 forComponent:NSCalendarUnitDay];
        [components setValue:0 forComponent:NSCalendarUnitHour];
        [components setValue:0 forComponent:NSCalendarUnitMinute];
        [components setValue:0 forComponent:NSCalendarUnitSecond];

        *start = components.date;
    }
}

typedef struct _ResultIndexes {
    NSInteger nearestIndex;
    NSTimeInterval absTimeDelta;
    NSInteger allIndexes[1];
} ResultIndexes;

+ (void)filterEventsInRange:(NSRange)range searchText:(nonnull NSString*)text definingInterval:(NSTimeInterval)definingInterval events:(Event* _Nonnull __strong* _Nonnull)events resultIndexes:(nonnull NSMutableData*)resultIndexes {
    if (0 == range.length) { return; }
    if (NULL == events) { return; }

    [resultIndexes setLength:offsetof(ResultIndexes, allIndexes[0]) + sizeof(NSInteger) * range.length];

    NSTimeInterval absDelta = DBL_MAX;
    NSInteger nearestIndex = -1;

    NSUInteger index = 0;
    ResultIndexes* indexesArray = (ResultIndexes*)resultIndexes.mutableBytes;

    for (NSInteger idx = 0; idx < range.length; idx++) {
        const NSInteger eventIdx = range.location + idx;

        Event* event = events[eventIdx];
        const NSRange substrRange = [event.title rangeOfString:text options:NSCaseInsensitiveSearch];
        if (0 == substrRange.length) { continue; }

        const NSTimeInterval delta = fabs(event.startDate.timeIntervalSinceReferenceDate - definingInterval);
        if (delta < absDelta) {
            nearestIndex = index;
            absDelta = delta;
        }

        (*indexesArray).allIndexes[index] = eventIdx;
        index++;
    }

    (*indexesArray).nearestIndex = nearestIndex;
    (*indexesArray).absTimeDelta = absDelta;
    [resultIndexes setLength:offsetof(ResultIndexes, allIndexes[0]) + sizeof(NSInteger) * index];
}

+ (void)performSearchText:(nonnull NSString* )text definingDate:(nullable NSDate*)definingDate events:(Event* _Nonnull  __strong* _Nonnull)events eventsCount:(NSInteger)eventsCount environment:(nonnull id<SearchEnvironment>)environment completion:(nonnull TextSearchCompletion)completion {
    if (text.length == 0) {
        completion(MakeCompletionResultFinal(-1, -1, -1.0));
        return;
    }

    const NSTimeInterval definingTimeInterval = ((nil != definingDate) ? definingDate : [NSDate new]).timeIntervalSinceReferenceDate;

    const NSInteger processingItemsCount = MIN(environment.processingItemsCount, eventsCount);
    const NSUInteger rangesCount = (eventsCount + processingItemsCount - 1) / processingItemsCount;

    NSMutableArray<NSData*>* result = [NSMutableArray.alloc initWithCapacity:rangesCount];

    dispatch_group_t group = dispatch_group_create();
    for (NSUInteger idx = 0; idx < rangesCount; idx++) {
        dispatch_group_enter(group);

        NSMutableData* chunk = [NSMutableData new];
        [result addObject:chunk];

        dispatch_async(environment.nextProcessingQueue, ^{
            const NSInteger location = idx * processingItemsCount;
            const NSRange range = NSMakeRange(location, (idx + 1 < rangesCount) ? processingItemsCount : eventsCount - location);
            [ViewController filterEventsInRange:range searchText:text definingInterval:definingTimeInterval events:events resultIndexes:chunk];

            dispatch_group_leave(group);
        });
    }

    dispatch_async(environment.reportingQueue, ^{
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

        NSUInteger index = 0;
        NSInteger nearestEventIndex = -1;
        NSTimeInterval nearestDelta = DBL_MAX;

        for (NSInteger idx = 0; idx < result.count; idx++) {
            NSData* subIndexes = [result objectAtIndex:idx];
            const NSUInteger length = subIndexes.length - offsetof(ResultIndexes, allIndexes[0]);

            if (0 == length) { continue; }

            ResultIndexes const* resultIndexes = (ResultIndexes const*)subIndexes.bytes;

            if ((*resultIndexes).absTimeDelta < nearestDelta) {
                nearestDelta = (*resultIndexes).absTimeDelta;
                nearestEventIndex = index + (*resultIndexes).nearestIndex;
            }

            index += length / sizeof(NSInteger);
            completion(MakeCompletionResultPartial(index, (*resultIndexes).allIndexes, length));
        }

        completion(MakeCompletionResultFinal(index, nearestEventIndex, nearestDelta));
    });
}

@end
