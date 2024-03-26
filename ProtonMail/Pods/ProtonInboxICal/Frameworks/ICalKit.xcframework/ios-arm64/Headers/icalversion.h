/*======================================================================
 FILE: icalversion.h
 CREATOR: eric 20 March 1999

 (C) COPYRIGHT 2000, Eric Busboom <eric@civicknowledge.com>

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: https://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at https://www.mozilla.org/MPL/
 ======================================================================*/

#ifndef ICAL_VERSION_H
#define ICAL_VERSION_H

#define ICAL_PACKAGE "libical"
#define ICAL_VERSION "3.0"

#define ICAL_MAJOR_VERSION (3)
#define ICAL_MINOR_VERSION (0)
#define ICAL_PATCH_VERSION (95)
#define ICAL_MICRO_VERSION ICAL_PATCH_VERSION

/**
 * ICAL_CHECK_VERSION:
 * @param major: major version (e.g. 1 for version 1.2.5)
 * @param minor: minor version (e.g. 2 for version 1.2.5)
 * @param micro: micro version (e.g. 5 for version 1.2.5)
 *
 * @return TRUE if the version of the LIBICAL header files
 * is the same as or newer than the passed-in version.
 */
#define ICAL_CHECK_VERSION(major,minor,micro)                          \
    (ICAL_MAJOR_VERSION > (major) ||                                   \
    (ICAL_MAJOR_VERSION == (major) && ICAL_MINOR_VERSION > (minor)) || \
    (ICAL_MAJOR_VERSION == (major) && ICAL_MINOR_VERSION == (minor) && \
    ICAL_MICRO_VERSION >= (micro)))

#endif
