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
#include "config.h"

#ifdef HAVE_SYS_CDEFS_H
#include <sys/cdefs.h>
#endif

#if defined(__NetBSD__)
__COPYRIGHT("@(#) Copyright (c) 2009 The NetBSD Foundation, Inc. All rights reserved.");
__RCSID("$NetBSD: create.c,v 1.36 2010/11/07 02:29:28 agc Exp $");
#endif

#include <sys/types.h>
#include <sys/param.h>
#include <sys/stat.h>

#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif

#include <string.h>

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

#ifdef HAVE_OPENSSL_CAST_H
#include <openssl/cast.h>
#endif

#include "create.h"
#include "keyring.h"
#include "packet.h"
#include "signature.h"
#include "writer.h"
#include "readerwriter.h"
#include "memory.h"
#include "netpgpdefs.h"
#include "netpgpdigest.h"

/**
 * \ingroup Core_Create
 * \param length
 * \param type
 * \param output
 * \return 1 if OK, otherwise 0
 */

unsigned 
__ops_write_ss_header(__ops_output_t *output,
			unsigned length,
			__ops_content_enum type)
{
	return __ops_write_length(output, length) &&
		__ops_write_scalar(output, (unsigned)(type -
				(unsigned)OPS_PTAG_SIG_SUBPKT_BASE), 1);
}

/*
 * XXX: the general idea of _fast_ is that it doesn't copy stuff the safe
 * (i.e. non _fast_) version will, and so will also need to be freed.
 */

/**
 * \ingroup Core_Create
 *
 * __ops_fast_create_userid() sets id->userid to the given userid.
 * This is fast because it is only copying a char*. However, if userid
 * is changed or freed in the future, this could have injurious results.
 * \param id
 * \param userid
 */

void 
__ops_fast_create_userid(uint8_t **id, uint8_t *userid)
{
	*id = userid;
}

/**
 * \ingroup Core_WritePackets
 * \brief Writes a User Id packet
 * \param id
 * \param output
 * \return 1 if OK, otherwise 0
 */
unsigned 
__ops_write_struct_userid(__ops_output_t *output, const uint8_t *id)
{
	return __ops_write_ptag(output, OPS_PTAG_CT_USER_ID) &&
		__ops_write_length(output, (unsigned)strlen((const char *) id)) &&
		__ops_write(output, id, (unsigned)strlen((const char *) id));
}

/**
 * \ingroup Core_WritePackets
 * \brief Write a User Id packet.
 * \param userid
 * \param output
 *
 * \return return value from __ops_write_struct_userid()
 */
unsigned 
__ops_write_userid(const uint8_t *userid, __ops_output_t *output)
{
	return __ops_write_struct_userid(output, userid);
}

/**
\ingroup Core_MPI
*/
static unsigned 
mpi_length(const BIGNUM *bn)
{
	return (unsigned)(2 + (BN_num_bits(bn) + 7) / 8);
}

static unsigned 
pubkey_length(const __ops_pubkey_t *key)
{
	switch (key->alg) {
	case OPS_PKA_DSA:
		return mpi_length(key->key.dsa.p) + mpi_length(key->key.dsa.q) +
			mpi_length(key->key.dsa.g) + mpi_length(key->key.dsa.y);

	case OPS_PKA_RSA:
		return mpi_length(key->key.rsa.n) + mpi_length(key->key.rsa.e);

	default:
		(void) fprintf(stderr,
			"pubkey_length: unknown key algorithm\n");
	}
	return 0;
}

static unsigned 
seckey_length(const __ops_seckey_t *key)
{
	int             len;

	len = 0;
	switch (key->pubkey.alg) {
	case OPS_PKA_DSA:
		return (unsigned)(mpi_length(key->key.dsa.x) + pubkey_length(&key->pubkey));
	case OPS_PKA_RSA:
		len = mpi_length(key->key.rsa.d) + mpi_length(key->key.rsa.p) +
			mpi_length(key->key.rsa.q) + mpi_length(key->key.rsa.u);

		return (unsigned)(len + pubkey_length(&key->pubkey));
	default:
		(void) fprintf(stderr,
			"seckey_length: unknown key algorithm\n");
	}
	return 0;
}

/**
 * \ingroup Core_Create
 * \param key
 * \param t
 * \param n
 * \param e
*/
void 
__ops_fast_create_rsa_pubkey(__ops_pubkey_t *key, time_t t,
			       BIGNUM *n, BIGNUM *e)
{
	key->version = OPS_V4;
	key->birthtime = t;
	key->alg = OPS_PKA_RSA;
	key->key.rsa.n = n;
	key->key.rsa.e = e;
}

/*
 * Note that we support v3 keys here because they're needed for for
 * verification - the writer doesn't allow them, though
 */
