/*======================================================================
 FILE: icaltime.h
 CREATOR: eric 02 June 2000

 (C) COPYRIGHT 2000, Eric Busboom <eric@civicknowledge.com>

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: https://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at https://www.mozilla.org/MPL/

 The Original Code is eric. The Initial Developer of the Original
 Code is Eric Busboom
======================================================================*/

/**     @file icaltime.h
 *      @brief struct icaltimetype is a pseudo-object that abstracts time
 *      handling.
 *
 *      It can represent either a DATE or a DATE-TIME (floating, UTC or in a
 *      given timezone), and it keeps track internally of its native timezone.
 *
 *      The typical usage is to call the correct constructor specifying the
 *      desired timezone. If this is not known until a later time, the
 *      correct behavior is to specify a NULL timezone and call
 *      icaltime_convert_to_zone() at a later time.
 *
 *      There are several ways to create a new icaltimetype:
 *
 *      - icaltime_null_time()
 *      - icaltime_null_date()
 *      - icaltime_current_time_with_zone()
 *      - icaltime_today()
 *      - icaltime_from_timet_with_zone(time_t tm, int is_date,
 *              icaltimezone *zone)
 *      - icaltime_from_day_of_year(int doy, int year)
 *
 *      italtimetype objects can be converted to different formats:
 *
 *      - icaltime_as_timet(struct icaltimetype tt)
 *      - icaltime_as_timet_with_zone(struct icaltimetype tt,
 *              icaltimezone *zone)
 *      - icaltime_as_ical_string(struct icaltimetype tt)
 *
 *      Accessor methods include:
 *
 *      - icaltime_get_timezone(struct icaltimetype t)
 *      - icaltime_get_tzid(struct icaltimetype t)
 *      - icaltime_set_timezone(struct icaltimetype t, const icaltimezone *zone)
 *      - icaltime_day_of_year(struct icaltimetype t)
 *      - icaltime_day_of_week(struct icaltimetype t)
 *      - icaltime_start_doy_week(struct icaltimetype t, int fdow)
 *      - icaltime_week_number(struct icaltimetype t)
 *
 *      Query methods include:
 *
 *      - icaltime_is_null_time(struct icaltimetype t)
 *      - icaltime_is_valid_time(struct icaltimetype t)
 *      - icaltime_is_date(struct icaltimetype t)
 *      - icaltime_is_utc(struct icaltimetype t)
 *
 *      Modify, compare and utility methods include:
 *
 *      - icaltime_compare(struct icaltimetype a,struct icaltimetype b)
 *      - icaltime_compare_date_only(struct icaltimetype a,
 *              struct icaltimetype b)
 *      - icaltime_adjust(struct icaltimetype *tt, int days, int hours,
 *              int minutes, int seconds);
 *      - icaltime_normalize(struct icaltimetype t);
 *      - icaltime_convert_to_zone(const struct icaltimetype tt,
 *              icaltimezone *zone);
 */

#ifndef ICALTIME_H
#define ICALTIME_H

#include "libical_ical_export.h"

#include <time.h>

/* An opaque struct representing a timezone. We declare this here to avoid
   a circular dependancy. */
#if !defined(ICALTIMEZONE_DEFINED)
#define ICALTIMEZONE_DEFINED
typedef struct _icaltimezone icaltimezone;
#endif

/** icaltime_span is returned by icalcomponent_get_span() */
struct icaltime_span
{
    time_t start;       /**< in UTC */
    time_t end;         /**< in UTC */
    int is_busy;        /**< 1->busy time, 0-> free time */
};

typedef struct icaltime_span icaltime_span;

struct icaltimetype
{
    int year;           /**< Actual year, e.g. 2001. */
    int month;          /**< 1 (Jan) to 12 (Dec). */
    int day;
    int hour;
    int minute;
    int second;

    int is_date;        /**< 1 -> interpret this as date. */

    int is_daylight;    /**< 1 -> time is in daylight savings time. */

    const icaltimezone *zone;  /**< timezone */
};

typedef struct icaltimetype icaltimetype;

/**     @brief Constructor.
 *
 *      @returns A null time, which indicates no time has been set.
 *      This time represents the beginning of the epoch.
 */
LIBICAL_ICAL_EXPORT struct icaltimetype icaltime_null_time(void);

/**     @brief Constructor.
 *
 *      @returns A null date, which indicates no time has been set.
 */
LIBICAL_ICAL_EXPORT struct icaltimetype icaltime_null_date(void);

/**     @brief Convenience constructor.
 *
 * @returns The current time in the given timezone, as an icaltimetype.
 */
LIBICAL_ICAL_EXPORT struct icaltimetype icaltime_current_time_with_zone(const icaltimezone *zone);

/**     @brief Convenience constructor.
 *
 * @returns The current day as an icaltimetype, with is_date set.
 */
LIBICAL_ICAL_EXPORT struct icaltimetype icaltime_today(void);

