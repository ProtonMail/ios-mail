/*======================================================================
 FILE: icalrecur.h
 CREATOR: eric 20 March 2000

 (C) COPYRIGHT 2000, Eric Busboom <eric@civicknowledge.com>

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: https://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at https://www.mozilla.org/MPL/
========================================================================*/

/**
@file icalrecur.h
@brief Routines for dealing with recurring time

How to use:

1) Get a rule and a start time from a component

@code
        icalproperty rrule;
        struct icalrecurrencetype recur;
        struct icaltimetype dtstart;

        rrule = icalcomponent_get_first_property(comp,ICAL_RRULE_PROPERTY);
        recur = icalproperty_get_rrule(rrule);
        start = icalproperty_get_dtstart(dtstart);
@endcode

Or, just make them up:

@code
        recur = icalrecurrencetype_from_string("FREQ=YEARLY;BYDAY=SU,WE");
        dtstart = icaltime_from_string("19970101T123000")
@endcode

2) Create an iterator

@code
        icalrecur_iterator *ritr;
        ritr = icalrecur_iterator_new(recur,start);
@endcode

3) Iterator over the occurrences

@code
        struct icaltimetype next;
        while (next = icalrecur_iterator_next(ritr)
               && !icaltime_is_null_time(next){
                Do something with next
        }
@endcode

Note that the time returned by icalrecur_iterator_next is in
whatever timezone that dtstart is in.

*/

#ifndef ICALRECUR_H
#define ICALRECUR_H

#include "libical_ical_export.h"
#include "icalarray.h"
#include "icaltime.h"

/*
 * Recurrence enumerations
 */

typedef enum icalrecurrencetype_frequency
{
    /* These enums are used to index an array, so don't change the
       order or the integers */

    ICAL_SECONDLY_RECURRENCE = 0,
    ICAL_MINUTELY_RECURRENCE = 1,
    ICAL_HOURLY_RECURRENCE = 2,
    ICAL_DAILY_RECURRENCE = 3,
    ICAL_WEEKLY_RECURRENCE = 4,
    ICAL_MONTHLY_RECURRENCE = 5,
    ICAL_YEARLY_RECURRENCE = 6,
    ICAL_NO_RECURRENCE = 7
} icalrecurrencetype_frequency;

typedef enum icalrecurrencetype_weekday
{
    ICAL_NO_WEEKDAY,
    ICAL_SUNDAY_WEEKDAY,
    ICAL_MONDAY_WEEKDAY,
    ICAL_TUESDAY_WEEKDAY,
    ICAL_WEDNESDAY_WEEKDAY,
    ICAL_THURSDAY_WEEKDAY,
    ICAL_FRIDAY_WEEKDAY,
    ICAL_SATURDAY_WEEKDAY
} icalrecurrencetype_weekday;

typedef enum icalrecurrencetype_skip
{
    ICAL_SKIP_BACKWARD = 0,
    ICAL_SKIP_FORWARD,
    ICAL_SKIP_OMIT,
    ICAL_SKIP_UNDEFINED
} icalrecurrencetype_skip;

enum icalrecurrence_array_max_values
{
    ICAL_RECURRENCE_ARRAY_MAX = 0x7f7f,
    ICAL_RECURRENCE_ARRAY_MAX_BYTE = 0x7f
};

/*
 * Recurrence enumerations conversion routines.
 */

LIBICAL_ICAL_EXPORT icalrecurrencetype_frequency icalrecur_string_to_freq(const char *str);
LIBICAL_ICAL_EXPORT const char *icalrecur_freq_to_string(icalrecurrencetype_frequency kind);

LIBICAL_ICAL_EXPORT icalrecurrencetype_skip icalrecur_string_to_skip(const char *str);
LIBICAL_ICAL_EXPORT const char *icalrecur_skip_to_string(icalrecurrencetype_skip kind);

LIBICAL_ICAL_EXPORT const char *icalrecur_weekday_to_string(icalrecurrencetype_weekday kind);
LIBICAL_ICAL_EXPORT icalrecurrencetype_weekday icalrecur_string_to_weekday(const char *str);

/**
 * Recurrence type routines
 */

/* See RFC 5545 Section 3.3.10, RECUR Value, and RFC 7529
 * for an explanation of the values and fields in struct icalrecurrencetype.
 *
 * The maximums below are based on lunisolar leap years (13 months)
 */