static unsigned 
write_pubkey_body(const __ops_pubkey_t *key, __ops_output_t *output)
{
	if (!(__ops_write_scalar(output, (unsigned)key->version, 1) &&
	      __ops_write_scalar(output, (unsigned)key->birthtime, 4))) {
		return 0;
	}

	if (key->version != 4 &&
	    !__ops_write_scalar(output, key->days_valid, 2)) {
		return 0;
	}

	if (!__ops_write_scalar(output, (unsigned)key->alg, 1)) {
		return 0;
	}

	switch (key->alg) {
	case OPS_PKA_DSA:
		return __ops_write_mpi(output, key->key.dsa.p) &&
			__ops_write_mpi(output, key->key.dsa.q) &&
			__ops_write_mpi(output, key->key.dsa.g) &&
			__ops_write_mpi(output, key->key.dsa.y);

	case OPS_PKA_RSA:
	case OPS_PKA_RSA_ENCRYPT_ONLY:
	case OPS_PKA_RSA_SIGN_ONLY:
		return __ops_write_mpi(output, key->key.rsa.n) &&
			__ops_write_mpi(output, key->key.rsa.e);

	case OPS_PKA_ELGAMAL:
		return __ops_write_mpi(output, key->key.elgamal.p) &&
			__ops_write_mpi(output, key->key.elgamal.g) &&
			__ops_write_mpi(output, key->key.elgamal.y);

	default:
		(void) fprintf(stderr,
			"write_pubkey_body: bad algorithm\n");
		break;
	}
	return 0;
}

/*
 * Note that we support v3 keys here because they're needed for
 * verification.
 */
static unsigned 
write_seckey_body(const __ops_seckey_t *key,
		      const uint8_t *passphrase,
		      const size_t pplen,
		      __ops_output_t *output)
{
	/* RFC4880 Section 5.5.3 Secret-Key Packet Formats */

	__ops_crypt_t   crypted;
	__ops_hash_t    hash;
	unsigned	done = 0;
	unsigned	i = 0;
	uint8_t		hashed[OPS_SHA1_HASH_SIZE];
	uint8_t		sesskey[CAST_KEY_LENGTH];

	if (!write_pubkey_body(&key->pubkey, output)) {
		return 0;
	}
	if (key->s2k_usage != OPS_S2KU_ENCRYPTED_AND_HASHED) {
		(void) fprintf(stderr, "write_seckey_body: s2k usage\n");
		return 0;
	}
	if (!__ops_write_scalar(output, (unsigned)key->s2k_usage, 1)) {
		return 0;
	}

	if (key->alg != OPS_SA_CAST5) {
		(void) fprintf(stderr, "write_seckey_body: algorithm\n");
		return 0;
	}
	if (!__ops_write_scalar(output, (unsigned)key->alg, 1)) {
		return 0;
	}

	if (key->s2k_specifier != OPS_S2KS_SIMPLE &&
	    key->s2k_specifier != OPS_S2KS_SALTED) {
		/* = 1 \todo could also be iterated-and-salted */
		(void) fprintf(stderr, "write_seckey_body: s2k spec\n");
		return 0;
	}
	if (!__ops_write_scalar(output, (unsigned)key->s2k_specifier, 1)) {
		return 0;
	}
	if (!__ops_write_scalar(output, (unsigned)key->hash_alg, 1)) {
		return 0;
	}

	switch (key->s2k_specifier) {
	case OPS_S2KS_SIMPLE:
		/* nothing more to do */
		break;

	case OPS_S2KS_SALTED:
		/* 8-octet salt value */
		__ops_random(__UNCONST(&key->salt[0]), OPS_SALT_SIZE);
		if (!__ops_write(output, key->salt, OPS_SALT_SIZE)) {
			return 0;
		}
		break;

		/*
		 * \todo case OPS_S2KS_ITERATED_AND_SALTED: // 8-octet salt
		 * value // 1-octet count break;
		 */

	default:
		(void) fprintf(stderr,
			"invalid/unsupported s2k specifier %d\n",
			key->s2k_specifier);
		return 0;
	}

	if (!__ops_write(output, &key->iv[0], __ops_block_size(key->alg))) {
		return 0;
	}

	/*
	 * create the session key for encrypting the algorithm-specific
	 * fields
	 */

	switch (key->s2k_specifier) {
	case OPS_S2KS_SIMPLE:
	case OPS_S2KS_SALTED:
		/* RFC4880: section 3.7.1.1 and 3.7.1.2 */

		for (done = 0, i = 0; done < CAST_KEY_LENGTH; i++) {
			unsigned 	j;
			uint8_t		zero = 0;
			int             needed;
			int             size;

			needed = CAST_KEY_LENGTH - done;
			size = MIN(needed, OPS_SHA1_HASH_SIZE);

			__ops_hash_any(&hash, key->hash_alg);
			if (!hash.init(&hash)) {
				(void) fprintf(stderr, "write_seckey_body: bad alloc\n");
				return 0;
			}

			/* preload if iterating  */
			for (j = 0; j < i; j++) {
				/*
				 * Coverity shows a DEADCODE error on this
				 * line. This is expected since the hardcoded
				 * use of SHA1 and CAST5 means that it will
				 * not used. This will change however when
				 * other algorithms are supported.
				 */
				hash.add(&hash, &zero, 1);
			}

			if (key->s2k_specifier == OPS_S2KS_SALTED) {
				hash.add(&hash, key->salt, OPS_SALT_SIZE);
			}
			hash.add(&hash, passphrase, (unsigned)pplen);
			hash.finish(&hash, hashed); // this is crashing 'i' value is completly wrong after this

			/*
			 * if more in hash than is needed by session key, use
			 * the leftmost octets
			 */
			(void) memcpy(&sesskey[i * OPS_SHA1_HASH_SIZE],
					hashed, (unsigned)size);
			done += (unsigned)size;
			if (done > CAST_KEY_LENGTH) {
				(void) fprintf(stderr,
					"write_seckey_body: short add\n");
				return 0;
			}
		}

		break;

		/*
		 * \todo case OPS_S2KS_ITERATED_AND_SALTED: * 8-octet salt
		 * value * 1-octet count break;
		 */

	default:
		(void) fprintf(stderr,
			"invalid/unsupported s2k specifier %d\n",
			key->s2k_specifier);
		return 0;
	}

	/* use this session key to encrypt */

	__ops_crypt_any(&crypted, key->alg);
	crypted.set_iv(&crypted, key->iv);
	crypted.set_crypt_key(&crypted, sesskey);
	__ops_encrypt_init(&crypted);

	if (__ops_get_debug_level(__FILE__)) {
		hexdump(stderr, "writing: iv=", key->iv, __ops_block_size(key->alg));
		hexdump(stderr, "key= ", sesskey, CAST_KEY_LENGTH);
		(void) fprintf(stderr, "\nturning encryption on...\n");
	}
	__ops_push_enc_crypt(output, &crypted);

	switch (key->pubkey.alg) {
		/* case OPS_PKA_DSA: */
		/* return __ops_write_mpi(output, key->key.dsa.x); */

	case OPS_PKA_RSA:
	case OPS_PKA_RSA_ENCRYPT_ONLY:
	case OPS_PKA_RSA_SIGN_ONLY:

		if (!__ops_write_mpi(output, key->key.rsa.d) ||
		    !__ops_write_mpi(output, key->key.rsa.p) ||
		    !__ops_write_mpi(output, key->key.rsa.q) ||
		    !__ops_write_mpi(output, key->key.rsa.u)) {
			if (__ops_get_debug_level(__FILE__)) {
				(void) fprintf(stderr,
					"4 x mpi not written - problem\n");
			}
			return 0;
		}
		break;
	case OPS_PKA_DSA:
		return __ops_write_mpi(output, key->key.dsa.x);
	case OPS_PKA_ELGAMAL:
		return __ops_write_mpi(output, key->key.elgamal.x);
	default:
		return 0;
	}

	if (!__ops_write(output, key->checkhash, OPS_CHECKHASH_SIZE)) {
		return 0;
	}

	__ops_writer_pop(output);

	return 1;
}

