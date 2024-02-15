/*======================================================================
 FILE: icalcomponent.h
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

/**
 *      @file icalcomponent.h
 */

#ifndef ICALCOMPONENT_H
#define ICALCOMPONENT_H

#include "libical_deprecated.h"
#include "libical_ical_export.h"
#include "icalenums.h"  /* Defines icalcomponent_kind */
#include "icalproperty.h"
#include "pvl.h"

typedef struct icalcomponent_impl icalcomponent;

/* This is exposed so that callers will not have to allocate and
   deallocate iterators. Pretend that you can't see it. */
typedef struct icalcompiter
{
    icalcomponent_kind kind;
    pvl_elem iter;

} icalcompiter;

/** @brief Constructor
 */
LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new(icalcomponent_kind kind);

/**
 * @brief Deeply clones an icalcomponent.
 * Returns a pointer to the memory for the newly cloned icalcomponent.
 * @since 3.1.0
 */
LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_clone(const icalcomponent *component);

/** @brief Constructor
 */
LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_from_string(const char *str);

/** @brief Constructor
 */
LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_vanew(icalcomponent_kind kind, ...);

/** @brief Constructor
 */
LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_x(const char *x_name);

/*** @brief Destructor
 */
LIBICAL_ICAL_EXPORT void icalcomponent_free(icalcomponent *component);

LIBICAL_ICAL_EXPORT char *icalcomponent_as_ical_string(icalcomponent *component);

LIBICAL_ICAL_EXPORT char *icalcomponent_as_ical_string_r(icalcomponent *component);

LIBICAL_ICAL_EXPORT int icalcomponent_is_valid(icalcomponent *component);

LIBICAL_ICAL_EXPORT icalcomponent_kind icalcomponent_isa(const icalcomponent *component);

LIBICAL_ICAL_EXPORT int icalcomponent_isa_component(void *component);

/**
 * @copydoc icalcomponent_clone()
 * @deprecated Use icalcomponent_clone() instead
 */
LIBICAL_ICAL_EXPORT LIBICAL_DEPRECATED(icalcomponent *icalcomponent_new_clone(
                                           icalcomponent *component));

/***** Working with Properties *****/

LIBICAL_ICAL_EXPORT void icalcomponent_add_property(icalcomponent *component,
                                                    icalproperty *property);

LIBICAL_ICAL_EXPORT void icalcomponent_remove_property(icalcomponent *component,
                                                       icalproperty *property);

LIBICAL_ICAL_EXPORT int icalcomponent_count_properties(icalcomponent *component,
                                                       icalproperty_kind kind);

/**
 * @brief Sets the parent icalcomponent for the specified icalproperty @p property.
 * @since 3.0
 */
LIBICAL_ICAL_EXPORT void icalproperty_set_parent(icalproperty *property,
                                                 icalcomponent *component);

/**
 * @brief Returns the parent icalcomponent for the specified @p property.
 */
LIBICAL_ICAL_EXPORT icalcomponent *icalproperty_get_parent(const icalproperty *property);

/* Iterate through the properties */
LIBICAL_ICAL_EXPORT icalproperty *icalcomponent_get_current_property(icalcomponent *component);

LIBICAL_ICAL_EXPORT icalproperty *icalcomponent_get_first_property(icalcomponent *component,
                                                                   icalproperty_kind kind);
LIBICAL_ICAL_EXPORT icalproperty *icalcomponent_get_next_property(icalcomponent *component,
                                                                  icalproperty_kind kind);

/***** Working with Components *****/

/** Return the first VEVENT, VTODO or VJOURNAL sub-component of cop, or
   comp if it is one of those types */
LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_get_inner(icalcomponent *comp);

LIBICAL_ICAL_EXPORT void icalcomponent_add_component(icalcomponent *parent, icalcomponent *child);

LIBICAL_ICAL_EXPORT void icalcomponent_remove_component(icalcomponent *parent,
                                                        icalcomponent *child);

