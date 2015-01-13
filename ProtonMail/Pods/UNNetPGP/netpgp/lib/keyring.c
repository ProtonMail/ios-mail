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
__RCSID("$NetBSD: keyring.c,v 1.47 2010/10/31 19:45:53 stacktic Exp $");
#endif

#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif

#include <regex.h>
#include <stdlib.h>
#include <string.h>

#ifdef HAVE_TERMIOS_H
#include <termios.h>
#endif

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

#include "types.h"
#include "keyring.h"
#include "packet-parse.h"
#include "signature.h"
#include "netpgpsdk.h"
#include "readerwriter.h"
#include "netpgpdefs.h"
#include "packet.h"
#include "crypto.h"
#include "validate.h"
#include "netpgpdefs.h"
#include "netpgpdigest.h"



/**
   \ingroup HighLevel_Keyring

   \brief Creates a new __ops_key_t struct

   \return A new __ops_key_t struct, initialised to zero.

   \note The returned __ops_key_t struct must be freed after use with __ops_keydata_free.
*/

__ops_key_t  *
__ops_keydata_new(void)
{
	return calloc(1, sizeof(__ops_key_t));
}


/**
 \ingroup HighLevel_Keyring

 \brief Frees keydata and its memory

 \param keydata Key to be freed.

 \note This frees the keydata itself, as well as any other memory alloc-ed by it.
*/
void 
__ops_keydata_free(__ops_key_t *keydata)
{
	unsigned        n;

	for (n = 0; n < keydata->uidc; ++n) {
		__ops_userid_free(&keydata->uids[n]);
	}
	free(keydata->uids);
	keydata->uids = NULL;
	keydata->uidc = 0;

	for (n = 0; n < keydata->packetc; ++n) {
		__ops_subpacket_free(&keydata->packets[n]);
	}
	free(keydata->packets);
	keydata->packets = NULL;
	keydata->packetc = 0;

	if (keydata->type == OPS_PTAG_CT_PUBLIC_KEY) {
		__ops_pubkey_free(&keydata->key.pubkey);
	} else {
		__ops_seckey_free(&keydata->key.seckey);
	}

	free(keydata);
}

/**
 \ingroup HighLevel_KeyGeneral

 \brief Returns the public key in the given keydata.
 \param keydata

  \return Pointer to public key

  \note This is not a copy, do not free it after use.
*/

const __ops_pubkey_t *
__ops_get_pubkey(const __ops_key_t *keydata)
{
	return (keydata->type == OPS_PTAG_CT_PUBLIC_KEY) ?
				&keydata->key.pubkey :
				&keydata->key.seckey.pubkey;
}

/**
\ingroup HighLevel_KeyGeneral

\brief Check whether this is a secret key or not.
*/

unsigned 
__ops_is_key_secret(const __ops_key_t *data)
{
	return data->type != OPS_PTAG_CT_PUBLIC_KEY;
}

/**
 \ingroup HighLevel_KeyGeneral

 \brief Returns the secret key in the given keydata.

 \note This is not a copy, do not free it after use.

 \note This returns a const.  If you need to be able to write to this
 pointer, use __ops_get_writable_seckey
*/

const __ops_seckey_t *
__ops_get_seckey(const __ops_key_t *data)
{
	return (data->type == OPS_PTAG_CT_SECRET_KEY) ?
				&data->key.seckey : NULL;
}

/**
 \ingroup HighLevel_KeyGeneral

  \brief Returns the secret key in the given keydata.

  \note This is not a copy, do not free it after use.

  \note If you do not need to be able to modify this key, there is an
  equivalent read-only function __ops_get_seckey.
*/

__ops_seckey_t *
__ops_get_writable_seckey(__ops_key_t *data)
{
	return (data->type == OPS_PTAG_CT_SECRET_KEY) ?
				&data->key.seckey : NULL;
}

/* utility function to zero out memory */
void
__ops_forget(void *vp, unsigned size)
{
	(void) memset(vp, 0x0, size);
}

typedef struct {
	FILE			*passfp;
	const __ops_key_t	*key;
	char			*passphrase;
	__ops_seckey_t		*seckey;
} decrypt_t;

