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
#ifndef VALIDATE_H_
#define VALIDATE_H_	1

typedef struct {
	const __ops_key_t	*key;
	unsigned	         packet;
	unsigned	         offset;
} validate_reader_t;

/** Struct used with the validate_key_cb callback */
typedef struct {
	__ops_pubkey_t		 pubkey;
	__ops_pubkey_t		 subkey;
	__ops_seckey_t		 seckey;
	enum {
		ATTRIBUTE = 1,
		ID
	}               	 last_seen;
	uint8_t			*userid;
	__ops_data_t		 userattr;
	uint8_t			 hash[OPS_MAX_HASH_SIZE];
	const __ops_keyring_t	*keyring;
	validate_reader_t	*reader;
	__ops_validation_t	*result;
	__ops_cb_ret_t(*getpassphrase) (const __ops_packet_t *,
						__ops_cbdata_t *);
} validate_key_cb_t;

/** Struct use with the validate_data_cb callback */
typedef struct {
	enum {
		LITDATA,
		SIGNED_CLEARTEXT
	} type;
	union {
		__ops_litdata_body_t	 litdata_body;
		__ops_fixed_body_t	 cleartext_body;
	} data;
	uint8_t			 	 hash[OPS_MAX_HASH_SIZE];
	__ops_memory_t			*mem;
	const __ops_keyring_t		*keyring;
	validate_reader_t		*reader;/* reader-specific arg */
	__ops_validation_t		*result;
	char				*detachname;
} validate_data_cb_t;

void __ops_keydata_reader_set(__ops_stream_t *, const __ops_key_t *);

__ops_cb_ret_t __ops_validate_key_cb(const __ops_packet_t *, __ops_cbdata_t *);

unsigned check_binary_sig(const uint8_t *,
		const unsigned,
		const __ops_sig_t *,
		const __ops_pubkey_t *);

unsigned   __ops_validate_file(__ops_io_t *,
			__ops_validation_t *,
			const char *,
			const char *,
			const int,
			const __ops_keyring_t *);

unsigned   __ops_validate_mem(__ops_io_t *,
			__ops_validation_t *,
			__ops_memory_t *,
			__ops_memory_t **,
			const int,
			const __ops_keyring_t *);

__ops_cb_ret_t validate_data_cb(const __ops_packet_t *, __ops_cbdata_t *);

#endif /* !VALIDATE_H_ */
