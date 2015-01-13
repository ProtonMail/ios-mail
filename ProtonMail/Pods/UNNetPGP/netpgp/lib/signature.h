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

#ifndef SIGNATURE_H_
#define SIGNATURE_H_

#include <sys/types.h>

#include <inttypes.h>

#include "packet.h"
#include "create.h"
#include "memory.h"

typedef struct __ops_create_sig_t	 __ops_create_sig_t;

__ops_create_sig_t *__ops_create_sig_new(void);
void __ops_create_sig_delete(__ops_create_sig_t *);

unsigned __ops_check_useridcert_sig(const __ops_pubkey_t *,
			  const uint8_t *,
			  const __ops_sig_t *,
			  const __ops_pubkey_t *,
			  const uint8_t *);
unsigned __ops_check_userattrcert_sig(const __ops_pubkey_t *,
			  const __ops_data_t *,
			  const __ops_sig_t *,
			  const __ops_pubkey_t *,
			  const uint8_t *);
unsigned __ops_check_subkey_sig(const __ops_pubkey_t *,
			   const __ops_pubkey_t *,
			   const __ops_sig_t *,
			   const __ops_pubkey_t *,
			   const uint8_t *);
unsigned __ops_check_direct_sig(const __ops_pubkey_t *,
			   const __ops_sig_t *,
			   const __ops_pubkey_t *,
			   const uint8_t *);
unsigned __ops_check_hash_sig(__ops_hash_t *,
			 const __ops_sig_t *,
			 const __ops_pubkey_t *);
void __ops_sig_start_key_sig(__ops_create_sig_t *,
				  const __ops_pubkey_t *,
				  const uint8_t *,
				  __ops_sig_type_t);
void __ops_start_sig(__ops_create_sig_t *,
			const __ops_seckey_t *,
			const __ops_hash_alg_t,
			const __ops_sig_type_t);

void __ops_sig_add_data(__ops_create_sig_t *, const void *, size_t);
__ops_hash_t *__ops_sig_get_hash(__ops_create_sig_t *);
unsigned   __ops_end_hashed_subpkts(__ops_create_sig_t *);
unsigned __ops_write_sig(__ops_output_t *, __ops_create_sig_t *,
			const __ops_pubkey_t *, const __ops_seckey_t *);
unsigned   __ops_add_time(__ops_create_sig_t *, int64_t, const char *);
unsigned __ops_add_issuer_keyid(__ops_create_sig_t *,
			const uint8_t *);
void __ops_add_primary_userid(__ops_create_sig_t *, unsigned);

/* Standard Interface */
unsigned   __ops_sign_file(__ops_io_t *,
			const char *,
			const char *,
			const __ops_seckey_t *,
			const char *,
			const int64_t,
			const uint64_t,
			const unsigned,
			const unsigned,
			const unsigned);

int __ops_sign_detached(__ops_io_t *,
			const char *,
			char *,
			__ops_seckey_t *,
			const char *,
			const int64_t,
			const uint64_t,
			const unsigned,
			const unsigned);

/* armoured stuff */
unsigned __ops_crc24(unsigned, uint8_t);

void __ops_reader_push_dearmour(__ops_stream_t *);

void __ops_reader_pop_dearmour(__ops_stream_t *);
unsigned __ops_writer_push_clearsigned(__ops_output_t *, __ops_create_sig_t *);
void __ops_writer_push_armor_msg(__ops_output_t *);

typedef enum {
	OPS_PGP_MESSAGE = 1,
	OPS_PGP_PUBLIC_KEY_BLOCK,
	OPS_PGP_PRIVATE_KEY_BLOCK,
	OPS_PGP_MULTIPART_MESSAGE_PART_X_OF_Y,
	OPS_PGP_MULTIPART_MESSAGE_PART_X,
	OPS_PGP_SIGNATURE
} __ops_armor_type_t;

#define CRC24_INIT 0xb704ceL

unsigned __ops_writer_use_armored_sig(__ops_output_t *);

void __ops_writer_push_armoured(__ops_output_t *, __ops_armor_type_t);

__ops_memory_t   *__ops_sign_buf(__ops_io_t *,
				const void *,
				const size_t,
				const __ops_seckey_t *,
				const int64_t,
				const uint64_t,
				const char *,
				const unsigned,
				const unsigned);

unsigned __ops_keyring_read_from_mem(__ops_io_t *,
				__ops_keyring_t *,
				const unsigned,
				__ops_memory_t *);

#endif /* SIGNATURE_H_ */