#define ICAL_BY_SECOND_SIZE     62      /* 0 to 60 */
#define ICAL_BY_MINUTE_SIZE     61      /* 0 to 59 */
#define ICAL_BY_HOUR_SIZE       25      /* 0 to 23 */
#define ICAL_BY_MONTH_SIZE      14      /* 1 to 13 */
#define ICAL_BY_MONTHDAY_SIZE   32      /* 1 to 31 */
#define ICAL_BY_WEEKNO_SIZE     56      /* 1 to 55 */
#define ICAL_BY_YEARDAY_SIZE    386     /* 1 to 385 */
#define ICAL_BY_SETPOS_SIZE     ICAL_BY_YEARDAY_SIZE          /* 1 to N */
#define ICAL_BY_DAY_SIZE        7*(ICAL_BY_WEEKNO_SIZE-1)+1   /* 1 to N */

/** Main struct for holding digested recurrence rules */
struct icalrecurrencetype
{
    icalrecurrencetype_frequency freq;

    /* until and count are mutually exclusive. */
    struct icaltimetype until;
    int count;

    short interval;

    icalrecurrencetype_weekday week_start;

    /* The BY* parameters can each take a list of values. Here I
     * assume that the list of values will not be larger than the
     * range of the value -- that is, the client will not name a
     * value more than once.

     * Each of the lists is terminated with the value
     * ICAL_RECURRENCE_ARRAY_MAX unless the list is full.
     */

    short by_second[ICAL_BY_SECOND_SIZE];
    short by_minute[ICAL_BY_MINUTE_SIZE];
    short by_hour[ICAL_BY_HOUR_SIZE];
    short by_day[ICAL_BY_DAY_SIZE];             /**< @brief Encoded value
        *
        * The 'day' element of the by_day array is encoded to allow
        * representation of both the day of the week ( Monday, Tueday), but
        * also the Nth day of the week (first Tuesday of the month, last
        * Thursday of the year).
        *
        * These values are decoded by icalrecurrencetype_day_day_of_week() and
        * icalrecurrencetype_day_position().
        */
    short by_month_day[ICAL_BY_MONTHDAY_SIZE];
    short by_year_day[ICAL_BY_YEARDAY_SIZE];
    short by_week_no[ICAL_BY_WEEKNO_SIZE];
    short by_month[ICAL_BY_MONTH_SIZE];         /**< @brief Encoded value
        *
        * The 'month' element of the by_month array is encoded to allow
        * representation of the "L" leap suffix (RFC 7529).
        *
        * These values are decoded by icalrecurrencetype_month_is_leap()
        * and icalrecurrencetype_month_month().
        */
    short by_set_pos[ICAL_BY_SETPOS_SIZE];

    /* For RSCALE extension (RFC 7529) */
    char *rscale;
    icalrecurrencetype_skip skip;
};

LIBICAL_ICAL_EXPORT int icalrecurrencetype_rscale_is_supported(void);

LIBICAL_ICAL_EXPORT icalarray *icalrecurrencetype_rscale_supported_calendars(void);

LIBICAL_ICAL_EXPORT void icalrecurrencetype_clear(struct icalrecurrencetype *r);

/*
 * Routines to decode the day values of the by_day array
 */

/** @brief Decodes a day to a weekday.
 *
 * @returns The decoded day of the week. 1 is Monday, 2 is Tuesday, etc.
 * A position of 0 means 'any' or 'every'.
 *
 * The 'day' element of icalrecurrencetype_weekday is encoded to
 * allow representation of both the day of the week ( Monday, Tuesday),
 * but also the Nth day of the week ( First tuesday of the month, last
 * thursday of the year) These routines decode the day values.
 *
 * The day's position in the period ( Nth-ness) and the numerical
 * value of the day are encoded together as: pos*7 + dow.
 *
 * A position of 0 means 'any' or 'every'.
 */
LIBICAL_ICAL_EXPORT enum icalrecurrencetype_weekday icalrecurrencetype_day_day_of_week(short day);

/** @brief Decodes a day to a position of the weekday.
 *
 * @returns The position of the day in the week.
 * 0 == any of day of week. 1 == first, 2 = second, -2 == second to last, etc.
 * 0 means 'any' or 'every'.
 */
LIBICAL_ICAL_EXPORT int icalrecurrencetype_day_position(short day);

/** Encodes the @p weekday and @p position into a form, which can be stored
 *  to icalrecurrencetype::by_day array. Use icalrecurrencetype_day_day_of_week()
 *  and icalrecurrencetype_day_position() to split the encoded value back into the parts.
 * @since 3.1
 */
