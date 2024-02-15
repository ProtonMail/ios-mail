/*======================================================================
 FILE: qsort_gen.h

 (C) COPYRIGHT 2018, Markus Minichmayr <markus@tapkey.com>

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: https://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at https://www.mozilla.org/MPL/

 The Initial Developer of the Original Code is Markus Minichmayr.
======================================================================*/

#ifndef QSORT_GEN_H
#define QSORT_GEN_H

/**
 * @file qsort_gen.h
 * @brief An implementation of qsort that is more flexible than the version
 * provided with stdlib.
 *
 * In contrast to the qsort provided with stdlib, this version doesn't assume
 * that the data to be sorted is stored in a contiguous block of memory.
 */

/**
 * @brief Sort an arbitrary list of items using the qsort algorithm.
 * @param context A pointer representing the list to be sorted. Won't be
 * interpreted by this function but passed to the compar and swapr functions.
 * @param nitems The number of items in the list.
 * @param compar The comparator function. The function receives the pointer
 * to the list to be sorted and the indices of the elements to be compared.
 * @param swapr The function used to swap two elements within the list. The
 * function receives the pointer to the list to be sorted and the indices of
 * the elements to be compared.
 */
void qsort_gen(void *list, size_t nitems,
               int(*compar)(const void *, size_t, size_t),
               void(*swapr)(void *, size_t, size_t));

/**
 * @brief Swaps two arbitrary blocks of memory.
 * @param m1 Pointer to the first block of memory.
 * @param m2 Pointer to the second block of memory.
 * @param size Size of the memory blocks to be swapped.
 */
void qsort_gen_memswap(void *m1, void *m2, size_t size);

#endif /* QSORT_GEN_H */
