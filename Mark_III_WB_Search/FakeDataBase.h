//
//  FakeDataBase.hpp
//  Mark_III_WB_Search
//
//  Created by Denis Esie on 07.02.2024.
//

#ifndef FakeDataBase_h
#define FakeDataBase_h

#import <Foundation/Foundation.h>

@class Event;

// For the simplicity of the task we assume that this function always returns 10000 items
Event * __strong * fetchEvents(NSDate *startDate, NSDate *endDate);

#endif /* FakeDataBase_h */