LIBICAL_ICAL_EXPORT short icalrecurrencetype_encode_day(enum icalrecurrencetype_weekday weekday,
                                                        int position);

/*
 * Routines to decode the 'month' element of the by_month array
 */

/**
 * The @p month element of the by_month array is encoded to allow
 * representation of the "L" leap suffix (RFC 7529).
 * These routines decode the month values.
 *
 * The "L" suffix is encoded by setting a high-order bit.
 */
LIBICAL_ICAL_EXPORT int icalrecurrencetype_month_is_leap(short month);

LIBICAL_ICAL_EXPORT int icalrecurrencetype_month_month(short month);

/** Encodes the @p month and the @p is_leap into a form, which can be stored
 *  to icalrecurrencetype::by_month array. Use icalrecurrencetype_month_is_leap()
 *  and icalrecurrencetype_month_month() to split the encoded value back into the parts
 *  @since 3.1
 */
LIBICAL_ICAL_EXPORT short icalrecurrencetype_encode_month(int month, int is_leap);

/*
 * Recurrence rule parser
 */

/** Convert between strings and recurrencetype structures. */
LIBICAL_ICAL_EXPORT struct icalrecurrencetype icalrecurrencetype_from_string(const char *str);

LIBICAL_ICAL_EXPORT char *icalrecurrencetype_as_string(struct icalrecurrencetype *recur);

LIBICAL_ICAL_EXPORT char *icalrecurrencetype_as_string_r(struct icalrecurrencetype *recur);

/*
 * Recurrence iteration routines
 */

typedef struct icalrecur_iterator_impl icalrecur_iterator;

/** Creates a new recurrence rule iterator, starting at DTSTART. */
LIBICAL_ICAL_EXPORT icalrecur_iterator *icalrecur_iterator_new(struct icalrecurrencetype rule,
                                                               struct icaltimetype dtstart);

/**
 * Sets the date-time at which the iterator will start,
 * where @p start is a value between DTSTART and UNTIL.
 *
 * NOTE: CAN NOT be used with RRULEs that contain COUNT.
 * @since 3.0
 */
LIBICAL_ICAL_EXPORT int icalrecur_iterator_set_start(icalrecur_iterator *impl,
                                                     struct icaltimetype start);

/** Set the date-time at which the iterator will stop at the latest.
 *  Values equal to or greater than end will not be returned by the iterator.
*/
LIBICAL_ICAL_EXPORT int icalrecur_iterator_set_end(icalrecur_iterator *impl,
                                                   struct icaltimetype end);

/**
 * Sets the date-times over which the iterator will run,
 * where @p from is a value between DTSTART and UNTIL.
 *
 * If @p to is null time, the forward iterator will return values
 * up to and including UNTIL (if present), otherwise up to the year 2582.
 *
 * if @p to is non-null time and later than @p from,
 * the forward iterator will return values up to and including 'to'.
 *
 * If @p to is non-null time and earlier than @p from,
 * the reverse iterator will be set to start at @p from
 * and will return values down to and including @p to.
 *
 * NOTE: CAN NOT be used with RRULEs that contain COUNT.
 * @since 3.1
 */
LIBICAL_ICAL_EXPORT int icalrecur_iterator_set_range(icalrecur_iterator *impl,
                                                     struct icaltimetype from,
                                                     struct icaltimetype to);

/**
 * Gets the next occurrence from an iterator.
 */
LIBICAL_ICAL_EXPORT struct icaltimetype icalrecur_iterator_next(icalrecur_iterator *);

/**
 * Gets the previous occurrence from an iterator.
 * @since 3.1
 */
LIBICAL_ICAL_EXPORT struct icaltimetype icalrecur_iterator_prev(icalrecur_iterator *);

/** Frees the iterator. */
LIBICAL_ICAL_EXPORT void icalrecur_iterator_free(icalrecur_iterator *);

/** @brief Fills an array with the 'count' number of occurrences generated by
 * the rrule.
 *
 * Specifically, this fills @p array up with at most 'count' time_t values, each
 * representing an occurrence time in seconds past the POSIX epoch.
 *
 * Note that the times are returned in UTC, but the times
 * are calculated in local time. You will have to convert the results
 * back into local time before using them.
 */
LIBICAL_ICAL_EXPORT int icalrecur_expand_recurrence(const char *rule, time_t start,
                                                    int count, time_t *array);

#endif