static __ops_cb_ret_t 
decrypt_cb(const __ops_packet_t *pkt, __ops_cbdata_t *cbinfo)
{
	const __ops_contents_t	*content = &pkt->u;
	decrypt_t		*decrypt;
	char			 pass[MAX_PASSPHRASE_LENGTH];

	decrypt = __ops_callback_arg(cbinfo);
	switch (pkt->tag) {
	case OPS_PARSER_PTAG:
	case OPS_PTAG_CT_USER_ID:
	case OPS_PTAG_CT_SIGNATURE:
	case OPS_PTAG_CT_SIGNATURE_HEADER:
	case OPS_PTAG_CT_SIGNATURE_FOOTER:
	case OPS_PTAG_CT_TRUST:
		break;

	case OPS_GET_PASSPHRASE:
		(void) __ops_getpassphrase(decrypt->passfp, pass, sizeof(pass));
		*content->skey_passphrase.passphrase = netpgp_strdup(pass);
		__ops_forget(pass, (unsigned)sizeof(pass));
		return OPS_KEEP_MEMORY;

	case OPS_PARSER_ERRCODE:
		switch (content->errcode.errcode) {
		case OPS_E_P_MPI_FORMAT_ERROR:
			/* Generally this means a bad passphrase */
			fprintf(stderr, "Bad passphrase!\n");
			return OPS_RELEASE_MEMORY;

		case OPS_E_P_PACKET_CONSUMED:
			/* And this is because of an error we've accepted */
			return OPS_RELEASE_MEMORY;
		default:
			break;
		}
		(void) fprintf(stderr, "parse error: %s\n",
				__ops_errcode(content->errcode.errcode));
		return OPS_FINISHED;

	case OPS_PARSER_ERROR:
		fprintf(stderr, "parse error: %s\n", content->error);
		return OPS_FINISHED;

	case OPS_PTAG_CT_SECRET_KEY:
		if ((decrypt->seckey = calloc(1, sizeof(*decrypt->seckey))) == NULL) {
			(void) fprintf(stderr, "decrypt_cb: bad alloc\n");
			return OPS_FINISHED;
		}
		decrypt->seckey->checkhash = calloc(1, OPS_CHECKHASH_SIZE);
		*decrypt->seckey = content->seckey;
		return OPS_KEEP_MEMORY;

	case OPS_PARSER_PACKET_END:
		/* nothing to do */
		break;

	default:
		fprintf(stderr, "Unexpected tag %d (0x%x)\n", pkt->tag,
			pkt->tag);
		return OPS_FINISHED;
	}

	return OPS_RELEASE_MEMORY;
}

/**
\ingroup Core_Keys
\brief Decrypts secret key from given keydata with given passphrase
\param key Key from which to get secret key
\param passphrase Passphrase to use to decrypt secret key
\return secret key
*/
__ops_seckey_t *
__ops_decrypt_seckey(const __ops_key_t *key, void *passfp)
{
	__ops_stream_t	*stream;
	const int	 printerrors = 1;
	decrypt_t	 decrypt;

	(void) memset(&decrypt, 0x0, sizeof(decrypt));
	decrypt.key = key;
	decrypt.passfp = passfp;
	stream = __ops_new(sizeof(*stream));
	__ops_keydata_reader_set(stream, key);
	__ops_set_callback(stream, decrypt_cb, &decrypt);
	stream->readinfo.accumulate = 1;
	__ops_parse(stream, !printerrors);
	return decrypt.seckey;
}

/**
\ingroup Core_Keys
\brief Set secret key in content
\param content Content to be set
\param key Keydata to get secret key from
*/
void 
__ops_set_seckey(__ops_contents_t *cont, const __ops_key_t *key)
{
	*cont->get_seckey.seckey = &key->key.seckey;
}

/**
\ingroup Core_Keys
\brief Get Key ID from keydata
\param key Keydata to get Key ID from
\return Pointer to Key ID inside keydata
*/
const uint8_t *
__ops_get_key_id(const __ops_key_t *key)
{
	return key->sigid;
}

/**
\ingroup Core_Keys
\brief How many User IDs in this key?
\param key Keydata to check
\return Num of user ids
*/
unsigned 
__ops_get_userid_count(const __ops_key_t *key)
{
	return key->uidc;
}

/**
\ingroup Core_Keys
\brief Get indexed user id from key
\param key Key to get user id from
\param index Which key to get
\return Pointer to requested user id
*/
const uint8_t *
__ops_get_userid(const __ops_key_t *key, unsigned subscript)
{
	return key->uids[subscript];
}

/**
   \ingroup HighLevel_Supported
   \brief Checks whether key's algorithm and type are supported by OpenPGP::SDK
   \param keydata Key to be checked
   \return 1 if key algorithm and type are supported by OpenPGP::SDK; 0 if not
*/