/**     @brief Constructor.
 *
 *      @param tm The time expressed as seconds past UNIX epoch
 *      @param is_date Boolean: 1 means we should treat tm as a DATE
 *      @param zone The timezone tm is in, NULL means to treat tm as a
 *              floating time
 *
 *      Returns a new icaltime instance, initialized to the given time,
 *      optionally using the given timezone.
 *
 *      If the caller specifies the is_date param as TRUE, the returned
 *      object is of DATE type, otherwise the input is meant to be of
 *      DATE-TIME type.
 *      If the zone is not specified (NULL zone param) the time is taken
 *      to be floating, that is, valid in any timezone. Note that, in
 *      addition to the uses specified in [RFC5545], this can be used
 *      when doing simple math on couples of times.
 *      If the zone is specified (UTC or otherwise), it's stored in the
 *      object and it's used as the native timezone for this object.
 *      This means that the caller can convert this time to a different
 *      target timezone with no need to store the source timezone.
 *
 */
LIBICAL_ICAL_EXPORT struct icaltimetype icaltime_from_timet_with_zone(const time_t tm,
                                                                      const int is_date,
                                                                      const icaltimezone *zone);

/**     @brief Contructor.
 *
 * Creates a time from an ISO format string.
 *
 * @todo If the given string specifies a DATE-TIME not in UTC, there
 *       is no way to know if this is a floating time or really refers to a
 *       timezone. We should probably add a new constructor:
 *       icaltime_from_string_with_zone()
 */
LIBICAL_ICAL_EXPORT struct icaltimetype icaltime_from_string(const char *str);

/**     @brief Contructor.
 *
 *      Creates a new time, given a day of year and a year.
 *
 *      Note that Jan 1 is day #1, not 0.
 */
LIBICAL_ICAL_EXPORT struct icaltimetype icaltime_from_day_of_year(const int doy, const int year);

/**
 * Returns the time as seconds past the UNIX epoch.
 *
 * This function probably won't do what you expect.  In particular, you should
 * only pass an icaltime in UTC, since no conversion is done.  Even in that case,
 * it's probably better to just use icaltime_as_timet_with_zone().
 */
LIBICAL_ICAL_EXPORT time_t icaltime_as_timet(const struct icaltimetype);

/**     @brief Returns the time as seconds past the UNIX epoch, using the
 *      given timezone.
 *
 *      This convenience method combines a call to icaltime_convert_to_zone()
 *      with a call to icaltime_as_timet().
 *      If the input timezone is null, no conversion is done; that is, the
 *      time is simply returned as time_t in its native timezone.
 */
LIBICAL_ICAL_EXPORT time_t icaltime_as_timet_with_zone(const struct icaltimetype tt,
                                                       const icaltimezone *zone);

/**
 * @brief Returns a string represention of the time, in RFC5545 format.
 *
 * @par Ownership
 * The created string is owned by libical.
 */
LIBICAL_ICAL_EXPORT const char *icaltime_as_ical_string(const struct icaltimetype tt);

/**
 * @brief Returns a string represention of the time, in RFC5545 format.
 *
 * @par Ownership
 * The string is owned by the caller.
 */
LIBICAL_ICAL_EXPORT char *icaltime_as_ical_string_r(const struct icaltimetype tt);

/** @brief Returns the timezone. */
LIBICAL_ICAL_EXPORT const icaltimezone *icaltime_get_timezone(const struct icaltimetype t);

/** @brief Returns the tzid, or NULL for a floating time. */
LIBICAL_ICAL_EXPORT const char *icaltime_get_tzid(const struct icaltimetype t);

/**     @brief Sets the timezone.
 *
 *      Forces the icaltime to be interpreted relative to another timezone.
 *      If you need to do timezone conversion, applying offset adjustments,
 *      then you should use icaltime_convert_to_zone instead.
 */
LIBICAL_ICAL_EXPORT struct icaltimetype icaltime_set_timezone(struct icaltimetype *t,
                                                              const icaltimezone *zone);

/**
 *      @brief Returns the day of the year, counting from 1 (Jan 1st).
 */
LIBICAL_ICAL_EXPORT int icaltime_day_of_year(const struct icaltimetype t);

/** @brief Returns the day of the week of the given time.
 *
 * Sunday is 1, and Saturday is 7.
 */
LIBICAL_ICAL_EXPORT int icaltime_day_of_week(const struct icaltimetype t);

/** Returns the day of the year for the first day of the week . */
/** @brief Returns the day of the year for the first day of the week
 *  that the given time is within.
 *
 *  This uses the first day of the week that contains the given time,
 *  which is a Sunday. It returns the day of the year for the resulting
 *  day.
 */
LIBICAL_ICAL_EXPORT int icaltime_start_doy_week(const struct icaltimetype t, int fdow);

/** @brief Returns the week number for the week the given time is within.
 *
 * @todo Doesn't take into account the start day of the
 * week. strftime assumes that weeks start on Monday.
 */
LIBICAL_ICAL_EXPORT int icaltime_week_number(const struct icaltimetype t);

/** @brief Returns true if the time is null. */
LIBICAL_ICAL_EXPORT int icaltime_is_null_time(const struct icaltimetype t);