/**
 * \ingroup Core_WritePackets
 * \brief Writes a Public Key packet
 * \param key
 * \param output
 * \return 1 if OK, otherwise 0
 */
static unsigned 
write_struct_pubkey(__ops_output_t *output, const __ops_pubkey_t *key)
{
	return __ops_write_ptag(output, OPS_PTAG_CT_PUBLIC_KEY) &&
		__ops_write_length(output, 1 + 4 + 1 + pubkey_length(key)) &&
		write_pubkey_body(key, output);
}


/**
   \ingroup HighLevel_KeyWrite

   \brief Writes a transferable PGP public key to the given output stream.

   \param keydata Key to be written
   \param armoured Flag is set for armoured output
   \param output Output stream

*/

unsigned 
__ops_write_xfer_pubkey(__ops_output_t *output,
			const __ops_key_t *key,
			const unsigned armoured)
{
	unsigned    i, j;

	if (armoured) {
		__ops_writer_push_armoured(output, OPS_PGP_PUBLIC_KEY_BLOCK);
	}
	/* public key */
	if (!write_struct_pubkey(output, &key->key.pubkey)) {
		return 0;
	}

	/* TODO: revocation signatures go here */

	/* user ids and corresponding signatures */
	for (i = 0; i < key->uidc; i++) {
		if (!__ops_write_struct_userid(output, key->uids[i])) {
			return 0;
		}
		for (j = 0; j < key->packetc; j++) {
			if (!__ops_write(output, key->packets[j].raw, (unsigned)key->packets[j].length)) {
				return 0;
			}
		}
	}

	/* TODO: user attributes and corresponding signatures */

	/*
	 * subkey packets and corresponding signatures and optional
	 * revocation
	 */

	if (armoured) {
		__ops_writer_info_finalise(&output->errors, &output->writer);
		__ops_writer_pop(output);
	}
	return 1;
}

/**
   \ingroup HighLevel_KeyWrite

   \brief Writes a transferable PGP secret key to the given output stream.

   \param keydata Key to be written
   \param passphrase
   \param pplen
   \param armoured Flag is set for armoured output
   \param output Output stream

*/