unsigned 
__ops_is_key_supported(const __ops_key_t *key)
{
	if (key->type == OPS_PTAG_CT_PUBLIC_KEY) {
		switch(key->key.pubkey.alg) {
		case OPS_PKA_RSA:
		case OPS_PKA_DSA:
		case OPS_PKA_ELGAMAL:
			return 1;
		default:
			break;
		}
	}
	return 0;
}

/* \todo check where userid pointers are copied */
/**
\ingroup Core_Keys
\brief Copy user id, including contents
\param dst Destination User ID
\param src Source User ID
\note If dst already has a userid, it will be freed.
*/
static uint8_t * 
__ops_copy_userid(uint8_t **dst, const uint8_t *src)
{
	size_t          len;

	len = strlen((const char *) src);
	if (*dst) {
		free(*dst);
	}
	if ((*dst = calloc(1, len + 1)) == NULL) {
		(void) fprintf(stderr, "__ops_copy_userid: bad alloc\n");
	} else {
		(void) memcpy(*dst, src, len);
	}
	return *dst;
}

/* \todo check where pkt pointers are copied */
/**
\ingroup Core_Keys
\brief Copy packet, including contents
\param dst Destination packet
\param src Source packet
\note If dst already has a packet, it will be freed.
*/
static __ops_subpacket_t * 
__ops_copy_packet(__ops_subpacket_t *dst, const __ops_subpacket_t *src)
{
	if (dst->raw) {
		free(dst->raw);
	}
	if ((dst->raw = calloc(1, src->length)) == NULL) {
		(void) fprintf(stderr, "__ops_copy_packet: bad alloc\n");
	} else {
		dst->length = src->length;
		(void) memcpy(dst->raw, src->raw, src->length);
	}
	return dst;
}

/**
\ingroup Core_Keys
\brief Add User ID to key
\param key Key to which to add User ID
\param userid User ID to add
\return Pointer to new User ID
*/
uint8_t  *
__ops_add_userid(__ops_key_t *key, const uint8_t *userid)
{
	uint8_t  **uidp;

	EXPAND_ARRAY(key, uid);
	/* initialise new entry in array */
	uidp = &key->uids[key->uidc++];
	*uidp = NULL;
	/* now copy it */
	return __ops_copy_userid(uidp, userid);
}

void print_packet_hex(const __ops_subpacket_t *pkt);

/**
\ingroup Core_Keys
\brief Add packet to key
\param keydata Key to which to add packet
\param packet Packet to add
\return Pointer to new packet
*/
__ops_subpacket_t   *
__ops_add_subpacket(__ops_key_t *keydata, const __ops_subpacket_t *packet)
{
	__ops_subpacket_t   *subpktp;

	EXPAND_ARRAY(keydata, packet);
	/* initialise new entry in array */
	subpktp = &keydata->packets[keydata->packetc++];
	subpktp->length = 0;
	subpktp->raw = NULL;
	/* now copy it */
	return __ops_copy_packet(subpktp, packet);
}

/**
\ingroup Core_Keys
\brief Add selfsigned User ID to key
\param keydata Key to which to add user ID
\param userid Self-signed User ID to add
\return 1 if OK; else 0
*/
unsigned 
__ops_add_selfsigned_userid(__ops_key_t *key, uint8_t *userid)
{
	__ops_create_sig_t	*sig;
	__ops_subpacket_t	 sigpacket;
	__ops_memory_t		*mem_userid = NULL;
	__ops_output_t		*useridoutput = NULL;
	__ops_memory_t		*mem_sig = NULL;
	__ops_output_t		*sigoutput = NULL;

	/*
         * create signature packet for this userid
         */

	/* create userid pkt */
	__ops_setup_memory_write(&useridoutput, &mem_userid, 128);
	__ops_write_struct_userid(useridoutput, userid);

	/* create sig for this pkt */
	sig = __ops_create_sig_new();
	__ops_sig_start_key_sig(sig, &key->key.seckey.pubkey, userid, OPS_CERT_POSITIVE);
	__ops_add_time(sig, (int64_t)time(NULL), "birth");
	__ops_add_issuer_keyid(sig, key->sigid);
	__ops_add_primary_userid(sig, 1);
	__ops_end_hashed_subpkts(sig);

	__ops_setup_memory_write(&sigoutput, &mem_sig, 128);
	__ops_write_sig(sigoutput, sig, &key->key.seckey.pubkey, &key->key.seckey);

	/* add this packet to key */
	sigpacket.length = __ops_mem_len(mem_sig);
	sigpacket.raw = __ops_mem_data(mem_sig);

	/* add userid to key */
	(void) __ops_add_userid(key, userid);
	(void) __ops_add_subpacket(key, &sigpacket);

	/* cleanup */
	__ops_create_sig_delete(sig);
	__ops_output_delete(useridoutput);
	__ops_output_delete(sigoutput);
	__ops_memory_free(mem_userid);
	__ops_memory_free(mem_sig);

	return 1;
}

