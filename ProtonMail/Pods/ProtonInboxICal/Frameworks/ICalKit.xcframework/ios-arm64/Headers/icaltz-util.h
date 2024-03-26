/*
 * Authors :
 *  Chenthill Palanisamy <pchenthill@novell.com>
 *
 * Copyright 2007, Novell, Inc.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the terms of either:
 *
 *   The LGPL as published by the Free Software Foundation, version
 *   2.1, available at: https://www.gnu.org/licenses/lgpl-2.1.html
 *
 * Or:
 *
 *   The Mozilla Public License Version 2.0. You may obtain a copy of
 *   the License at https://www.mozilla.org/MPL/
 */

#ifndef ICALTZUTIL_H
#define ICALTZUTIL_H

#include "libical_ical_export.h"
#include "icalcomponent.h"

#if defined(sun) && defined(__SVR4)
#define ZONES_TAB_SYSTEM_FILENAME "tab/zone_sun.tab"
#else
#define ZONES_TAB_SYSTEM_FILENAME "zone.tab"
#endif

/**
 * Returns the fullpath to the system zoneinfo directory (where zone.tab lives).
 * The returned value points to static memory inside the library and should not try to be freed.
 *
 * If the TZDIR variable appears in the environment, it will be searched first for zone.tab.
 * If zone.tab is not located in TZDIR (or if TZDIR is not in the environment), then a
 * list of well-known paths where the system zone.tab typically is installed is searched.
 */
LIBICAL_ICAL_EXPORT const char *icaltzutil_get_zone_directory(void);

/**
 * Sets the fullpath to the zoneinfo directory (zone.tab must reside in there).
 * @param A const character string containing the fullpath to the zoneinfo directory.
 *
 * The internal zoneinfo path can be cleared if @p zonepath is empty or NULL.
 * @since 3.1
 */
LIBICAL_ICAL_EXPORT void icaltzutil_set_zone_directory(const char *zonepath);

/**
 * Returns a pointer to a timezone icalcomponent corresponding to the specified location
 * (a file residing in the zoneinfo).
 *
 * @param location is a string containing the name of a location with a timezone file
 *        found under the zoneinfo data.
 */
LIBICAL_ICAL_EXPORT icalcomponent *icaltzutil_fetch_timezone(const char *location);

#endif