unsigned 
__ops_write_xfer_seckey(__ops_output_t *output,
				const __ops_key_t *key,
				const uint8_t *passphrase,
				const size_t pplen,
				unsigned armoured)
{
	unsigned	i, j;

	if (armoured) {
		__ops_writer_push_armoured(output, OPS_PGP_PRIVATE_KEY_BLOCK);
	}
	/* public key */
	if (!__ops_write_struct_seckey(&key->key.seckey, passphrase,
			pplen, output)) {
		return 0;
	}

	/* TODO: revocation signatures go here */

	/* user ids and corresponding signatures */
	for (i = 0; i < key->uidc; i++) {
		if (!__ops_write_struct_userid(output, key->uids[i])) {
			return 0;
		}
		for (j = 0; j < key->packetc; j++) {
			if (!__ops_write(output, key->packets[j].raw, (unsigned)key->packets[j].length)) {
				return 0;
			}
		}
	}

	/* TODO: user attributes and corresponding signatures */

	/*
	 * subkey packets and corresponding signatures and optional
	 * revocation
	 */

	if (armoured) {
		__ops_writer_info_finalise(&output->errors, &output->writer);
		__ops_writer_pop(output);
	}
	return 1;
}

/**
 * \ingroup Core_WritePackets
 * \brief Writes one RSA public key packet.
 * \param t Creation time
 * \param n RSA public modulus
 * \param e RSA public encryption exponent
 * \param output Writer settings
 *
 * \return 1 if OK, otherwise 0
 */

unsigned 
__ops_write_rsa_pubkey(time_t t, const BIGNUM *n,
			 const BIGNUM *e,
			 __ops_output_t *output)
{
	__ops_pubkey_t key;

	__ops_fast_create_rsa_pubkey(&key, t, __UNCONST(n), __UNCONST(e));
	return write_struct_pubkey(output, &key);
}

/**
 * \ingroup Core_Create
 * \param out
 * \param key
 * \param make_packet
 */

void 
__ops_build_pubkey(__ops_memory_t *out, const __ops_pubkey_t *key,
		     unsigned make_packet)
{
	__ops_output_t *output;

	output = __ops_output_new();
	__ops_memory_init(out, 128);
	__ops_writer_set_memory(output, out);
	write_pubkey_body(key, output);
	if (make_packet) {
		__ops_memory_make_packet(out, OPS_PTAG_CT_PUBLIC_KEY);
	}
	__ops_output_delete(output);
}

/**
 * \ingroup Core_Create
 *
 * Create an RSA secret key structure. If a parameter is marked as
 * [OPTIONAL], then it can be omitted and will be calculated from
 * other params - or, in the case of e, will default to 0x10001.
 *
 * Parameters are _not_ copied, so will be freed if the structure is
 * freed.
 *
 * \param key The key structure to be initialised.
 * \param t
 * \param d The RSA parameter d (=e^-1 mod (p-1)(q-1)) [OPTIONAL]
 * \param p The RSA parameter p
 * \param q The RSA parameter q (q > p)
 * \param u The RSA parameter u (=p^-1 mod q) [OPTIONAL]
 * \param n The RSA public parameter n (=p*q) [OPTIONAL]
 * \param e The RSA public parameter e */

void 
__ops_fast_create_rsa_seckey(__ops_seckey_t *key, time_t t,
			     BIGNUM *d, BIGNUM *p, BIGNUM *q, BIGNUM *u,
			       BIGNUM *n, BIGNUM *e)
{
	__ops_fast_create_rsa_pubkey(&key->pubkey, t, n, e);

	/* XXX: calculate optionals */
	key->key.rsa.d = d;
	key->key.rsa.p = p;
	key->key.rsa.q = q;
	key->key.rsa.u = u;

	key->s2k_usage = OPS_S2KU_NONE;

	/* XXX: sanity check and add errors... */
}

/**
 * \ingroup Core_WritePackets
 * \brief Writes a Secret Key packet.
 * \param key The secret key
 * \param passphrase The passphrase
 * \param pplen Length of passphrase
 * \param output
 * \return 1 if OK; else 0
 */
