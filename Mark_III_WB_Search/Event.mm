//
//  Event.mm
//  Mark_III_WB_Search
//
//  Created by Denis Esie on 07.02.2024.
//

#include "Event.h"

@implementation Event

- (instancetype)initWithTitle:(NSString *)title startDate:(NSDate *)startDate endDate:(NSDate *)endDate {
    self = [super init];
    if (self) {
        _title = title;
        _startDate = startDate;
        _endDate = endDate;
    }
    return self;
}

@end