/**
\ingroup Core_Keys
\brief Initialise __ops_key_t
\param keydata Keydata to initialise
\param type OPS_PTAG_CT_PUBLIC_KEY or OPS_PTAG_CT_SECRET_KEY
*/
void 
__ops_keydata_init(__ops_key_t *keydata, const __ops_content_enum type)
{
	if (keydata->type != OPS_PTAG_CT_RESERVED) {
		(void) fprintf(stderr,
			"__ops_keydata_init: wrong keydata type\n");
	} else if (type != OPS_PTAG_CT_PUBLIC_KEY &&
		   type != OPS_PTAG_CT_SECRET_KEY) {
		(void) fprintf(stderr, "__ops_keydata_init: wrong type\n");
	} else {
		keydata->type = type;
	}
}

/* used to point to data during keyring read */
typedef struct keyringcb_t {
	__ops_keyring_t		*keyring;	/* the keyring we're reading */
} keyringcb_t;


static __ops_cb_ret_t
cb_keyring_read(const __ops_packet_t *pkt, __ops_cbdata_t *cbinfo)
{
	__ops_keyring_t	*keyring;
	__ops_revoke_t	*revocation;
	__ops_key_t	*key;
	keyringcb_t	*cb;

	cb = __ops_callback_arg(cbinfo);
	keyring = cb->keyring;
	switch (pkt->tag) {
	case OPS_PARSER_PTAG:
	case OPS_PTAG_CT_ENCRYPTED_SECRET_KEY:
		/* we get these because we didn't prompt */
		break;
	case OPS_PTAG_CT_SIGNATURE_HEADER:
		key = &keyring->keys[keyring->keyc - 1];
		EXPAND_ARRAY(key, subsig);
		key->subsigs[key->subsigc].uid = key->uidc - 1;
		(void) memcpy(&key->subsigs[key->subsigc].sig, &pkt->u.sig,
				sizeof(pkt->u.sig));
		key->subsigc += 1;
		break;
	case OPS_PTAG_CT_SIGNATURE:
		key = &keyring->keys[keyring->keyc - 1];
		EXPAND_ARRAY(key, subsig);
		key->subsigs[key->subsigc].uid = key->uidc - 1;
		(void) memcpy(&key->subsigs[key->subsigc].sig, &pkt->u.sig,
				sizeof(pkt->u.sig));
		key->subsigc += 1;
		break;
	case OPS_PTAG_CT_TRUST:
		key = &keyring->keys[keyring->keyc - 1];
		key->subsigs[key->subsigc - 1].trustlevel = pkt->u.ss_trust.level;
		key->subsigs[key->subsigc - 1].trustamount = pkt->u.ss_trust.amount;
		break;
	case OPS_PTAG_SS_KEY_EXPIRY:
		EXPAND_ARRAY(keyring, key);
		if (keyring->keyc > 0) {
			keyring->keys[keyring->keyc - 1].key.pubkey.duration = pkt->u.ss_time;
		}
		break;
	case OPS_PTAG_SS_ISSUER_KEY_ID:
		key = &keyring->keys[keyring->keyc - 1];
		(void) memcpy(&key->subsigs[key->subsigc - 1].sig.info.signer_id,
			      pkt->u.ss_issuer,
			      sizeof(pkt->u.ss_issuer));
		key->subsigs[key->subsigc - 1].sig.info.signer_id_set = 1;
		break;
	case OPS_PTAG_SS_CREATION_TIME:
		key = &keyring->keys[keyring->keyc - 1];
		key->subsigs[key->subsigc - 1].sig.info.birthtime = pkt->u.ss_time;
		key->subsigs[key->subsigc - 1].sig.info.birthtime_set = 1;
		break;
	case OPS_PTAG_SS_EXPIRATION_TIME:
		key = &keyring->keys[keyring->keyc - 1];
		key->subsigs[key->subsigc - 1].sig.info.duration = pkt->u.ss_time;
		key->subsigs[key->subsigc - 1].sig.info.duration_set = 1;
		break;
	case OPS_PTAG_SS_PRIMARY_USER_ID:
		key = &keyring->keys[keyring->keyc - 1];
		key->uid0 = key->uidc - 1;
		break;
	case OPS_PTAG_SS_REVOCATION_REASON:
		key = &keyring->keys[keyring->keyc - 1];
		if (key->uidc == 0) {
			/* revoke whole key */
			key->revoked = 1;
			revocation = &key->revocation;
		} else {
			/* revoke the user id */
			EXPAND_ARRAY(key, revoke);
			revocation = &key->revokes[key->revokec];
			key->revokes[key->revokec].uid = key->uidc - 1;
			key->revokec += 1;
		}
		revocation->code = pkt->u.ss_revocation.code;
		revocation->reason = netpgp_strdup(__ops_show_ss_rr_code(pkt->u.ss_revocation.code));
		break;
	case OPS_PTAG_CT_SIGNATURE_FOOTER:
	case OPS_PARSER_ERRCODE:
		break;

	default:
		break;
	}

	return OPS_RELEASE_MEMORY;
}