unsigned 
__ops_write_struct_seckey(const __ops_seckey_t *key,
			    const uint8_t *passphrase,
			    const size_t pplen,
			    __ops_output_t *output)
{
	int             length = 0;

	if (key->pubkey.version != 4) {
		(void) fprintf(stderr,
			"__ops_write_struct_seckey: public key version\n");
		return 0;
	}

	/* Ref: RFC4880 Section 5.5.3 */

	/* pubkey, excluding MPIs */
	length += 1 + 4 + 1 + 1;

	/* s2k usage */
	length += 1;

	switch (key->s2k_usage) {
	case OPS_S2KU_NONE:
		/* nothing to add */
		break;

	case OPS_S2KU_ENCRYPTED_AND_HASHED:	/* 254 */
	case OPS_S2KU_ENCRYPTED:	/* 255 */

		/* Ref: RFC4880 Section 3.7 */
		length += 1;	/* s2k_specifier */

		switch (key->s2k_specifier) {
		case OPS_S2KS_SIMPLE:
			length += 1;	/* hash algorithm */
			break;

		case OPS_S2KS_SALTED:
			length += 1 + 8;	/* hash algorithm + salt */
			break;

		case OPS_S2KS_ITERATED_AND_SALTED:
			length += 1 + 8 + 1;	/* hash algorithm, salt +
						 * count */
			break;

		default:
			(void) fprintf(stderr,
				"__ops_write_struct_seckey: s2k spec\n");
			return 0;
		}
		break;

	default:
		(void) fprintf(stderr,
			"__ops_write_struct_seckey: s2k usage\n");
		return 0;
	}

	/* IV */
	if (key->s2k_usage) {
		length += __ops_block_size(key->alg);
	}
	/* checksum or hash */
	switch (key->s2k_usage) {
	case OPS_S2KU_NONE:
	case OPS_S2KU_ENCRYPTED:
		length += 2;
		break;

	case OPS_S2KU_ENCRYPTED_AND_HASHED:
		length += OPS_CHECKHASH_SIZE;
		break;

	default:
		(void) fprintf(stderr,
			"__ops_write_struct_seckey: s2k cksum usage\n");
		return 0;
	}

	/* secret key and public key MPIs */
	length += (unsigned)seckey_length(key);

	return __ops_write_ptag(output, OPS_PTAG_CT_SECRET_KEY) &&
		/* __ops_write_length(output,1+4+1+1+seckey_length(key)+2) && */
		__ops_write_length(output, (unsigned)length) &&
		write_seckey_body(key, passphrase, pplen, output);
}

/**
 * \ingroup Core_Create
 *
 * \brief Create a new __ops_output_t structure.
 *
 * \return the new structure.
 * \note It is the responsiblity of the caller to call __ops_output_delete().
 * \sa __ops_output_delete()
 */
__ops_output_t *
__ops_output_new(void)
{
	return calloc(1, sizeof(__ops_output_t));
}

/**
 * \ingroup Core_Create
 * \brief Delete an __ops_output_t strucut and associated resources.
 *
 * Delete an __ops_output_t structure. If a writer is active, then
 * that is also deleted.
 *
 * \param info the structure to be deleted.
 */
void 
__ops_output_delete(__ops_output_t *output)
{
	__ops_writer_info_delete(&output->writer);
	free(output);
}

/**
 \ingroup Core_Create
 \brief Calculate the checksum for a session key
 \param sesskey Session Key to use
 \param cs Checksum to be written
 \return 1 if OK; else 0
*/
unsigned 
__ops_calc_sesskey_checksum(__ops_pk_sesskey_t *sesskey, uint8_t cs[2])
{
	uint32_t   checksum = 0;
	unsigned    i;

	if (!__ops_is_sa_supported(sesskey->symm_alg)) {
		return 0;
	}

	for (i = 0; i < __ops_key_size(sesskey->symm_alg); i++) {
		checksum += sesskey->key[i];
	}
	checksum = checksum % 65536;

	cs[0] = (uint8_t)((checksum >> 8) & 0xff);
	cs[1] = (uint8_t)(checksum & 0xff);

	if (__ops_get_debug_level(__FILE__)) {
		hexdump(stderr, "nm buf checksum:", cs, 2);
	}
	return 1;
}

static unsigned 
create_unencoded_m_buf(__ops_pk_sesskey_t *sesskey, __ops_crypt_t *cipherinfo, uint8_t *m_buf)
{
	unsigned	i;

	/* m_buf is the buffer which will be encoded in PKCS#1 block
	* encoding to form the "m" value used in the Public Key
	* Encrypted Session Key Packet as defined in RFC Section 5.1
	* "Public-Key Encrypted Session Key Packet"
	 */
	m_buf[0] = sesskey->symm_alg;
	for (i = 0; i < cipherinfo->keysize ; i++) {
		/* XXX - Flexelint - Warning 679: Suspicious Truncation in arithmetic expression combining with pointer */
		m_buf[1 + i] = sesskey->key[i];
	}

	return __ops_calc_sesskey_checksum(sesskey,
				m_buf + 1 + cipherinfo->keysize);
}

