/*-
 * Copyright (c) 2009 The NetBSD Foundation, Inc.
 * All rights reserved.
 *
 * This code is derived from software contributed to The NetBSD Foundation
 * by Alistair Crooks (agc@NetBSD.org)
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE NETBSD FOUNDATION, INC. AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE FOUNDATION OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
/*
 * Copyright (c) 2005-2008 Nominet UK (www.nic.uk)
 * All rights reserved.
 * Contributors: Ben Laurie, Rachel Willmer. The Contributors have asserted
 * their moral rights under the UK Copyright Design and Patents Act 1988 to
 * be recorded as the authors of this copyright work.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License.
 *
 * You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/** \file
 */

#ifndef PACKET_SHOW_H_
#define PACKET_SHOW_H_

#include "packet.h"

/** __ops_list_t
 */
typedef struct {
	unsigned    size;	/* num of array slots allocated */
	unsigned    used;	/* num of array slots currently used */
	char          **strings;
} __ops_list_t;

/** __ops_text_t
 */
typedef struct {
	__ops_list_t	known;
	__ops_list_t   	unknown;
} __ops_text_t;

/** __ops_bit_map_t
 */
typedef struct {
	uint8_t		mask;
	const char     *string;
} __ops_bit_map_t;

void __ops_text_init(__ops_text_t *);
void __ops_text_free(__ops_text_t *);

const char *__ops_show_packet_tag(__ops_content_enum);
const char *__ops_show_ss_type(__ops_content_enum);

const char *__ops_show_sig_type(__ops_sig_type_t);
const char *__ops_show_pka(__ops_pubkey_alg_t);

__ops_text_t *__ops_showall_ss_zpref(const __ops_data_t *);
const char *__ops_show_ss_zpref(uint8_t);

__ops_text_t *__ops_showall_ss_hashpref(const __ops_data_t *);
const char *__ops_show_hash_alg(uint8_t);
const char *__ops_show_symm_alg(uint8_t);

__ops_text_t *__ops_showall_ss_skapref(const __ops_data_t *);
const char *__ops_show_ss_skapref(uint8_t);

const char *__ops_show_ss_rr_code(__ops_ss_rr_code_t);

__ops_text_t *__ops_showall_ss_features(__ops_data_t);

__ops_text_t *__ops_showall_ss_key_flags(const __ops_data_t *);
const char *__ops_show_ss_key_flag(uint8_t, __ops_bit_map_t *);

__ops_text_t *__ops_show_keyserv_prefs(const __ops_data_t *);
const char *__ops_show_keyserv_pref(uint8_t, __ops_bit_map_t *);

__ops_text_t *__ops_showall_notation(__ops_ss_notation_t);

#endif /* PACKET_SHOW_H_ */
