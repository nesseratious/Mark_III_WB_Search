//
//  ViewController.mm
//  Mark_III_WB_Search
//
//  Created by Denis Esie on 07.02.2024.
//

#import "ViewController.h"
#import "FakeDataBase.h"
#import "Event.h"
#import <list>

static const NSInteger searchDeltaInYears = 10;
static const NSInteger startMinusSearchDeltaInYears = 5;
static const NSInteger startPlusSearchDeltaInYears = 5;

@interface ViewController ()

@property (nonatomic, direct) UITableView *tableView;
@property (nonatomic, direct) UISearchBar *searchBar;
@property (nonatomic, direct) Event * __strong * events;
@property (nonatomic, direct) NSInteger eventCount;

@property (nonatomic, direct) dispatch_queue_t loadingQueue;

@property (nonatomic, direct) NSMutableData* filteredIndexes;
@property (nonatomic, direct) NSInteger filteredIndexesCount;

@property (nonatomic, direct) NSArray<dispatch_queue_t>* processingQueues;
@property (nonatomic, direct) NSUInteger threadsCount;

@end

@implementation ViewController
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

- (void)filterEventsInRange:(NSRange)range searchText:(NSString*)text resultIndexes:(NSMutableData*)resultIndexes {
    if (0 == range.length) { return; }

    [resultIndexes setLength:sizeof(NSInteger) * range.length];

    NSUInteger index = 0;
    NSInteger* indexesArray = (NSInteger*)resultIndexes.mutableBytes;

    for (NSInteger idx = 0; idx < range.length; idx++) {
        const NSInteger eventIdx = range.location + idx;

        Event* event = self.events[eventIdx];
        const NSRange substrRange = [event.title rangeOfString:text options:NSCaseInsensitiveSearch];
        if (0 == substrRange.length) { continue; }

        indexesArray[index] = eventIdx;
        index++;
    }

    [resultIndexes setLength:sizeof(NSInteger) * index];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // init like
    self.eventCount = 10000; // TODO: predefined - change to something more useful
    self.filteredIndexesCount = -1;

    self.loadingQueue = dispatch_queue_create("com.viewController.loadingQueue", DISPATCH_QUEUE_SERIAL);
    self.threadsCount = NSProcessInfo.processInfo.processorCount / 2;

    NSMutableArray* array = [NSMutableArray.alloc initWithCapacity:self.threadsCount];
    for (NSUInteger idx = 0; idx < self.threadsCount; idx++) {
        [array addObject:dispatch_queue_create([NSString stringWithFormat:@"com.viewController.processingQueues.%d", (int)idx].UTF8String, DISPATCH_QUEUE_SERIAL)];
    }
    self.processingQueues = array;

    NSDate* startDate = nil;
    NSDate* endDate = nil;
    [ViewController getStartRangeDate:&startDate endRangeDate:&endDate forDate:[NSDate new] minusYearsDelta:startMinusSearchDeltaInYears plusYearsDelta: startPlusSearchDeltaInYears];

    self.filteredIndexes = [NSMutableData dataWithLength:sizeof(NSInteger) * self.eventCount];
    self.events = fetchEvents(startDate, endDate);

    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search";
    self.navigationItem.titleView = self.searchBar;
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"EventCell"];
    
    [self.view addSubview:self.tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return -1 == self.filteredIndexesCount ? self.eventCount : self.filteredIndexesCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    auto* cell = [tableView dequeueReusableCellWithIdentifier:@"EventCell" forIndexPath:indexPath];
    
    Event *event = -1 == self.filteredIndexesCount ? self.events[indexPath.row] : self.events[((NSInteger*)self.filteredIndexes.bytes)[indexPath.row]];

    auto* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd"];

    cell.textLabel.text = [NSString stringWithFormat:@"%@: %@ - %@", event.title, [dateFormatter stringFromDate:event.startDate], [dateFormatter stringFromDate:event.endDate]];
    return cell;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(performSearchText:) withObject:searchText afterDelay:1.5];
}

- (void)performSearchText:(NSString* )text {
    if (text.length == 0) {
        if (-1 != self.filteredIndexesCount) {
            self.filteredIndexesCount = -1;
            [self.tableView reloadData];
        }
        return;
    }

    const NSUInteger queuesCount = self.processingQueues.count;
    const NSInteger eventCount = self.eventCount;
    const NSInteger width = eventCount / queuesCount;

    dispatch_group_t group = dispatch_group_create();
    NSMutableArray<NSData*>* result = [NSMutableArray.alloc initWithCapacity:queuesCount];

    for (NSUInteger idx = 0; idx < queuesCount; idx++) {
        dispatch_group_enter(group);

        NSMutableData* chunk = [NSMutableData new];
        [result addObject:chunk];

        dispatch_async(self.processingQueues[idx], ^{
            const NSInteger location = idx * width;
            const NSRange range = NSMakeRange(location, (idx + 1 < queuesCount) ? width : eventCount - location);
            [self filterEventsInRange:range searchText:text resultIndexes:chunk];
            dispatch_group_leave(group);
        });
    }

    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

    NSUInteger index = 0;
    NSInteger* indexesArray = (NSInteger*)self.filteredIndexes.mutableBytes;

    for (NSInteger idx = 0; idx < result.count; idx++) {
        NSData* subIndexes = [result objectAtIndex:idx];
        const NSUInteger length = [subIndexes length];

        if (0 == length) { continue; }

        memcpy(&indexesArray[index], subIndexes.bytes, length);
        index += length / sizeof(NSInteger);
    }

    self.filteredIndexesCount = index;
    [self.tableView reloadData];

    NSLog(@"self.filteredIndexesCount = %d", (int)self.filteredIndexesCount);
}

@end