/**
   \ingroup HighLevel_KeyringRead

   \brief Reads a keyring from a file

   \param keyring Pointer to an existing __ops_keyring_t struct
   \param armour 1 if file is armoured; else 0
   \param filename Filename of keyring to be read

   \return __ops 1 if OK; 0 on error

   \note Keyring struct must already exist.

   \note Can be used with either a public or secret keyring.

   \note You must call __ops_keyring_free() after usage to free alloc-ed memory.

   \note If you call this twice on the same keyring struct, without calling
   __ops_keyring_free() between these calls, you will introduce a memory leak.

   \sa __ops_keyring_read_from_mem()
   \sa __ops_keyring_free()

*/

unsigned 
__ops_keyring_fileread(__ops_keyring_t *keyring,
			const unsigned armour,
			const char *filename)
{
	__ops_stream_t	*stream;
	keyringcb_t	 cb;
	unsigned	 res = 1;
	int		 fd;

	(void) memset(&cb, 0x0, sizeof(cb));
	cb.keyring = keyring;
	stream = __ops_new(sizeof(*stream));

	/* add this for the moment, */
	/*
	 * \todo need to fix the problems with reading signature subpackets
	 * later
	 */

	/* __ops_parse_options(parse,OPS_PTAG_SS_ALL,OPS_PARSE_RAW); */
	__ops_parse_options(stream, OPS_PTAG_SS_ALL, OPS_PARSE_PARSED);

#ifdef O_BINARY
	fd = open(filename, O_RDONLY | O_BINARY);
#else
	fd = open(filename, O_RDONLY);
#endif
	if (fd < 0) {
		__ops_stream_delete(stream);
		perror(filename);
		return 0;
	}
#ifdef USE_MMAP_FOR_FILES
	__ops_reader_set_mmap(stream, fd);
#else
	__ops_reader_set_fd(stream, fd);
#endif

	__ops_set_callback(stream, cb_keyring_read, &cb);

	if (armour) {
		__ops_reader_push_dearmour(stream);
	}
	res = __ops_parse_and_accumulate(keyring, stream);
	__ops_print_errors(__ops_stream_get_errors(stream));

	if (armour) {
		__ops_reader_pop_dearmour(stream);
	}

	(void)close(fd);

	__ops_stream_delete(stream);

	return res;
}

/**
   \ingroup HighLevel_KeyringRead

   \brief Reads a keyring from memory

   \param keyring Pointer to existing __ops_keyring_t struct
   \param armour 1 if file is armoured; else 0
   \param mem Pointer to a __ops_memory_t struct containing keyring to be read

   \return __ops 1 if OK; 0 on error

   \note Keyring struct must already exist.

   \note Can be used with either a public or secret keyring.

   \note You must call __ops_keyring_free() after usage to free alloc-ed memory.

   \note If you call this twice on the same keyring struct, without calling
   __ops_keyring_free() between these calls, you will introduce a memory leak.

   \sa __ops_keyring_fileread
   \sa __ops_keyring_free
*/
unsigned 
__ops_keyring_read_from_mem(__ops_io_t *io,
				__ops_keyring_t *keyring,
				const unsigned armour,
				__ops_memory_t *mem)
{
	__ops_stream_t	*stream;
	const unsigned	 noaccum = 0;
	keyringcb_t	 cb;
	unsigned	 res;

	(void) memset(&cb, 0x0, sizeof(cb));
	cb.keyring = keyring;
	stream = __ops_new(sizeof(*stream));
	__ops_parse_options(stream, OPS_PTAG_SS_ALL, OPS_PARSE_PARSED);
	__ops_setup_memory_read(io, &stream, mem, &cb, cb_keyring_read,
					noaccum);
	if (armour) {
		__ops_reader_push_dearmour(stream);
	}
	res = (unsigned)__ops_parse_and_accumulate(keyring, stream);
	__ops_print_errors(__ops_stream_get_errors(stream));
	if (armour) {
		__ops_reader_pop_dearmour(stream);
	}
	/* don't call teardown_memory_read because memory was passed in */
	__ops_stream_delete(stream);
	return res;
}