/**
\ingroup Core_Create
\brief implementation of EME-PKCS1-v1_5-ENCODE, as defined in OpenPGP RFC
\param M
\param mLen
\param pubkey
\param EM
\return 1 if OK; else 0
*/
unsigned 
encode_m_buf(const uint8_t *M, size_t mLen, const __ops_pubkey_t * pubkey,
	     uint8_t *EM)
{
	unsigned    k;
	unsigned        i;

	/* implementation of EME-PKCS1-v1_5-ENCODE, as defined in OpenPGP RFC */
	switch (pubkey->alg) {
	case OPS_PKA_RSA:
		k = (unsigned)BN_num_bytes(pubkey->key.rsa.n);
		if (mLen > k - 11) {
			(void) fprintf(stderr, "encode_m_buf: message too long\n");
			return 0;
		}
		break;
	case OPS_PKA_DSA:
	case OPS_PKA_ELGAMAL:
		k = (unsigned)BN_num_bytes(pubkey->key.elgamal.p);
		if (mLen > k - 11) {
			(void) fprintf(stderr, "encode_m_buf: message too long\n");
			return 0;
		}
		break;
	default:
		(void) fprintf(stderr, "encode_m_buf: pubkey algorithm\n");
		return 0;
	}
	/* these two bytes defined by RFC */
	EM[0] = 0x00;
	EM[1] = 0x02;
	/* add non-zero random bytes of length k - mLen -3 */
	for (i = 2; i < (k - mLen) - 1; ++i) {
		do {
			__ops_random(EM + i, 1);
		} while (EM[i] == 0);
	}
	if (i < 8 + 2) {
		(void) fprintf(stderr, "encode_m_buf: bad i len\n");
		return 0;
	}
	EM[i++] = 0;
	(void) memcpy(EM + i, M, mLen);
	if (__ops_get_debug_level(__FILE__)) {
		hexdump(stderr, "Encoded Message:", EM, mLen);
	}
	return 1;
}

/**
 \ingroup Core_Create
\brief Creates an __ops_pk_sesskey_t struct from keydata
\param key Keydata to use
\return __ops_pk_sesskey_t struct
\note It is the caller's responsiblity to free the returned pointer
\note Currently hard-coded to use CAST5
\note Currently hard-coded to use RSA
*/
__ops_pk_sesskey_t *
__ops_create_pk_sesskey(const __ops_key_t *key, const char *ciphername, int dont_use_subkey_to_encrypt)
{
	/*
         * Creates a random session key and encrypts it for the given key
         *
         * Encryption used is PK,
         * can be any, we're hardcoding RSA for now
         */

	const __ops_pubkey_t	*pubkey;
	__ops_pk_sesskey_t	*sesskey;
	__ops_symm_alg_t	 cipher;
	const uint8_t		*id;
	__ops_crypt_t		 cipherinfo;
	uint8_t			*unencoded_m_buf;
	uint8_t			*encoded_m_buf;
	size_t			 sz_encoded_m_buf;

	if (memcmp(key->encid, "\0\0\0\0\0\0\0\0", 8) == 0) {
		pubkey = __ops_get_pubkey(key);
		id = key->sigid;
    } else if (dont_use_subkey_to_encrypt) {
        //DUPA
		pubkey = __ops_get_pubkey(key);
        id = key->sigid;
	} else {
		pubkey = &key->enckey;
		id = key->encid;
	}
	/* allocate unencoded_m_buf here */
	(void) memset(&cipherinfo, 0x0, sizeof(cipherinfo));
	__ops_crypt_any(&cipherinfo,
		cipher = __ops_str_to_cipher((ciphername) ? ciphername : "cast5"));
	unencoded_m_buf = calloc(1, cipherinfo.keysize + 1 + 2);
	if (unencoded_m_buf == NULL) {
		(void) fprintf(stderr,
			"__ops_create_pk_sesskey: can't allocate\n");
		return NULL;
	}
	switch(pubkey->alg) {
	case OPS_PKA_RSA:
		sz_encoded_m_buf = BN_num_bytes(pubkey->key.rsa.n);
		break;
	case OPS_PKA_DSA:
	case OPS_PKA_ELGAMAL:
		sz_encoded_m_buf = BN_num_bytes(pubkey->key.elgamal.p);
		break;
	default:
		sz_encoded_m_buf = 0;
		break;
	}
	if ((encoded_m_buf = calloc(1, sz_encoded_m_buf)) == NULL) {
		(void) fprintf(stderr,
			"__ops_create_pk_sesskey: can't allocate\n");
		free(unencoded_m_buf);
		return NULL;
	}
	if ((sesskey = calloc(1, sizeof(*sesskey))) == NULL) {
		(void) fprintf(stderr,
			"__ops_create_pk_sesskey: can't allocate\n");
		free(unencoded_m_buf);
		free(encoded_m_buf);
		return NULL;
	}
	if (key->type != OPS_PTAG_CT_PUBLIC_KEY) {
		(void) fprintf(stderr,
			"__ops_create_pk_sesskey: bad type\n");
		free(unencoded_m_buf);
		free(encoded_m_buf);
		free(sesskey);
		return NULL;
	}
	sesskey->version = OPS_PKSK_V3;
	(void) memcpy(sesskey->key_id, id, sizeof(sesskey->key_id));

	if (__ops_get_debug_level(__FILE__)) {
		hexdump(stderr, "Encrypting for keyid", id, sizeof(sesskey->key_id));
	}
	switch (pubkey->alg) {
	case OPS_PKA_RSA:
	case OPS_PKA_DSA:
	case OPS_PKA_ELGAMAL:
		break;
	default:
		(void) fprintf(stderr,
			"__ops_create_pk_sesskey: bad pubkey algorithm\n");
		free(unencoded_m_buf);
		free(encoded_m_buf);
		free(sesskey);
		return NULL;
	}
	sesskey->alg = pubkey->alg;

	sesskey->symm_alg = cipher;
	__ops_random(sesskey->key, cipherinfo.keysize);

	if (__ops_get_debug_level(__FILE__)) {
		hexdump(stderr, "sesskey created", sesskey->key,
			cipherinfo.keysize + 1 + 2);
	}
	if (create_unencoded_m_buf(sesskey, &cipherinfo, &unencoded_m_buf[0]) == 0) {
		free(unencoded_m_buf);
		free(encoded_m_buf);
		free(sesskey);
		return NULL;
	}
	if (__ops_get_debug_level(__FILE__)) {
		hexdump(stderr, "uuencoded m buf", unencoded_m_buf, cipherinfo.keysize + 1 + 2);
	}
	encode_m_buf(unencoded_m_buf, cipherinfo.keysize + 1 + 2, pubkey, encoded_m_buf);

	/* and encrypt it */
	switch (key->key.pubkey.alg) {
	case OPS_PKA_RSA:
		if (!__ops_rsa_encrypt_mpi(encoded_m_buf, sz_encoded_m_buf, pubkey,
				&sesskey->params)) {
			free(unencoded_m_buf);
			free(encoded_m_buf);
			free(sesskey);
			return NULL;
		}
		break;
	case OPS_PKA_DSA:
	case OPS_PKA_ELGAMAL:
		if (!__ops_elgamal_encrypt_mpi(encoded_m_buf, sz_encoded_m_buf, pubkey,
				&sesskey->params)) {
			free(unencoded_m_buf);
			free(encoded_m_buf);
			free(sesskey);
			return NULL;
		}
		break;
	default:
		/* will not get here - for lint only */
		break;
	}
	free(unencoded_m_buf);
	free(encoded_m_buf);
	return sesskey;
}