LIBICAL_ICAL_EXPORT int icalcomponent_count_components(icalcomponent *component,
                                                       icalcomponent_kind kind);

/**
 *  This takes 2 VCALENDAR components and merges the second one into the first,
 *  resolving any problems with conflicting TZIDs. comp_to_merge will no
 *  longer exist after calling this function.
 */
LIBICAL_ICAL_EXPORT void icalcomponent_merge_component(icalcomponent *comp,
                                                       icalcomponent *comp_to_merge);

/* Iteration Routines. There are two forms of iterators, internal and
external. The internal ones came first, and are almost completely
sufficient, but they fail badly when you want to construct a loop that
removes components from the container.*/

/* Iterate through components */
LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_get_current_component(icalcomponent *component);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_get_first_component(icalcomponent *component,
                                                                     icalcomponent_kind kind);
LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_get_next_component(icalcomponent *component,
                                                                    icalcomponent_kind kind);

/* Using external iterators */
LIBICAL_ICAL_EXPORT icalcompiter icalcomponent_begin_component(icalcomponent *component,
                                                               icalcomponent_kind kind);

LIBICAL_ICAL_EXPORT icalcompiter icalcomponent_end_component(icalcomponent *component,
                                                             icalcomponent_kind kind);

LIBICAL_ICAL_EXPORT icalcomponent *icalcompiter_next(icalcompiter * i);

LIBICAL_ICAL_EXPORT icalcomponent *icalcompiter_prior(icalcompiter * i);

LIBICAL_ICAL_EXPORT icalcomponent *icalcompiter_deref(icalcompiter * i);

/***** Working with embedded error properties *****/

/* Check the component against itip rules and insert error properties*/
/* Working with embedded error properties */
LIBICAL_ICAL_EXPORT int icalcomponent_check_restrictions(icalcomponent *comp);

/** @brief Returns the number of errors encountered parsing the data.
 *
 * This function counts the number times the X-LIC-ERROR occurs
 * in the data structure.
 */
LIBICAL_ICAL_EXPORT int icalcomponent_count_errors(icalcomponent *component);

/** @brief Removes all X-LIC-ERROR properties*/
LIBICAL_ICAL_EXPORT void icalcomponent_strip_errors(icalcomponent *component);

/** @brief Converts some X-LIC-ERROR properties into RETURN-STATUS properties*/
LIBICAL_ICAL_EXPORT void icalcomponent_convert_errors(icalcomponent *component);

/* Internal operations. They are private, and you should not be using them. */
LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_get_parent(icalcomponent *component);

LIBICAL_ICAL_EXPORT void icalcomponent_set_parent(icalcomponent *component,
                                                  icalcomponent *parent);

/* Kind conversion routines */

LIBICAL_ICAL_EXPORT int icalcomponent_kind_is_valid(const icalcomponent_kind kind);

LIBICAL_ICAL_EXPORT icalcomponent_kind icalcomponent_string_to_kind(const char *string);

LIBICAL_ICAL_EXPORT const char *icalcomponent_kind_to_string(icalcomponent_kind kind);

/************* Derived class methods.  ****************************

If the code was in an OO language, the remaining routines would be
members of classes derived from icalcomponent. Don't call them on the
wrong component subtypes. */

/** @brief Returns a reference to the first VEVENT, VTODO or
 * VJOURNAL in the component.
 */
LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_get_first_real_component(icalcomponent *c);

/**     @brief Gets the timespan covered by this component, in UTC.
 *
 *      See icalcomponent_foreach_recurrence() for a better way to
 *      extract spans from an component.
 *
 *      This method can be called on either a VCALENDAR or any real
 *      component. If the VCALENDAR contains no real component, but
 *      contains a VTIMEZONE, we return that span instead.
 *      This might not be a desirable behavior; we keep it for now
 *      for backward compatibility, but it might be deprecated at a
 *      future time.
 *
 *      FIXME this API needs to be clarified. DTEND is defined as the
 *      first available time after the end of this event, so the span
 *      should actually end 1 second before DTEND.
 */
