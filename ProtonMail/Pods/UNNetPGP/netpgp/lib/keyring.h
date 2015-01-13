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

#ifndef KEYRING_H_
#define KEYRING_H_

#include "packet.h"
#include "packet-parse.h"
#include "mj.h"

enum {
	MAX_ID_LENGTH		= 128,
	MAX_PASSPHRASE_LENGTH	= 256
};

typedef struct __ops_key_t	__ops_key_t;

/** \struct __ops_keyring_t
 * A keyring
 */
typedef struct __ops_keyring_t {
	DYNARRAY(__ops_key_t,	key);
	__ops_hash_alg_t	hashtype;
} __ops_keyring_t;

const __ops_key_t *__ops_getkeybyid(__ops_io_t *,
					const __ops_keyring_t *,
					const uint8_t *,
					unsigned *,
					__ops_pubkey_t **);
const __ops_key_t *__ops_getkeybyname(__ops_io_t *,
					const __ops_keyring_t *,
					const char *);
const __ops_key_t *__ops_getnextkeybyname(__ops_io_t *,
					const __ops_keyring_t *,
					const char *,
					unsigned *);
void __ops_keydata_free(__ops_key_t *);
void __ops_keyring_free(__ops_keyring_t *);
void __ops_dump_keyring(const __ops_keyring_t *);
const __ops_pubkey_t *__ops_get_pubkey(const __ops_key_t *);
unsigned   __ops_is_key_secret(const __ops_key_t *);
const __ops_seckey_t *__ops_get_seckey(const __ops_key_t *);
__ops_seckey_t *__ops_get_writable_seckey(__ops_key_t *);
__ops_seckey_t *__ops_decrypt_seckey(const __ops_key_t *, void *);

unsigned   __ops_keyring_fileread(__ops_keyring_t *, const unsigned,
					const char *);

int __ops_keyring_list(__ops_io_t *, const __ops_keyring_t *, const int);
int __ops_keyring_json(__ops_io_t *, const __ops_keyring_t *, mj_t *, const int);

void __ops_set_seckey(__ops_contents_t *, const __ops_key_t *);
void __ops_forget(void *, unsigned);

const uint8_t *__ops_get_key_id(const __ops_key_t *);
unsigned __ops_get_userid_count(const __ops_key_t *);
const uint8_t *__ops_get_userid(const __ops_key_t *, unsigned);
unsigned __ops_is_key_supported(const __ops_key_t *);

uint8_t *__ops_add_userid(__ops_key_t *, const uint8_t *);
__ops_subpacket_t *__ops_add_subpacket(__ops_key_t *,
						const __ops_subpacket_t *);

unsigned __ops_add_selfsigned_userid(__ops_key_t *, uint8_t *);

__ops_key_t  *__ops_keydata_new(void);
void __ops_keydata_init(__ops_key_t *, const __ops_content_enum);

int __ops_parse_and_accumulate(__ops_keyring_t *, __ops_stream_t *);

int __ops_sprint_keydata(__ops_io_t *, const __ops_keyring_t *,
			const __ops_key_t *, char **, const char *,
			const __ops_pubkey_t *, const int);
int __ops_sprint_mj(__ops_io_t *, const __ops_keyring_t *,
			const __ops_key_t *, mj_t *, const char *,
			const __ops_pubkey_t *, const int);
int __ops_hkp_sprint_keydata(__ops_io_t *, const __ops_keyring_t *,
			const __ops_key_t *, char **,
			const __ops_pubkey_t *, const int);
void __ops_print_keydata(__ops_io_t *, const __ops_keyring_t *, const __ops_key_t *,
			const char *, const __ops_pubkey_t *, const int);
void __ops_print_sig(__ops_io_t *, const __ops_key_t *, const char *,
			const __ops_pubkey_t *);
void __ops_print_pubkey(const __ops_pubkey_t *);
int __ops_sprint_pubkey(const __ops_key_t *, char *, size_t);

int __ops_list_packets(__ops_io_t *,
			char *,
			unsigned,
			__ops_keyring_t *,
			__ops_keyring_t *,
			void *,
			__ops_cbfunc_t *);

char *__ops_export_key(__ops_io_t *, const __ops_key_t *, uint8_t *);

int __ops_add_to_pubring(__ops_keyring_t *, const __ops_pubkey_t *, __ops_content_enum tag);
int __ops_add_to_secring(__ops_keyring_t *, const __ops_seckey_t *);

int __ops_append_keyring(__ops_keyring_t *, __ops_keyring_t *);

#endif /* KEYRING_H_ */