/**
\ingroup Core_WritePackets
\brief Writes Public Key Session Key packet
\param info Write settings
\param pksk Public Key Session Key to write out
\return 1 if OK; else 0
*/
unsigned 
__ops_write_pk_sesskey(__ops_output_t *output, __ops_pk_sesskey_t *pksk)
{
	/* XXX - Flexelint - Pointer parameter 'pksk' (line 1076) could be declared as pointing to const */
	if (pksk == NULL) {
		(void) fprintf(stderr,
			"__ops_write_pk_sesskey: NULL pksk\n");
		return 0;
	}
	switch (pksk->alg) {
	case OPS_PKA_RSA:
		return __ops_write_ptag(output, OPS_PTAG_CT_PK_SESSION_KEY) &&
			__ops_write_length(output, (unsigned)(1 + 8 + 1 +
				BN_num_bytes(pksk->params.rsa.encrypted_m) + 2)) &&
			__ops_write_scalar(output, (unsigned)pksk->version, 1) &&
			__ops_write(output, pksk->key_id, 8) &&
			__ops_write_scalar(output, (unsigned)pksk->alg, 1) &&
			__ops_write_mpi(output, pksk->params.rsa.encrypted_m)
			/* ??	&& __ops_write_scalar(output, 0, 2); */
			;
	case OPS_PKA_DSA:
	case OPS_PKA_ELGAMAL:
		return __ops_write_ptag(output, OPS_PTAG_CT_PK_SESSION_KEY) &&
			__ops_write_length(output, (unsigned)(1 + 8 + 1 +
				BN_num_bytes(pksk->params.elgamal.g_to_k) + 2 +
				BN_num_bytes(pksk->params.elgamal.encrypted_m) + 2)) &&
			__ops_write_scalar(output, (unsigned)pksk->version, 1) &&
			__ops_write(output, pksk->key_id, 8) &&
			__ops_write_scalar(output, (unsigned)pksk->alg, 1) &&
			__ops_write_mpi(output, pksk->params.elgamal.g_to_k) &&
			__ops_write_mpi(output, pksk->params.elgamal.encrypted_m)
			/* ??	&& __ops_write_scalar(output, 0, 2); */
			;
	default:
		(void) fprintf(stderr,
			"__ops_write_pk_sesskey: bad algorithm\n");
		return 0;
	}
}

/**
\ingroup Core_WritePackets
\brief Writes MDC packet
\param hashed Hash for MDC
\param output Write settings
\return 1 if OK; else 0
*/

unsigned 
__ops_write_mdc(__ops_output_t *output, const uint8_t *hashed)
{
	/* write it out */
	return __ops_write_ptag(output, OPS_PTAG_CT_MDC) &&
		__ops_write_length(output, OPS_SHA1_HASH_SIZE) &&
		__ops_write(output, hashed, OPS_SHA1_HASH_SIZE);
}

/**
\ingroup Core_WritePackets
\brief Writes Literal Data packet from buffer
\param data Buffer to write out
\param maxlen Max length of buffer
\param type Literal Data Type
\param output Write settings
\return 1 if OK; else 0
*/
unsigned 
__ops_write_litdata(__ops_output_t *output,
			const uint8_t *data,
			const int maxlen,
			const __ops_litdata_enum type)
{
	/*
         * RFC4880 does not specify a meaning for filename or date.
         * It is implementation-dependent.
         * We will not implement them.
         */
	/* \todo do we need to check text data for <cr><lf> line endings ? */
	return __ops_write_ptag(output, OPS_PTAG_CT_LITDATA) &&
		__ops_write_length(output, (unsigned)(1 + 1 + 4 + maxlen)) &&
		__ops_write_scalar(output, (unsigned)type, 1) &&
		__ops_write_scalar(output, 0, 1) &&
		__ops_write_scalar(output, 0, 4) &&
		__ops_write(output, data, (unsigned)maxlen);
}