/**
 *      @brief Returns false if the time is clearly invalid, but is not null.
 *
 *      This is usually the result of creating a new time type but not
 *      clearing it, or setting one of the flags to an illegal value.
 */
LIBICAL_ICAL_EXPORT int icaltime_is_valid_time(const struct icaltimetype t);

/**     @brief Returns true if time is a DATE.
 *
 * The options are DATE type, which returns true, or DATE-TIME, which
 * returns false.
 */
LIBICAL_ICAL_EXPORT int icaltime_is_date(const struct icaltimetype t);

/**     @brief Returns true if the time is relative to UTC zone.
 *
 *      @todo  We should only check the zone.
 */
LIBICAL_ICAL_EXPORT int icaltime_is_utc(const struct icaltimetype t);

/**
 *      @brief Returns -1, 0, or 1 to indicate that a is less than b, a
 *      equals b, or a is greater than b.
 *
 *      This converts both times to the UTC timezone and compares them.
 */
LIBICAL_ICAL_EXPORT int icaltime_compare(const struct icaltimetype a, const struct icaltimetype b);

/** @brief Like icaltime_compare, but only use the date parts.
 *
 * This converts both times to the UTC timezone and compares their date
 * components.
 */
LIBICAL_ICAL_EXPORT int icaltime_compare_date_only(const struct icaltimetype a,
                                                   const struct icaltimetype b);

/** @brief Like icaltime_compare, but only use the date parts; accepts
 *  timezone.
 *
 * This converts both times to the given timezone and compares their date
 * components.
 */
LIBICAL_ICAL_EXPORT int icaltime_compare_date_only_tz(const struct icaltimetype a,
                                                      const struct icaltimetype b,
                                                      icaltimezone *tz);

/** Adds or subtracts a number of days, hours, minutes and seconds. */
/**     @brief Internal, shouldn't be part of the public API
 *
 *      Adds or subtracts a time from a icaltimetype. This time is given
 *      as a number of days, hours, minutes and seconds.
 *
 *      @note This function is exactly the same as
 *      icaltimezone_adjust_change() except for the type of the first
 *      parameter.
 */
LIBICAL_ICAL_EXPORT void icaltime_adjust(struct icaltimetype *tt,
                                         const int days, const int hours,
                                         const int minutes, const int seconds);

/**
 *      @brief Normalizes the icaltime, so all of the time components
 *      are in their normal ranges.
 *
 *      For instance, given a time with minutes=70, the minutes will be
 *      reduces to 10, and the hour incremented. This allows the caller
 *      to do arithmetic on times without worrying about overflow or
 *      underflow.
 */
LIBICAL_ICAL_EXPORT struct icaltimetype icaltime_normalize(const struct icaltimetype t);

/**     @brief Converts time to a given timezone.
 *
 *      Converts a time from its native timezone to a given timezone.
 *
 *      If tt is a date, the returned time is an exact
 *      copy of the input. If it's a floating time, the returned object
 *      represents the same time translated to the given timezone.
 *      Otherwise the time will be converted to the new
 *      time zone, and its native timezone set to the right timezone.
 */
LIBICAL_ICAL_EXPORT struct icaltimetype icaltime_convert_to_zone(const struct icaltimetype tt,
                                                                 icaltimezone *zone);

/** Returns the number of days in the given month. */
LIBICAL_ICAL_EXPORT int icaltime_days_in_month(const int month, const int year);

/**
 * @brief Returns whether the specified year is a leap year.
 *
 * Year is the normal year, e.g. 2001.
 */
LIBICAL_ICAL_EXPORT int icaltime_is_leap_year(const int year);

/** Returns the number of days in this year. */
LIBICAL_ICAL_EXPORT int icaltime_days_in_year(const int year);

/**
 *  @brief Builds an icaltimespan given a start time, end time and busy value.
 *
 *  @param dtstart   The beginning time of the span, can be a date-time
 *                   or just a date.
 *  @param dtend     The end time of the span.
 *  @param is_busy   A boolean value, 0/1.
 *  @returns          A span using the supplied values. The times are specified in UTC.
 */
LIBICAL_ICAL_EXPORT struct icaltime_span icaltime_span_new(struct icaltimetype dtstart,
                                                           struct icaltimetype dtend, int is_busy);

/** @brief Returns true if the two spans overlap.
 *
 *  @param s1         First span to test
 *  @param s2         Second span to test
 *  @return           boolean value
 *
 *  The result is calculated by testing if the start time of s1 is contained
 *  by the s2 span, or if the end time of s1 is contained by the s2 span.
 *
 *  Also returns true if the spans are equal.
 *
 *  Note, this will return false if the spans are adjacent.
 */
LIBICAL_ICAL_EXPORT int icaltime_span_overlaps(icaltime_span *s1, icaltime_span *s2);

/** @brief Returns true if the span is totally within the containing
 *  span.
 *
 *  @param s          The span to test for.
 *  @param container  The span to test against.
 *  @return           boolean value.
 *
 */
LIBICAL_ICAL_EXPORT int icaltime_span_contains(icaltime_span *s, icaltime_span *container);

#endif /* !ICALTIME_H */