LIBICAL_ICAL_EXPORT struct icaltime_span icalcomponent_get_span(icalcomponent *comp);

/******************** Convenience routines **********************/

/**     @brief Sets the DTSTART property to the given icaltime,
 *
 *      This method respects the icaltime type (DATE vs DATE-TIME) and
 *      timezone (or lack thereof).
 */
LIBICAL_ICAL_EXPORT void icalcomponent_set_dtstart(icalcomponent *comp, struct icaltimetype v);

/**     @brief Gets the DTSTART property as an icaltime
 *
 *      If DTSTART is a DATE-TIME with a timezone parameter and a
 *      corresponding VTIMEZONE is present in the component, the
 *      returned component will already be in the correct timezone;
 *      otherwise the caller is responsible for converting it.
 *
 *      FIXME this is useless until we can flag the failure
 */
LIBICAL_ICAL_EXPORT struct icaltimetype icalcomponent_get_dtstart(icalcomponent *comp);

/* For the icalcomponent routines only, dtend and duration are tied
   together. If you call the get routine for one and the other exists,
   the routine will calculate the return value. That is, if there is a
   DTEND and you call get_duration, the routine will return the difference
   between DTEND and DTSTART. However, if you call a set routine for
   one and the other exists, no action will be taken and icalerrno will
   be set to ICAL_MALFORMEDDATA_ERROR. If you call a set routine and
   neither exists, the routine will create the appropriate property. */

/**     @brief Gets the DTEND property as an icaltime.
 *
 *      If a DTEND property is not present but a DURATION is, we use
 *      that to determine the proper end.
 *
 *      If DTSTART is a DATE-TIME with a timezone parameter and a
 *      corresponding VTIMEZONE is present in the component, the
 *      returned component will already be in the correct timezone;
 *      otherwise the caller is responsible for converting it.
 *
 *      For the icalcomponent routines only, dtend and duration are tied
 *      together. If you call the get routine for one and the other
 *      exists, the routine will calculate the return value. That is, if
 *      there is a DTEND and you call get_duration, the routine will
 *      return the difference between DTEND and DTSTART.
 *
 *      FIXME this is useless until we can flag the failure
 */
LIBICAL_ICAL_EXPORT struct icaltimetype icalcomponent_get_dtend(icalcomponent *comp);

/**     @brief Sets the DTEND property to given icaltime.
 *
 *      This method respects the icaltime type (DATE vs DATE-TIME) and
 *      timezone (or lack thereof).
 *
 *      This also checks that a DURATION property isn't already there,
 *      and returns an error if it is. It's the caller's responsibility
 *      to remove it.
 *
 *      For the icalcomponent routines only, DTEND and DURATION are tied
 *      together. If you call this routine and DURATION exists, no action
 *      will be taken and icalerrno will be set to ICAL_MALFORMEDDATA_ERROR.
 *      If neither exists, the routine will create the appropriate
 *      property.
 */
LIBICAL_ICAL_EXPORT void icalcomponent_set_dtend(icalcomponent *comp, struct icaltimetype v);

/** @brief Returns the time a VTODO task is DUE.
 *
 *  @param comp Valid calendar component.
 *
 *  Uses the DUE: property if it exists, otherwise we calculate the DUE
 *  value by adding the task's duration to the DTSTART time.
 */
LIBICAL_ICAL_EXPORT struct icaltimetype icalcomponent_get_due(icalcomponent *comp);

/** @brief Sets the due date of a VTODO task.
 *
 *  @param comp Valid VTODO component.
 *  @param v    Valid due date time.
 *
 *  The DUE and DURATION properties are tied together:
 *  - If no duration or due properties then sets the DUE property.
 *  - If a DUE property is already set, then resets it to the value v.
 *  - If a DURATION property is already set, then calculates the new
 *    duration based on the supplied value of @p v.
 */
LIBICAL_ICAL_EXPORT void icalcomponent_set_due(icalcomponent *comp, struct icaltimetype v);

