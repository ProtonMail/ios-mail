/*======================================================================
 FILE: icaltimezone.h
 CREATOR: Damon Chaplin 15 March 2001

 (C) COPYRIGHT 2001, Damon Chaplin <damon@ximian.com>

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: https://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at https://www.mozilla.org/MPL/
======================================================================*/
/**
 * @file icaltimezone.h
 * @brief Timezone handling routines
 */

#ifndef ICALTIMEZONE_H
#define ICALTIMEZONE_H

#include "libical_ical_export.h"
#include "icalcomponent.h"

#include <stdio.h>

#if !defined(ICALTIMEZONE_DEFINED)
#define ICALTIMEZONE_DEFINED
/** @brief An opaque struct representing a timezone.
 * We declare this here to avoid a circular dependancy.
 */
typedef struct _icaltimezone icaltimezone;
#endif

/*
 * Creating/Destroying individual icaltimezones.
 */

/** @brief Creates a new icaltimezone. */
LIBICAL_ICAL_EXPORT icaltimezone *icaltimezone_new(void);

LIBICAL_ICAL_EXPORT icaltimezone *icaltimezone_copy(icaltimezone *originalzone);

/** @brief Frees all memory used for the icaltimezone.
 * @param zone The icaltimezone to be freed
 * @param free_struct Whether to free the icaltimezone struct as well
 */
LIBICAL_ICAL_EXPORT void icaltimezone_free(icaltimezone *zone, int free_struct);

/** Sets the prefix to be used for tzid's generated from system tzdata.
    Must be globally unique (such as a domain name owned by the developer
    of the calling application), and begin and end with forward slashes.
    Do not change or de-allocate the string buffer after calling this.
 */
LIBICAL_ICAL_EXPORT void icaltimezone_set_tzid_prefix(const char *new_prefix);

/*
 * Accessing timezones.
 */

/** @brief Releases builtin timezone memory. */
LIBICAL_ICAL_EXPORT void icaltimezone_free_builtin_timezones(void);

/** @brief Returns an icalarray of icaltimezone structs, one for each builtin
   timezone.
 *
 * This will load and parse the zones.tab file to get the
 * timezone names and their coordinates. It will not load the
 * VTIMEZONE data for any timezones.
 */
LIBICAL_ICAL_EXPORT icalarray *icaltimezone_get_builtin_timezones(void);

/** @brief Returns a single builtin timezone, given its Olson city name. */
LIBICAL_ICAL_EXPORT icaltimezone *icaltimezone_get_builtin_timezone(const char *location);

/** @brief Returns a single builtin timezone, given its offset from UTC. */
LIBICAL_ICAL_EXPORT icaltimezone *icaltimezone_get_builtin_timezone_from_offset(int offset,
                                                                                const char *tzname);

/** @brief Returns a single builtin timezone, given its TZID. */
LIBICAL_ICAL_EXPORT icaltimezone *icaltimezone_get_builtin_timezone_from_tzid(const char *tzid);

/** @brief Returns the UTC timezone. */
LIBICAL_ICAL_EXPORT icaltimezone *icaltimezone_get_utc_timezone(void);

/** Returns the TZID of a timezone. */
LIBICAL_ICAL_EXPORT const char *icaltimezone_get_tzid(icaltimezone *zone);

/** Returns the city name of a timezone. */
LIBICAL_ICAL_EXPORT const char *icaltimezone_get_location(icaltimezone *zone);

/** Returns the TZNAME properties used in the latest STANDARD and DAYLIGHT
   components. If they are the same it will return just one, e.g. "LMT".
   If they are different it will format them like "EST/EDT". Note that this
   may also return NULL. */
LIBICAL_ICAL_EXPORT const char *icaltimezone_get_tznames(icaltimezone *zone);

/** @brief Returns the latitude of a builtin timezone. */
LIBICAL_ICAL_EXPORT double icaltimezone_get_latitude(icaltimezone *zone);

/** @brief Returns the longitude of a builtin timezone. */
LIBICAL_ICAL_EXPORT double icaltimezone_get_longitude(icaltimezone *zone);

/** @brief Returns the VTIMEZONE component of a timezone. */
LIBICAL_ICAL_EXPORT icalcomponent *icaltimezone_get_component(icaltimezone *zone);

/** @brief Sets the VTIMEZONE component of an icaltimezone, initializing the
 * tzid, location & tzname fields.
 *
 * @returns 1 on success or 0 on failure, i.e.  no TZID was found.
 */
LIBICAL_ICAL_EXPORT int icaltimezone_set_component(icaltimezone *zone, icalcomponent *comp);

/** @brief Returns the timezone name to display to the user.
 *
 * We prefer to use the Olson city name, but fall back on the TZNAME, or finally
 * the TZID. We don't want to use "" as it may be wrongly interpreted as a
 * floating time. Do not free the returned string.
 */