/**
   \ingroup HighLevel_KeyringRead

   \brief Frees keyring's contents (but not keyring itself)

   \param keyring Keyring whose data is to be freed

   \note This does not free keyring itself, just the memory alloc-ed in it.
 */
void 
__ops_keyring_free(__ops_keyring_t *keyring)
{
	(void)free(keyring->keys);
	keyring->keys = NULL;
	keyring->keyc = keyring->keyvsize = 0;
}

/**
   \ingroup HighLevel_KeyringFind

   \brief Finds key in keyring from its Key ID

   \param keyring Keyring to be searched
   \param keyid ID of required key

   \return Pointer to key, if found; NULL, if not found

   \note This returns a pointer to the key inside the given keyring,
   not a copy.  Do not free it after use.

*/
const __ops_key_t *
__ops_getkeybyid(__ops_io_t *io, const __ops_keyring_t *keyring,
			   const uint8_t *keyid, unsigned *from, __ops_pubkey_t **pubkey)
{
	uint8_t	nullid[OPS_KEY_ID_SIZE];

	(void) memset(nullid, 0x0, sizeof(nullid));
	for ( ; keyring && *from < keyring->keyc; *from += 1) {
		if (__ops_get_debug_level(__FILE__)) {
			hexdump(io->errs, "keyring sig keyid", keyring->keys[*from].sigid, OPS_KEY_ID_SIZE);
			hexdump(io->errs, "keyring enc keyid", keyring->keys[*from].encid, OPS_KEY_ID_SIZE);
			hexdump(io->errs, "keyid", keyid, OPS_KEY_ID_SIZE);
		}
		if (memcmp(keyring->keys[*from].sigid, keyid, OPS_KEY_ID_SIZE) == 0 ||
		    memcmp(&keyring->keys[*from].sigid[OPS_KEY_ID_SIZE / 2],
				keyid, OPS_KEY_ID_SIZE / 2) == 0) {
			if (pubkey) {
				*pubkey = &keyring->keys[*from].key.pubkey;
			}
			return &keyring->keys[*from];
		}
		if (memcmp(&keyring->keys[*from].encid, nullid, sizeof(nullid)) == 0) {
			continue;
		}
		if (memcmp(&keyring->keys[*from].encid, keyid, OPS_KEY_ID_SIZE) == 0 ||
		    memcmp(&keyring->keys[*from].encid[OPS_KEY_ID_SIZE / 2], keyid, OPS_KEY_ID_SIZE / 2) == 0) {
			if (pubkey) {
				*pubkey = &keyring->keys[*from].enckey;
			}
			return &keyring->keys[*from];
		}
	}
	return NULL;
}

/* convert a string keyid into a binary keyid */
static void
str2keyid(const char *userid, uint8_t *keyid, size_t len)
{
	static const char	*uppers = "0123456789ABCDEF";
	static const char	*lowers = "0123456789abcdef";
	const char		*hi;
	const char		*lo;
	uint8_t			 hichar;
	uint8_t			 lochar;
	size_t			 j;
	int			 i;

	for (i = 0, j = 0 ; j < len && userid[i] && userid[i + 1] ; i += 2, j++) {
		if ((hi = strchr(uppers, userid[i])) == NULL) {
			if ((hi = strchr(lowers, userid[i])) == NULL) {
				break;
			}
			hichar = (uint8_t)(hi - lowers);
		} else {
			hichar = (uint8_t)(hi - uppers);
		}
		if ((lo = strchr(uppers, userid[i + 1])) == NULL) {
			if ((lo = strchr(lowers, userid[i + 1])) == NULL) {
				break;
			}
			lochar = (uint8_t)(lo - lowers);
		} else {
			lochar = (uint8_t)(lo - uppers);
		}
		keyid[j] = (hichar << 4) | (lochar);
	}
	keyid[j] = 0x0;
}