/**     @brief Sets the DURATION property to given icalduration.
 *
 *      This method respects the icaltime type (DATE vs DATE-TIME) and
 *      timezone (or lack thereof).
 *
 *      This also checks that a DTEND property isn't already there,
 *      and returns an error if it is. It's the caller's responsibility
 *      to remove it.
 *
 *      For the icalcomponent routines only, DTEND and DURATION are tied
 *      together. If you call this routine and DTEND exists, no action
 *      will be taken and icalerrno will be set to ICAL_MALFORMEDDATA_ERROR.
 *      If neither exists, the routine will create the appropriate
 *      property.
 */
LIBICAL_ICAL_EXPORT void icalcomponent_set_duration(icalcomponent *comp,
                                                    struct icaldurationtype v);

/**     @brief Gets the DURATION property as an icalduration
 *
 *      For the icalcomponent routines only, DTEND and DURATION are tied
 *      together.
 *      If a DURATION property is not present but a DTEND is, we use
 *      that to determine the proper end.
 *
 *      For the icalcomponent routines only, dtend and duration are tied
 *      together. If you call the get routine for one and the other
 *      exists, the routine will calculate the return value. That is, if
 *      there is a DTEND and you call get_duration, the routine will
 *      return the difference between DTEND and DTSTART.
 */
LIBICAL_ICAL_EXPORT struct icaldurationtype icalcomponent_get_duration(icalcomponent *comp);

/** @brief Sets the METHOD property to the given method.
 */
LIBICAL_ICAL_EXPORT void icalcomponent_set_method(icalcomponent *comp, icalproperty_method method);

/** @brief Returns the METHOD property.
 */
LIBICAL_ICAL_EXPORT icalproperty_method icalcomponent_get_method(icalcomponent *comp);

LIBICAL_ICAL_EXPORT struct icaltimetype icalcomponent_get_dtstamp(icalcomponent *comp);

LIBICAL_ICAL_EXPORT void icalcomponent_set_dtstamp(icalcomponent *comp, struct icaltimetype v);

LIBICAL_ICAL_EXPORT void icalcomponent_set_summary(icalcomponent *comp, const char *v);

LIBICAL_ICAL_EXPORT const char *icalcomponent_get_summary(icalcomponent *comp);

LIBICAL_ICAL_EXPORT void icalcomponent_set_comment(icalcomponent *comp, const char *v);

LIBICAL_ICAL_EXPORT const char *icalcomponent_get_comment(icalcomponent *comp);

LIBICAL_ICAL_EXPORT void icalcomponent_set_uid(icalcomponent *comp, const char *v);

LIBICAL_ICAL_EXPORT const char *icalcomponent_get_uid(icalcomponent *comp);

LIBICAL_ICAL_EXPORT void icalcomponent_set_relcalid(icalcomponent *comp, const char *v);

LIBICAL_ICAL_EXPORT const char *icalcomponent_get_relcalid(icalcomponent *comp);

LIBICAL_ICAL_EXPORT void icalcomponent_set_recurrenceid(icalcomponent *comp,
                                                        struct icaltimetype v);

LIBICAL_ICAL_EXPORT struct icaltimetype icalcomponent_get_recurrenceid(icalcomponent *comp);

LIBICAL_ICAL_EXPORT void icalcomponent_set_description(icalcomponent *comp, const char *v);

LIBICAL_ICAL_EXPORT const char *icalcomponent_get_description(icalcomponent *comp);

LIBICAL_ICAL_EXPORT void icalcomponent_set_location(icalcomponent *comp, const char *v);

LIBICAL_ICAL_EXPORT const char *icalcomponent_get_location(icalcomponent *comp);

LIBICAL_ICAL_EXPORT void icalcomponent_set_sequence(icalcomponent *comp, int v);

LIBICAL_ICAL_EXPORT int icalcomponent_get_sequence(icalcomponent *comp);

