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

+ (void)getStartRangeDate:(NSDate**)start endRangeDate:(NSDate**)end forDate:(NSDate*)date minusYearsDelta:(NSInteger)minusYearsDelta plusYearsDelta:(NSInteger)plusYearsDelta {
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

+ (void)filterEventsInRange:(NSRange)range searchText:(NSString*)text events:(Event* __strong*)events resultIndexes:(NSMutableData*)resultIndexes {
    if (0 == range.length) { return; }
    if (NULL == events) { return; }

    [resultIndexes setLength:sizeof(NSInteger) * range.length];

    NSUInteger index = 0;
    NSInteger* indexesArray = (NSInteger*)resultIndexes.mutableBytes;

    for (NSInteger idx = 0; idx < range.length; idx++) {
        const NSInteger eventIdx = range.location + idx;

        Event* event = events[eventIdx];
        const NSRange substrRange = [event.title rangeOfString:text options:NSCaseInsensitiveSearch];
        if (0 == substrRange.length) { continue; }

        indexesArray[index] = eventIdx;
        index++;
    }

    [resultIndexes setLength:sizeof(NSInteger) * index];
}

+ (void)performSearchText:(NSString* )text events:(Event* __strong*)events eventsCount:(NSInteger)eventsCount environment:(id<SearchEnvironment>)environment completion: (TextSearchCompletion)completion {
    if (text.length == 0) {
        completion(-1, TRUE, NULL, 0);
        return;
    }

    const NSUInteger queuesCount = NSProcessInfo.processInfo.processorCount;
    const NSInteger width = eventsCount / queuesCount;

    NSMutableArray<NSData*>* result = [NSMutableArray.alloc initWithCapacity:queuesCount];

    dispatch_group_t group = dispatch_group_create();
    for (NSUInteger idx = 0; idx < queuesCount; idx++) {
        dispatch_group_enter(group);

        NSMutableData* chunk = [NSMutableData new];
        [result addObject:chunk];

        dispatch_async(environment.nextProcessingQueue, ^{
            const NSInteger location = idx * width;
            const NSRange range = NSMakeRange(location, (idx + 1 < queuesCount) ? width : eventsCount - location);
            [ViewController filterEventsInRange:range searchText:text events:events resultIndexes:chunk];

            dispatch_group_leave(group);
        });
    }

    dispatch_async(environment.reportingQueue, ^{
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

        NSUInteger index = 0;

        for (NSInteger idx = 0; idx < result.count; idx++) {
            NSData* subIndexes = [result objectAtIndex:idx];
            const NSUInteger length = [subIndexes length];

            if (0 == length) { continue; }

            index += length / sizeof(NSInteger);
            completion(index, FALSE, subIndexes.bytes, length);
        }

        completion(index, TRUE, NULL, 0);
    });
}

@end