LIBICAL_ICAL_EXPORT const char *icaltimezone_get_display_name(icaltimezone *zone);

/*
 * Converting times between timezones.
 */

LIBICAL_ICAL_EXPORT void icaltimezone_convert_time(struct icaltimetype *tt,
                                                   icaltimezone *from_zone,
                                                   icaltimezone *to_zone);

/*
 * Getting offsets from UTC.
 */

/** @brief Calculates the UTC offset of a given local time in the given
 * timezone.
 *
 * It is the number of seconds to add to UTC to get local
 * time.  The is_daylight flag is set to 1 if the time is in
 * daylight-savings time.
 */
LIBICAL_ICAL_EXPORT int icaltimezone_get_utc_offset(icaltimezone *zone,
                                                    struct icaltimetype *tt, int *is_daylight);

/** @brief Calculates the UTC offset of a given UTC time in the given timezone.
 *
 * It is the number of seconds to add to UTC to get local
 * time.  The @p is_daylight flag is set to 1 if the time is in
 * daylight-savings time.
 */
LIBICAL_ICAL_EXPORT int icaltimezone_get_utc_offset_of_utc_time(icaltimezone *zone,
                                                                struct icaltimetype *tt,
                                                                int *is_daylight);

/*
 * Handling arrays of timezones. Mainly for internal use.
 */
LIBICAL_ICAL_EXPORT icalarray *icaltimezone_array_new(void);

LIBICAL_ICAL_EXPORT void icaltimezone_array_append_from_vtimezone(icalarray *timezones,
                                                                  icalcomponent *child);

LIBICAL_ICAL_EXPORT void icaltimezone_array_free(icalarray *timezones);

/*
 * By request (issue #112) make vtimezone functions public
 */
LIBICAL_ICAL_EXPORT void icaltimezone_expand_vtimezone(icalcomponent *comp,
                                                       int end_year, icalarray *changes);

/** @brief Gets the LOCATION or X-LIC-LOCATION property from a VTIMEZONE. */
LIBICAL_ICAL_EXPORT char *icaltimezone_get_location_from_vtimezone(icalcomponent *component);

/** @brief Gets the TZNAMEs used for the last STANDARD & DAYLIGHT
 * components in a VTIMEZONE.
 *
 * If both STANDARD and DAYLIGHT components use the same TZNAME, it
 * returns that. If they use different TZNAMEs, it formats them like
 * "EST/EDT". The returned string should be freed by the caller. */
LIBICAL_ICAL_EXPORT char *icaltimezone_get_tznames_from_vtimezone(icalcomponent *component);

/*
 * Truncate a VTIMEZONE component to the given start and end times.
 * If either time is null, then no truncation will occur at that point.
 * If either time is non-null, then it MUST be specified as UTC.
 * If the start time is non-null and ms_compatible is zero,
 * then the DTSTART of RRULEs will be adjusted to occur after the start time.
 * @since 3.0.6
 */
LIBICAL_ICAL_EXPORT void icaltimezone_truncate_vtimezone(icalcomponent *vtz,
                                                         icaltimetype start,
                                                         icaltimetype end,
                                                         int ms_compatible);

/*
 * @par Handling the default location the timezone files
 */

/** Sets the directory to look for the zonefiles */
LIBICAL_ICAL_EXPORT void set_zone_directory(const char *path);

/** Frees the memory dedicated to the zonefile directory */
LIBICAL_ICAL_EXPORT void free_zone_directory(void);

LIBICAL_ICAL_EXPORT void icaltimezone_release_zone_tab(void);

/*
 * @par Handling whether to use builtin timezone files
 */
LIBICAL_ICAL_EXPORT void icaltimezone_set_builtin_tzdata(int set);

LIBICAL_ICAL_EXPORT int icaltimezone_get_builtin_tzdata(void);

/*
 * Debugging Output.
 */

/**
 * @brief Outputs a list of timezone changes for the given timezone to the
 * given file, up to the maximum year given.
 *
 * We compare this output with the output from 'vzic --dump-changes' to
 * make sure that we are consistent. (vzic is the Olson timezone
 * database to VTIMEZONE converter.)
 *
 * The output format is:
 *
 *      Zone-Name [tab] Date [tab] Time [tab] UTC-Offset
 *
 * The Date and Time fields specify the time change in UTC.
 *
 * The UTC Offset is for local (wall-clock) time. It is the amount of time
 * to add to UTC to get local time.
 */
LIBICAL_ICAL_EXPORT int icaltimezone_dump_changes(icaltimezone *zone, int max_year, FILE *fp);

/* For the library only -- do not make visible */
extern const char *icaltimezone_tzid_prefix(void);

#endif /* ICALTIMEZONE_H */