/* return the next key which matches, starting searching at *from */
static const __ops_key_t *
getkeybyname(__ops_io_t *io,
			const __ops_keyring_t *keyring,
			const char *name,
			unsigned *from)
{
	const __ops_key_t	*kp;
	uint8_t			**uidp;
	unsigned    	 	 i = 0;
	__ops_key_t		*keyp;
	unsigned		 savedstart;
	regex_t			 r;
	uint8_t		 	 keyid[OPS_KEY_ID_SIZE + 1];
	size_t          	 len;

	if (!keyring || !name || !from) {
		return NULL;
	}
	len = strlen(name);
	if (__ops_get_debug_level(__FILE__)) {
		(void) fprintf(io->outs, "[%u] name '%s', len %zu\n",
			*from, name, len);
	}
	/* first try name as a keyid */
	(void) memset(keyid, 0x0, sizeof(keyid));
	str2keyid(name, keyid, sizeof(keyid));
	if (__ops_get_debug_level(__FILE__)) {
		hexdump(io->outs, "keyid", keyid, 4);
	}
	savedstart = *from;
	if ((kp = __ops_getkeybyid(io, keyring, keyid, from, NULL)) != NULL) {
		return kp;
	}
	*from = savedstart;
	if (__ops_get_debug_level(__FILE__)) {
		(void) fprintf(io->outs, "regex match '%s' from %u\n",
			name, *from);
	}
	/* match on full name or email address as a NOSUB, ICASE regexp */
	(void) regcomp(&r, name, REG_EXTENDED | REG_ICASE);
	for (keyp = &keyring->keys[*from]; *from < keyring->keyc; *from += 1, keyp++) {
		uidp = keyp->uids;
		for (i = 0 ; i < keyp->uidc; i++, uidp++) {
			if (regexec(&r, (char *)*uidp, 0, NULL, 0) == 0) {
				if (__ops_get_debug_level(__FILE__)) {
					(void) fprintf(io->outs,
						"MATCHED keyid \"%s\" len %" PRIsize "u\n",
					       (char *) *uidp, len);
				}
				regfree(&r);
				return keyp;
			}
		}
	}
	regfree(&r);
	return NULL;
}

/**
   \ingroup HighLevel_KeyringFind

   \brief Finds key from its User ID

   \param keyring Keyring to be searched
   \param userid User ID of required key

   \return Pointer to Key, if found; NULL, if not found

   \note This returns a pointer to the key inside the keyring, not a
   copy.  Do not free it.

*/
const __ops_key_t *
__ops_getkeybyname(__ops_io_t *io,
			const __ops_keyring_t *keyring,
			const char *name)
{
	unsigned	from;

	from = 0;
	return getkeybyname(io, keyring, name, &from);
}

const __ops_key_t *
__ops_getnextkeybyname(__ops_io_t *io,
			const __ops_keyring_t *keyring,
			const char *name,
			unsigned *n)
{
	return getkeybyname(io, keyring, name, n);
}

/**
   \ingroup HighLevel_KeyringList

   \brief Prints all keys in keyring to stdout.

   \param keyring Keyring to use

   \return none
*/
int
__ops_keyring_list(__ops_io_t *io, const __ops_keyring_t *keyring, const int psigs)
{
	__ops_key_t		*key;
	unsigned		 n;

	(void) fprintf(io->res, "%u key%s\n", keyring->keyc,
		(keyring->keyc == 1) ? "" : "s");
	for (n = 0, key = keyring->keys; n < keyring->keyc; ++n, ++key) {
		if (__ops_is_key_secret(key)) {
			__ops_print_keydata(io, keyring, key, "sec",
				&key->key.seckey.pubkey, 0);
		} else {
			__ops_print_keydata(io, keyring, key, "signature ", &key->key.pubkey, psigs);
		}
		(void) fputc('\n', io->res);
	}
	return 1;
}

int
__ops_keyring_json(__ops_io_t *io, const __ops_keyring_t *keyring, mj_t *obj, const int psigs)
{
	__ops_key_t		*key;
	unsigned		 n;

	(void) memset(obj, 0x0, sizeof(*obj));
	mj_create(obj, "array");
	obj->size = keyring->keyvsize;
	if (__ops_get_debug_level(__FILE__)) {
		(void) fprintf(io->errs, "__ops_keyring_json: vsize %u\n", obj->size);
	}
	if ((obj->value.v = calloc(sizeof(*obj->value.v), obj->size)) == NULL) {
		(void) fprintf(io->errs, "calloc failure\n");
		return 0;
	}
	for (n = 0, key = keyring->keys; n < keyring->keyc; ++n, ++key) {
		if (__ops_is_key_secret(key)) {
			__ops_sprint_mj(io, keyring, key, &obj->value.v[obj->c],
				"sec", &key->key.seckey.pubkey, psigs);
		} else {
			__ops_sprint_mj(io, keyring, key, &obj->value.v[obj->c],
				"signature ", &key->key.pubkey, psigs);
		}
		if (obj->value.v[obj->c].type != 0) {
			obj->c += 1;
		}
	}
	if (__ops_get_debug_level(__FILE__)) {
		char	*s;

		mj_asprint(&s, obj);
		(void) fprintf(stderr, "__ops_keyring_json: '%s'\n", s);
		free(s);
	}
	return 1;
}