LIBICAL_ICAL_EXPORT void icalcomponent_set_status(icalcomponent *comp, enum icalproperty_status v);

LIBICAL_ICAL_EXPORT enum icalproperty_status icalcomponent_get_status(icalcomponent *comp);

/** @brief Calls the given function for each TZID parameter found in the
 *  component, and any subcomponents.
 */
LIBICAL_ICAL_EXPORT void icalcomponent_foreach_tzid(icalcomponent *comp,
                                                    void (*callback) (icalparameter *param,
                                                                      void *data),
                                                    void *callback_data);

/** @brief Returns the icaltimezone in the component corresponding to the
 *  TZID, or NULL if it can't be found.
 */
LIBICAL_ICAL_EXPORT icaltimezone *icalcomponent_get_timezone(icalcomponent *comp,
                                                             const char *tzid);

/**
 * @brief Decides if a recurrence is acceptable.
 *
 * @param comp       A valid icalcomponent.
 * @param dtstart    The base dtstart value for this component.
 * @param recurtime  The time to test against.
 *
 * @return true if the recurrence value is excluded, false otherwise.
 *
 * This function decides if a specific recurrence value is
 * excluded by EXRULE or EXDATE properties.
 *
 * It's not the most efficient code.  You might get better performance
 * if you assume that recurtime is always increasing for each
 * call. Then you could:
 *
 *   - sort the EXDATE values
 *   - save the state of each EXRULE iterator for the next call.
 *
 * In this case though you don't need to worry how you call this
 * function.  It will always return the correct result.
 */
LIBICAL_ICAL_EXPORT int icalproperty_recurrence_is_excluded(icalcomponent *comp,
                                                            struct icaltimetype *dtstart,
                                                            struct icaltimetype *recurtime);

/**
 * @brief Cycles through all recurrences of an event.
 *
 * @param comp           A valid VEVENT component
 * @param start          Ignore timespans before this
 * @param end            Ignore timespans after this
 * @param callback       Function called for each timespan within the range
 * @param callback_data  Pointer passed back to the callback function
 *
 * This function will call the specified callback function for once
 * for the base value of DTSTART, and foreach recurring date/time
 * value.
 *
 * It will filter out events that are specified as an EXDATE or an EXRULE.
 *
 * @todo We do not filter out duplicate RRULES/RDATES
 * @todo We do not handle RDATEs with explicit periods
 */
LIBICAL_ICAL_EXPORT void icalcomponent_foreach_recurrence(icalcomponent *comp,
                                                          struct icaltimetype start,
                                                          struct icaltimetype end,
                                                          void (*callback) (icalcomponent *comp,
                                                                            struct icaltime_span *
                                                                            span, void *data),
                                                          void *callback_data);

/**
 * @brief Normalizes (reorders and sorts the properties) the specified icalcomponent @p comp.
 * @since 3.0
 */
LIBICAL_ICAL_EXPORT void icalcomponent_normalize(icalcomponent *comp);

/**
 * Computes the datetime corresponding to the specified @p icalproperty and @p icalcomponent.
 * If the property is a DATE-TIME with a TZID parameter and a corresponding VTIMEZONE
 * is present in the component, the returned component will already be in the correct
 * timezone; otherwise the caller is responsible for converting it.
 *
 * Call icaltime_is_null_time() on the returned value to detect failures.
 *
 * @since 3.0.5
 */
LIBICAL_ICAL_EXPORT struct icaltimetype icalproperty_get_datetime_with_component(
                                                                          icalproperty *prop,
                                                                          icalcomponent *comp);
/*************** Type Specific routines ***************/

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vcalendar(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vevent(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vtodo(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vjournal(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_valarm(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vfreebusy(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vtimezone(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_xstandard(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_xdaylight(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vagenda(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vquery(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vavailability(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_xavailable(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vpoll(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vvoter(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_xvote(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_vpatch(void);

LIBICAL_ICAL_EXPORT icalcomponent *icalcomponent_new_xpatch(void);

#endif /* !ICALCOMPONENT_H */