/**
\ingroup Core_WritePackets
\brief Writes Literal Data packet from contents of file
\param filename Name of file to read from
\param type Literal Data Type
\param output Write settings
\return 1 if OK; else 0
*/

unsigned 
__ops_fileread_litdata(const char *filename,
				 const __ops_litdata_enum type,
				 __ops_output_t *output)
{
	__ops_memory_t	*mem;
	unsigned   	 ret;
	int		 len;

	mem = __ops_memory_new();
	if (!__ops_mem_readfile(mem, filename)) {
		(void) fprintf(stderr, "__ops_mem_readfile of '%s' failed\n", filename);
		return 0;
	}
	len = (int)__ops_mem_len(mem);
	ret = __ops_write_litdata(output, __ops_mem_data(mem), len, type);
	__ops_memory_free(mem);
	return ret;
}

/**
   \ingroup HighLevel_General

   \brief Writes contents of buffer into file

   \param filename Filename to write to
   \param buf Buffer to write to file
   \param len Size of buffer
   \param overwrite Flag to set whether to overwrite an existing file
   \return 1 if OK; 0 if error
*/

int 
__ops_filewrite(const char *filename, const char *buf,
			const size_t len, const unsigned overwrite)
{
	int		flags;
	int		fd;

	flags = O_WRONLY | O_CREAT;
	if (overwrite) {
		flags |= O_TRUNC;
	} else {
		flags |= O_EXCL;
	}
#ifdef O_BINARY
	flags |= O_BINARY;
#endif
	fd = open(filename, flags, 0600);
	if (fd < 0) {
		(void) fprintf(stderr, "can't open '%s'\n", filename);
		return 0;
	}
	if (write(fd, buf, len) != (int)len) {
		(void) close(fd);
		return 0;
	}

	return (close(fd) == 0);
}

/**
\ingroup Core_WritePackets
\brief Write Symmetrically Encrypted packet
\param data Data to encrypt
\param len Length of data
\param output Write settings
\return 1 if OK; else 0
\note Hard-coded to use AES256
*/
unsigned 
__ops_write_symm_enc_data(const uint8_t *data,
				       const int len,
				       __ops_output_t * output)
{
	__ops_crypt_t	crypt_info;
	uint8_t		*encrypted = (uint8_t *) NULL;
	size_t		encrypted_sz;
	int             done = 0;

	/* \todo assume AES256 for now */
	__ops_crypt_any(&crypt_info, OPS_SA_AES_256);
	__ops_encrypt_init(&crypt_info);

	encrypted_sz = (size_t)(len + crypt_info.blocksize + 2);
	if ((encrypted = calloc(1, encrypted_sz)) == NULL) {
		(void) fprintf(stderr, "can't allocate %" PRIsize "d\n",
			encrypted_sz);
		return 0;
	}

	done = (int)__ops_encrypt_se(&crypt_info, encrypted, data, (unsigned)len);
	if (done != len) {
		(void) fprintf(stderr,
			"__ops_write_symm_enc_data: done != len\n");
		return 0;
	}

	return __ops_write_ptag(output, OPS_PTAG_CT_SE_DATA) &&
		__ops_write_length(output, (unsigned)(1 + encrypted_sz)) &&
		__ops_write(output, data, (unsigned)len);
}

/**
\ingroup Core_WritePackets
\brief Write a One Pass Signature packet
\param seckey Secret Key to use
\param hash_alg Hash Algorithm to use
\param sig_type Signature type
\param output Write settings
\return 1 if OK; else 0
*/
unsigned 
__ops_write_one_pass_sig(__ops_output_t *output, 
			const __ops_seckey_t *seckey,
			const __ops_hash_alg_t hash_alg,
			const __ops_sig_type_t sig_type)
{
	uint8_t   keyid[OPS_KEY_ID_SIZE];

	__ops_keyid(keyid, OPS_KEY_ID_SIZE, &seckey->pubkey, OPS_HASH_SHA1); /* XXX - hardcoded */
	return __ops_write_ptag(output, OPS_PTAG_CT_1_PASS_SIG) &&
		__ops_write_length(output, 1 + 1 + 1 + 1 + 8 + 1) &&
		__ops_write_scalar(output, 3, 1)	/* version */ &&
		__ops_write_scalar(output, (unsigned)sig_type, 1) &&
		__ops_write_scalar(output, (unsigned)hash_alg, 1) &&
		__ops_write_scalar(output, (unsigned)seckey->pubkey.alg, 1) &&
		__ops_write(output, keyid, 8) &&
		__ops_write_scalar(output, 1, 1);
}
