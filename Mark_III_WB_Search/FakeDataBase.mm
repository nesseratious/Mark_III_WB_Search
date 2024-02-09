//
//  FakeDataBase.mm
//  Mark_III_WB_Search
//
//  Created by Denis Esie on 07.02.2024.
//

#include "FakeDataBase.h"
#include "Event.h"

NSDate *randomDateInRange(NSDate *start, NSDate *end);
NSString *randomTitle(void);
int comparator(const void *event1, const void *event2);

// For the simplicity of the task we assume that this function always returns 10000 items
Event * __strong * fetchEvents(NSDate *startDate, NSDate *endDate) {
    const size_t length = sizeof(Event *) * 10000;
    void* buffer = (Event * __strong *)malloc(length);
    memset(buffer, 0, length);

    Event * __strong *eventsBuffer = (Event * __strong *)buffer;

    for (NSUInteger i = 0; i < 10000; i++) {
        NSString *title = randomTitle();
        NSDate *eventStartDate = randomDateInRange(startDate, endDate);
        NSDate *eventEndDate = randomDateInRange(eventStartDate, endDate);

        auto* event = [[Event alloc] initWithTitle:title startDate:eventStartDate endDate:eventEndDate];
        eventsBuffer[i] = event;
    }
    
    qsort(eventsBuffer, 10000, sizeof(Event *), comparator);
    return eventsBuffer;
}

int comparator(const void *event1, const void *event2) {
    auto* firstEvent = *(__unsafe_unretained Event **)event1;
    auto* secondEvent = *(__unsafe_unretained Event **)event2;
    return (int)[firstEvent.startDate compare:secondEvent.startDate];
}

NSDate *randomDateInRange(NSDate *start, NSDate *end) {
    NSTimeInterval startInterval = [start timeIntervalSince1970];
    NSTimeInterval endInterval = [end timeIntervalSince1970];
    NSTimeInterval randomInterval = ((double)arc4random() / 0x100000000) * (endInterval - startInterval) + startInterval;
    return [NSDate dateWithTimeIntervalSince1970:randomInterval];
}

static auto* titleAdjectives = @[@"Amazing", @"Incredible", @"Extraordinary", @"Fun", @"Mysterious", @"Exciting", @"Creative", @"Innovative"];
static auto* titleNouns = @[@"Conference", @"Workshop", @"Seminar", @"Symposium", @"Retreat", @"Festival", @"Concert", @"Gathering"];

NSString *randomTitle(void) {
    NSString *adjective = titleAdjectives[arc4random_uniform((uint32_t)titleAdjectives.count)];
    NSString *noun = titleNouns[arc4random_uniform((uint32_t)titleNouns.count)];
    return [NSString stringWithFormat:@"%@ %@", adjective, noun];
}