/* this interface isn't right - hook into callback for getting passphrase */
char *
__ops_export_key(__ops_io_t *io, const __ops_key_t *keydata, uint8_t *passphrase)
{
	__ops_output_t	*output;
	__ops_memory_t	*mem;
	char		*cp;

	__OPS_USED(io);
	__ops_setup_memory_write(&output, &mem, 128);
	if (keydata->type == OPS_PTAG_CT_PUBLIC_KEY) {
		__ops_write_xfer_pubkey(output, keydata, 1);
	} else {
		__ops_write_xfer_seckey(output, keydata, passphrase,
					strlen((char *)passphrase), 1);
	}
	cp = netpgp_strdup(__ops_mem_data(mem));
	__ops_teardown_memory_write(output, mem);
	return cp;
}

/* add a key to a public keyring */
int
__ops_add_to_pubring(__ops_keyring_t *keyring, const __ops_pubkey_t *pubkey, __ops_content_enum tag)
{
	__ops_key_t	*key;
	time_t		 duration;

	if (__ops_get_debug_level(__FILE__)) {
		fprintf(stderr, "__ops_add_to_pubring (type %u)\n", tag);
	}
	switch(tag) {
	case OPS_PTAG_CT_PUBLIC_KEY:
		EXPAND_ARRAY(keyring, key);
		key = &keyring->keys[keyring->keyc++];
		duration = key->key.pubkey.duration;
		(void) memset(key, 0x0, sizeof(*key));
		key->type = tag;
		__ops_keyid(key->sigid, OPS_KEY_ID_SIZE, pubkey, keyring->hashtype);
		__ops_fingerprint(&key->sigfingerprint, pubkey, keyring->hashtype);
		key->key.pubkey = *pubkey;
		key->key.pubkey.duration = duration;
		return 1;
	case OPS_PTAG_CT_PUBLIC_SUBKEY:
		/* subkey is not the first */
		key = &keyring->keys[keyring->keyc - 1];
		__ops_keyid(key->encid, OPS_KEY_ID_SIZE, pubkey, keyring->hashtype);
		duration = key->key.pubkey.duration;
		(void) memcpy(&key->enckey, pubkey, sizeof(key->enckey));
		key->enckey.duration = duration;
		return 1;
	default:
		return 0;
	}
}

/* add a key to a secret keyring */
int
__ops_add_to_secring(__ops_keyring_t *keyring, const __ops_seckey_t *seckey)
{
	const __ops_pubkey_t	*pubkey;
	__ops_key_t		*key;

	if (__ops_get_debug_level(__FILE__)) {
		fprintf(stderr, "__ops_add_to_secring\n");
	}
	if (keyring->keyc > 0) {
		key = &keyring->keys[keyring->keyc - 1];
		if (__ops_get_debug_level(__FILE__) &&
		    key->key.pubkey.alg == OPS_PKA_DSA &&
		    seckey->pubkey.alg == OPS_PKA_ELGAMAL) {
			fprintf(stderr, "__ops_add_to_secring: found elgamal seckey\n");
		}
	}
	EXPAND_ARRAY(keyring, key);
	key = &keyring->keys[keyring->keyc++];
	(void) memset(key, 0x0, sizeof(*key));
	pubkey = &seckey->pubkey;
	__ops_keyid(key->sigid, OPS_KEY_ID_SIZE, pubkey, keyring->hashtype);
	__ops_fingerprint(&key->sigfingerprint, pubkey, keyring->hashtype);
	key->type = OPS_PTAG_CT_SECRET_KEY;
	key->key.seckey = *seckey;
	if (__ops_get_debug_level(__FILE__)) {
		fprintf(stderr, "__ops_add_to_secring: keyc %u\n", keyring->keyc);
	}
	return 1;
}

/* append one keyring to another */
int
__ops_append_keyring(__ops_keyring_t *keyring, __ops_keyring_t *newring)
{
	unsigned	i;

	for (i = 0 ; i < newring->keyc ; i++) {
		EXPAND_ARRAY(keyring, key);
		(void) memcpy(&keyring->keys[keyring->keyc], &newring->keys[i],
				sizeof(newring->keys[i]));
		keyring->keyc += 1;
	}
	return 1;
}
