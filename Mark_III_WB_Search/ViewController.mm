//
//  ViewController.mm
//  Mark_III_WB_Search
//
//  Created by Denis Esie on 07.02.2024.
//

#import "ViewController.h"
#import "ViewController+Utility.h"
#import "FakeDataBase.h"
#import "Event.h"
#import <list>

@interface ViewController () <SearchEnvironment>

@property (nonatomic, direct) UITableView *tableView;
@property (nonatomic, direct) UISearchBar *searchBar;
@property (nonatomic, direct) Event * __strong * events;
@property (nonatomic, direct) NSInteger eventCount;

@property (nonatomic, direct) dispatch_queue_t loadingQueue;

@property (nonatomic, direct) NSMutableData* filteredIndexes;
@property (nonatomic, direct) NSInteger filteredIndexesCount;

@property (nonatomic, direct) NSArray<dispatch_queue_t>* processingQueues;
@property (nonatomic, direct) NSUInteger currentProcessingQueue;
@property (nonatomic, direct) NSUInteger threadsCount;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // init like
    self.eventCount = 10000; // TODO: predefined - change to something more useful
    self.filteredIndexesCount = -1;

    self.loadingQueue = dispatch_queue_create("com.viewController.loadingQueue", DISPATCH_QUEUE_SERIAL);
    self.threadsCount = NSProcessInfo.processInfo.processorCount / 2;

    NSMutableArray* array = [NSMutableArray.alloc initWithCapacity:self.threadsCount];
    const dispatch_queue_attr_t attributes = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, -1);
    for (NSUInteger idx = 0; idx < self.threadsCount; idx++) {
        [array addObject:dispatch_queue_create([NSString stringWithFormat:@"com.viewController.processingQueues.%d", (int)idx].UTF8String, attributes)];
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
    __block NSInteger startIndex = 0;
    NSInteger* indexesArray = (NSInteger*)self.filteredIndexes.mutableBytes;

    __weak typeof(self) weakSelf = self;
    [ViewController performSearchText:text events:self.events eventsCount:self.eventCount environment:self completion:^(NSInteger count, BOOL finished, const void *partialBytes, NSUInteger length) {
        __strong typeof(self) strongSelf = weakSelf;
        dispatch_barrier_async(dispatch_get_main_queue(), ^{
            if (finished) {
                strongSelf.filteredIndexesCount = count;
                [strongSelf.tableView reloadData];
                NSLog(@"self.filteredIndexesCount = %d", (int)strongSelf.filteredIndexesCount);
            } else {
                memcpy(&indexesArray[startIndex], partialBytes, length);
                strongSelf.filteredIndexesCount = count;
                startIndex = count;
            }
        });
    }];
}

// MARK: ### SearchEnvironment ###

- (dispatch_queue_t)nextProcessingQueue {
    auto result = self.processingQueues[self.currentProcessingQueue % self.processingQueues.count];
    self.currentProcessingQueue++;
    return result;
}

@synthesize reportingQueue;

- (dispatch_queue_t)reportingQueue {
    return self.loadingQueue;
}

@end
