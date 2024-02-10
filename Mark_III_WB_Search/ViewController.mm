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

@property (nonatomic, direct) NSMutableData* filteredIndexes;
@property (nonatomic, direct) NSInteger filteredIndexesCount;
@property (nonatomic, direct) NSInteger highlightEventIndex;

@property (nonatomic, direct) NSArray<dispatch_queue_t>* processingQueues;
@property (nonatomic, direct) NSUInteger currentProcessingQueue;

@property (nonatomic, direct) NSString* latestSearchText;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // init like
    self.eventCount = 10000; // TODO: predefined - change to something more useful
    self.filteredIndexesCount = -1;
    self.highlightEventIndex = -1;

    _reportingQueue = dispatch_queue_create("com.viewController.loadingQueue", DISPATCH_QUEUE_SERIAL);

    const NSUInteger threadsCount = NSProcessInfo.processInfo.processorCount / 2;
    NSMutableArray* array = [NSMutableArray.alloc initWithCapacity:threadsCount];
    const dispatch_queue_attr_t attributes = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, -1);
    for (NSUInteger idx = 0; idx < threadsCount; idx++) {
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
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(performSearchText:) object:self.latestSearchText];

    self.latestSearchText = searchText;
    [self performSelector:@selector(performSearchText:) withObject:self.latestSearchText afterDelay:1.5];
}

- (void)performSearchText:(NSString* )text {
    __block NSInteger startIndex = 0;
    NSInteger* indexesArray = (NSInteger*)self.filteredIndexes.mutableBytes;

    self.highlightEventIndex = -1;

    __weak typeof(self) weakSelf = self;
    [ViewController performSearchText:text definingDate:nil events:self.events eventsCount:self.eventCount environment:self completion:^(CompletionResult result) {
        __strong typeof(self) strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (result.stage) {
                case inProgress:
                    memcpy(&indexesArray[startIndex], result.info.partial.bytes, result.info.partial.bytesSize);
                    strongSelf.filteredIndexesCount = result.info.partial.count;
                    startIndex = result.info.partial.count;
                    break;
                case completed:
                    strongSelf.filteredIndexesCount = result.info.final.count;
                    [strongSelf.tableView reloadData];
                    NSLog(@"self.filteredIndexesCount = %d", (int)strongSelf.filteredIndexesCount);

                    if (-1 == strongSelf.filteredIndexesCount)
                        break;

                    strongSelf.highlightEventIndex = result.info.final.nearestEventIndex;

                    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(performEventHighlighting) object:nil];
                    [self performSelectorOnMainThread:@selector(performEventHighlighting) withObject:nil waitUntilDone:NO modes:@[NSRunLoopCommonModes]];
                    break;
            }
        });
    }];
}

- (void)performEventHighlighting {
    if (-1 == self.highlightEventIndex || self.highlightEventIndex >= self.filteredIndexesCount)
        return;

    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.highlightEventIndex inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}

// MARK: ### SearchEnvironment ###

- (dispatch_queue_t)nextProcessingQueue {
    auto result = self.processingQueues[self.currentProcessingQueue % self.processingQueues.count];
    self.currentProcessingQueue++;
    return result;
}

@synthesize reportingQueue = _reportingQueue;
@synthesize processingItemsCount = _processingItemsCount;

- (NSInteger)processingItemsCount {
    return 2000;
}

@end
