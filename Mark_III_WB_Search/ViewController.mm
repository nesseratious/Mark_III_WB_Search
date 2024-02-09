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

@interface ViewController ()

@property (nonatomic, direct) UITableView *tableView;
@property (nonatomic, direct) UISearchBar *searchBar;
@property (nonatomic, direct) Event * __strong * events;
@property (nonatomic, direct) NSInteger eventCount;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
// MARK: - Example Code
    
// THIS IS EXAMPLE CODE, COMMENT OR DELETE IT WHEN DOING THE TASK
    
    auto* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd"];
    NSDate *startRange = [dateFormatter dateFromString:@"2019/01/01"];
    NSDate *endRange = [dateFormatter dateFromString:@"2029/01/01"];
    self.events = fetchEvents(startRange, endRange);
    self.eventCount = 10000;
    
// MARK: Example Code -

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
    return self.eventCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    auto* cell = [tableView dequeueReusableCellWithIdentifier:@"EventCell" forIndexPath:indexPath];
    
    Event *event = self.events[indexPath.row];
    
    auto* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd"];

    cell.textLabel.text = [NSString stringWithFormat:@"%@: %@ - %@", event.title, [dateFormatter stringFromDate:event.startDate], [dateFormatter stringFromDate:event.endDate]];
    return cell;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
     
}

@end

