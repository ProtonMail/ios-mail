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
#include "config.h"

#ifdef HAVE_SYS_CDEFS_H
#include <sys/cdefs.h>
#endif

#if defined(__NetBSD__)
__COPYRIGHT("@(#) Copyright (c) 2009 The NetBSD Foundation, Inc. All rights reserved.");
__RCSID("$NetBSD: netpgp.c,v 1.80 2010/11/04 15:38:45 agc Exp $");
#endif

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/param.h>
#include <sys/mman.h>

#ifdef HAVE_SYS_RESOURCE_H
#include <sys/resource.h>
#endif

#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif

#include <errno.h>
#include <regex.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

#include <errno.h>

#ifdef HAVE_LIMITS_H
#include <limits.h>
#endif

#include "netpgp.h"

#include "packet.h"
#include "packet-parse.h"
#include "keyring.h"
#include "errors.h"
#include "packet-show.h"
#include "create.h"
#include "netpgpsdk.h"
#include "memory.h"
#include "validate.h"
#include "readerwriter.h"
#include "netpgpdefs.h"
#include "crypto.h"
#include "ops-ssh.h"
#include "defs.h"

/* read any gpg config file */
static int
conffile(netpgp_t *netpgp, char *homedir, char *userid, size_t length)
{
	regmatch_t	 matchv[10];
	regex_t		 keyre;
	char		 buf[BUFSIZ];
	FILE		*fp;

	__OPS_USED(netpgp);
	(void) snprintf(buf, sizeof(buf), "%s/gpg.conf", homedir);
	if ((fp = fopen(buf, "r")) == NULL) {
		return 0;
	}
	(void) memset(&keyre, 0x0, sizeof(keyre));
	(void) regcomp(&keyre, "^[ \t]*default-key[ \t]+([0-9a-zA-F]+)",
		REG_EXTENDED);
	while (fgets(buf, (int)sizeof(buf), fp) != NULL) {
		if (regexec(&keyre, buf, 10, matchv, 0) == 0) {
			(void) memcpy(userid, &buf[(int)matchv[1].rm_so],
				MIN((unsigned)(matchv[1].rm_eo -
						matchv[1].rm_so), length));
			if (netpgp->passfp == NULL) {
				(void) fprintf(stderr,
				"netpgp: default key set to \"%.*s\"\n",
				(int)(matchv[1].rm_eo - matchv[1].rm_so),
				&buf[(int)matchv[1].rm_so]);
			}
		}
	}
	(void) fclose(fp);
	regfree(&keyre);
	return 1;
}

/* small function to pretty print an 8-character raw userid */
static char    *
userid_to_id(const uint8_t *userid, char *id)
{
	static const char *hexes = "0123456789abcdef";
	int		   i;

	for (i = 0; i < 8 ; i++) {
		id[i * 2] = hexes[(unsigned)(userid[i] & 0xf0) >> 4];
		id[(i * 2) + 1] = hexes[userid[i] & 0xf];
	}
	id[8 * 2] = 0x0;
	return id;
}

/* print out the successful signature information */
static void
resultp(__ops_io_t *io,
	const char *f,
	__ops_validation_t *res,
	__ops_keyring_t *ring)
{
	const __ops_key_t	*key;
	__ops_pubkey_t		*sigkey;
	unsigned		 from;
	unsigned		 i;
	time_t			 t;
	char			 id[MAX_ID_LENGTH + 1];

	for (i = 0; i < res->validc; i++) {
		(void) fprintf(io->res,
			"Good signature for %s made %s",
			(f) ? f : "<stdin>",
			ctime(&res->valid_sigs[i].birthtime));
		if (res->duration > 0) {
			t = res->birthtime + res->duration;
			(void) fprintf(io->res, "Valid until %s", ctime(&t));
		}
		(void) fprintf(io->res,
			"using %s key %s\n",
			__ops_show_pka(res->valid_sigs[i].key_alg),
			userid_to_id(res->valid_sigs[i].signer_id, id));
		from = 0;
		key = __ops_getkeybyid(io, ring,
			(const uint8_t *) res->valid_sigs[i].signer_id,
			&from, &sigkey);
		if (sigkey == &key->enckey) {
			(void) fprintf(io->res,
				"WARNING: signature for %s made with encryption key\n",
				(f) ? f : "<stdin>");
		}
		__ops_print_keydata(io, ring, key, "signature ", &key->key.pubkey, 0);
	}
}

/* check there's enough space in the arrays */
static int
size_arrays(netpgp_t *netpgp, unsigned needed)
{
	char	**temp;

	if (netpgp->size == 0) {
		/* only get here first time around */
		netpgp->size = needed;
		if ((netpgp->name = calloc(sizeof(char *), needed)) == NULL) {
			(void) fprintf(stderr, "size_arrays: bad alloc\n");
			return 0;
		}
		if ((netpgp->value = calloc(sizeof(char *), needed)) == NULL) {
			free(netpgp->name);
			(void) fprintf(stderr, "size_arrays: bad alloc\n");
			return 0;
		}
	} else if (netpgp->c == netpgp->size) {
		/* only uses 'needed' when filled array */
		netpgp->size += needed;
		temp = realloc(netpgp->name, sizeof(char *) * needed);
		if (temp == NULL) {
			(void) fprintf(stderr, "size_arrays: bad alloc\n");
			return 0;
		}
		netpgp->name = temp;
		temp = realloc(netpgp->value, sizeof(char *) * needed);
		if (temp == NULL) {
			(void) fprintf(stderr, "size_arrays: bad alloc\n");
			return 0;
		}
		netpgp->value = temp;
	}
	return 1;
}

/* find the name in the array */
static int
findvar(netpgp_t *netpgp, const char *name)
{
	unsigned	i;

	for (i = 0 ; i < netpgp->c && strcmp(netpgp->name[i], name) != 0; i++) {
	}
	return (i == netpgp->c) ? -1 : (int)i;
}

/* read a keyring and return it */
static void *
readkeyring(netpgp_t *netpgp, const char *name)
{
	__ops_keyring_t	*keyring;
	const unsigned	 noarmor = 0;
	char		 f[MAXPATHLEN];
	char		*filename;
	char		*homedir;

	homedir = netpgp_getvar(netpgp, "homedir");
	if ((filename = netpgp_getvar(netpgp, name)) == NULL) {
		(void) snprintf(f, sizeof(f), "%s/%s.gpg", homedir, name);
		filename = f;
	}
	if ((keyring = calloc(1, sizeof(*keyring))) == NULL) {
		(void) fprintf(stderr, "readkeyring: bad alloc\n");
		return NULL;
	}
	if (!__ops_keyring_fileread(keyring, noarmor, filename)) {
		free(keyring);
		(void) fprintf(stderr, "Can't read %s %s\n", name, filename);
		return NULL;
	}
	netpgp_setvar(netpgp, name, filename);
	return keyring;
}

/* read keys from ssh key files */
static int
readsshkeys(netpgp_t *netpgp, char *homedir, const char *needseckey)
{
	__ops_keyring_t	*pubring;
	__ops_keyring_t	*secring;
	struct stat	 st;
	unsigned	 hashtype;
	char		*hash;
	char		 f[MAXPATHLEN];
	char		*filename;

	if ((filename = netpgp_getvar(netpgp, "sshkeyfile")) == NULL) {
		/* set reasonable default for RSA key */
		(void) snprintf(f, sizeof(f), "%s/id_rsa.pub", homedir);
		filename = f;
	} else if (strcmp(&filename[strlen(filename) - 4], ".pub") != 0) {
		/* got ssh keys, check for pub file name */
		(void) snprintf(f, sizeof(f), "%s.pub", filename);
		filename = f;
	}
	/* check the pub file exists */
	if (stat(filename, &st) != 0) {
		(void) fprintf(stderr, "readsshkeys: bad pubkey filename '%s'\n", filename);
		return 0;
	}
	if ((pubring = calloc(1, sizeof(*pubring))) == NULL) {
		(void) fprintf(stderr, "readsshkeys: bad alloc\n");
		return 0;
	}
	/* openssh2 keys use md5 by default */
	hashtype = OPS_HASH_MD5;
	if ((hash = netpgp_getvar(netpgp, "hash")) != NULL) {
		/* openssh 2 hasn't really caught up to anything else yet */
		if (netpgp_strcasecmp(hash, "md5") == 0) {
			hashtype = OPS_HASH_MD5;
		} else if (netpgp_strcasecmp(hash, "sha1") == 0) {
			hashtype = OPS_HASH_SHA1;
		} else if (netpgp_strcasecmp(hash, "sha256") == 0) {
			hashtype = OPS_HASH_SHA256;
		}
	}
	if (!__ops_ssh2_readkeys(netpgp->io, pubring, NULL, filename, NULL, hashtype)) {
		free(pubring);
		(void) fprintf(stderr, "readsshkeys: can't read %s\n",
				filename);
		return 0;
	}
	if (netpgp->pubring == NULL) {
		netpgp->pubring = pubring;
	} else {
		__ops_append_keyring(netpgp->pubring, pubring);
	}
	if (needseckey) {
		netpgp_setvar(netpgp, "sshpubfile", filename);
		/* try to take the ".pub" off the end */
		if (filename == f) {
			f[strlen(f) - 4] = 0x0;
		} else {
			(void) snprintf(f, sizeof(f), "%.*s",
					(int)strlen(filename) - 4, filename);
			filename = f;
		}
		if ((secring = calloc(1, sizeof(*secring))) == NULL) {
			(void) fprintf(stderr, "readsshkeys: bad alloc\n");
			return 0;
		}
		if (!__ops_ssh2_readkeys(netpgp->io, pubring, secring, NULL, filename, hashtype)) {
			(void) fprintf(stderr, "readsshkeys: can't read sec %s\n", filename);
			return 0;
		}
		netpgp->secring = secring;
		netpgp_setvar(netpgp, "sshsecfile", filename);
	}
	return 1;
}

/* set ssh uid to first one in pubring */
static void
set_first_pubring(__ops_keyring_t *pubring, char *id, size_t len, int last)
{
	uint8_t	*src;
	int	 i;
	int	 n;

	(void) memset(id, 0x0, len);
	src = pubring->keys[(last) ? pubring->keyc - 1 : 0].sigid;
	for (i = 0, n = 0 ; i < OPS_KEY_ID_SIZE ; i += 2) {
		n += snprintf(&id[n], len - n, "%02x%02x", src[i], src[i + 1]);
	}
	id[n] = 0x0;
}

/* find the time - in a specific %Y-%m-%d format - using a regexp */
static int
grabdate(char *s, int64_t *t)
{
	static regex_t	r;
	static int	compiled;
	regmatch_t	matches[10];
	struct tm	tm;

	if (!compiled) {
		compiled = 1;
		(void) regcomp(&r, "([0-9][0-9][0-9][0-9])[-/]([0-9][0-9])[-/]([0-9][0-9])", REG_EXTENDED);
	}
	if (regexec(&r, s, 10, matches, 0) == 0) {
		(void) memset(&tm, 0x0, sizeof(tm));
		tm.tm_year = (int)strtol(&s[(int)matches[1].rm_so], NULL, 10);
		tm.tm_mon = (int)strtol(&s[(int)matches[2].rm_so], NULL, 10) - 1;
		tm.tm_mday = (int)strtol(&s[(int)matches[3].rm_so], NULL, 10);
		*t = mktime(&tm);
		return 1;
	}
	return 0;
}

/* get expiration in seconds */
static uint64_t
get_duration(char *s)
{
	uint64_t	 now;
	int64_t	 	 t;
	char		*mult;

	if (s == NULL) {
		return 0;
	}
	now = (uint64_t)strtoull(s, NULL, 10);
	if ((mult = strchr("hdwmy", s[strlen(s) - 1])) != NULL) {
		switch(*mult) {
		case 'h':
			return now * 60 * 60;
		case 'd':
			return now * 60 * 60 * 24;
		case 'w':
			return now * 60 * 60 * 24 * 7;
		case 'm':
			return now * 60 * 60 * 24 * 31;
		case 'y':
			return now * 60 * 60 * 24 * 365;
		}
	}
	if (grabdate(s, &t)) {
		return t;
	}
	return (uint64_t)strtoll(s, NULL, 10);
}

/* get birthtime in seconds */
static int64_t
get_birthtime(char *s)
{
	int64_t	t;

	if (s == NULL) {
		return time(NULL);
	}
	if (grabdate(s, &t)) {
		return t;
	}
	return (uint64_t)strtoll(s, NULL, 10);
}

/* resolve the userid */
static const __ops_key_t *
resolve_userid(netpgp_t *netpgp, const __ops_keyring_t *keyring, const char *userid)
{
	const __ops_key_t	*key;
	__ops_io_t		*io;

	if (userid == NULL) {
		userid = netpgp_getvar(netpgp, "userid");
		if (userid == NULL)
			return NULL;
	} else if (userid[0] == '0' && userid[1] == 'x') {
		userid += 2;
	}
	io = netpgp->io;
	if ((key = __ops_getkeybyname(io, keyring, userid)) == NULL) {
		(void) fprintf(io->errs, "Can't find key '%s'\n", userid);
	}
	return key;
}

/* append a key to a keyring */
static int
appendkey(__ops_io_t *io, __ops_key_t *key, char *ringfile)
{
	__ops_output_t	*create;
	const unsigned	 noarmor = 0;
	int		 fd;

	if ((fd = __ops_setup_file_append(&create, ringfile)) < 0) {
		fd = __ops_setup_file_write(&create, ringfile, 0);
	}
	if (fd < 0) {
		(void) fprintf(io->errs, "can't open pubring '%s'\n", ringfile);
		return 0;
	}
	if (!__ops_write_xfer_pubkey(create, key, noarmor)) {
		(void) fprintf(io->errs, "Cannot write pubkey\n");
		return 0;
	}
	__ops_teardown_file_write(create, fd);
	return 1;
}

/* return 1 if the file contains ascii-armoured text */
static unsigned
isarmoured(__ops_io_t *io, const char *f, const void *memory, const char *text)
{
	unsigned	 armoured;
	FILE		*fp;
	char	 	 buf[BUFSIZ];

	armoured = 0;
	if (f) {
		if ((fp = fopen(f, "r")) == NULL) {
			(void) fprintf(io->errs, "isarmoured: can't open '%s'\n", f);
			return 0;
		}
		if (fgets(buf, (int)sizeof(buf), fp) != NULL) {
			armoured = (strncmp(buf, text, strlen(text)) == 0);
		}
		(void) fclose(fp);
	} else {
		armoured = (strncmp(memory, text, strlen(text)) == 0);
	}
	return armoured;
}

/* vararg print function */
static void
p(FILE *fp, const char *s, ...)
{
	va_list	args;

	va_start(args, s);
	while (s != NULL) {
		(void) fprintf(fp, "%s", s);
		s = va_arg(args, char *);
	}
	va_end(args);
}

/* print a JSON object to the FILE stream */
static void
pobj(FILE *fp, mj_t *obj, int depth)
{
	unsigned	i;

	if (obj == NULL) {
		(void) fprintf(stderr, "No object found\n");
		return;
	}
	for (i = 0 ; i < (unsigned)depth ; i++) {
		p(fp, " ", NULL);
	}
	switch(obj->type) {
	case MJ_NULL:
	case MJ_FALSE:
	case MJ_TRUE:
		p(fp, (obj->type == MJ_NULL) ? "null" : (obj->type == MJ_FALSE) ? "false" : "true", NULL);
		break;
	case MJ_NUMBER:
		p(fp, obj->value.s, NULL);
		break;
	case MJ_STRING:
		(void) fprintf(fp, "%.*s", (int)(obj->c), obj->value.s);
		break;
	case MJ_ARRAY:
		for (i = 0 ; i < obj->c ; i++) {
			pobj(fp, &obj->value.v[i], depth + 1);
			if (i < obj->c - 1) {
				(void) fprintf(fp, ", "); 
			}
		}
		(void) fprintf(fp, "\n"); 
		break;
	case MJ_OBJECT:
		for (i = 0 ; i < obj->c ; i += 2) {
			pobj(fp, &obj->value.v[i], depth + 1);
			p(fp, ": ", NULL); 
			pobj(fp, &obj->value.v[i + 1], 0);
			if (i < obj->c - 1) {
				p(fp, ", ", NULL); 
			}
		}
		p(fp, "\n", NULL); 
		break;
	default:
		break;
	}
}

/* return the time as a string */
static char * 
ptimestr(char *dest, size_t size, time_t t)
{
	struct tm      *tm;

	tm = gmtime(&t);
	(void) snprintf(dest, size, "%04d-%02d-%02d",
		tm->tm_year + 1900,
		tm->tm_mon + 1,
		tm->tm_mday);
	return dest;
}

/* format a JSON object */
static void
format_json_key(FILE *fp, mj_t *obj, const int psigs)
{
	int64_t	 birthtime;
	int64_t	 duration;
	time_t	 now;
	char	 tbuf[32];
	char	*s;
	mj_t	*sub;
	int	 i;

	if (__ops_get_debug_level(__FILE__)) {
		mj_asprint(&s, obj);
		(void) fprintf(stderr, "formatobj: json is '%s'\n", s);
		free(s);
	}
	if (obj->c == 2 && obj->value.v[1].type == MJ_STRING &&
	    strcmp(obj->value.v[1].value.s, "[REVOKED]") == 0) {
		/* whole key has been rovoked - just return */
		return;
	}
	pobj(fp, &obj->value.v[mj_object_find(obj, "header", 0, 2) + 1], 0);
	p(fp, " ", NULL);
	pobj(fp, &obj->value.v[mj_object_find(obj, "key bits", 0, 2) + 1], 0);
	p(fp, "/", NULL);
	pobj(fp, &obj->value.v[mj_object_find(obj, "pka", 0, 2) + 1], 0);
	p(fp, " ", NULL);
	pobj(fp, &obj->value.v[mj_object_find(obj, "key id", 0, 2) + 1], 0);
	birthtime = strtoll(obj->value.v[mj_object_find(obj, "birthtime", 0, 2) + 1].value.s, NULL, 10);
	p(fp, " ", ptimestr(tbuf, sizeof(tbuf), birthtime), NULL);
	duration = strtoll(obj->value.v[mj_object_find(obj, "duration", 0, 2) + 1].value.s, NULL, 10);
	if (duration > 0) {
		now = time(NULL);
		p(fp, " ", (birthtime + duration < now) ? "[EXPIRED " : "[EXPIRES ",
			ptimestr(tbuf, sizeof(tbuf), birthtime + duration), "]", NULL);
	}
	p(fp, "\n", "Key fingerprint: ", NULL);
	pobj(fp, &obj->value.v[mj_object_find(obj, "fingerprint", 0, 2) + 1], 0);
	p(fp, "\n", NULL);
	/* go to field after \"duration\" */
	for (i = mj_object_find(obj, "duration", 0, 2) + 2; i < mj_arraycount(obj) ; i += 2) {
		if (strcmp(obj->value.v[i].value.s, "uid") == 0) {
			sub = &obj->value.v[i + 1];
			p(fp, "uid", NULL);
			pobj(fp, &sub->value.v[0], (psigs) ? 4 : 14); /* human name */
			pobj(fp, &sub->value.v[1], 1); /* any revocation */
			p(fp, "\n", NULL);
		} else if (strcmp(obj->value.v[i].value.s, "encryption") == 0) {
			sub = &obj->value.v[i + 1];
			p(fp, "encryption", NULL);
			pobj(fp, &sub->value.v[0], 1);	/* size */
			p(fp, "/", NULL);
			pobj(fp, &sub->value.v[1], 0); /* alg */
			p(fp, " ", NULL);
			pobj(fp, &sub->value.v[2], 0); /* id */
			p(fp, " ", ptimestr(tbuf, sizeof(tbuf), strtoll(sub->value.v[3].value.s, NULL, 10)),
				"\n", NULL);
		} else if (strcmp(obj->value.v[i].value.s, "sig") == 0) {
			sub = &obj->value.v[i + 1];
			p(fp, "sig", NULL);
			pobj(fp, &sub->value.v[0], 8);	/* size */
			p(fp, "  ", ptimestr(tbuf, sizeof(tbuf), strtoll(sub->value.v[1].value.s, NULL, 10)),
				" ", NULL); /* time */
			pobj(fp, &sub->value.v[2], 0); /* human name */
			p(fp, "\n", NULL);
		} else {
			fprintf(stderr, "weird '%s'\n", obj->value.v[i].value.s);
			pobj(fp, &obj->value.v[i], 0); /* human name */
		}
	}
	p(fp, "\n", NULL);
}

/* save a pgp pubkey to a temp file */
static int
savepubkey(char *res, char *f, size_t size)
{
	size_t	len;
	int	cc;
	int	wc;
	int	fd;

	(void) snprintf(f, size, "/tmp/pgp2ssh.XXXXXXX");
	if ((fd = mkstemp(f)) < 0) {
		(void) fprintf(stderr, "can't create temp file '%s'\n", f);
		return 0;
	}
	len = strlen(res);
	for (cc = 0 ; (wc = (int)MIN(write(fd, &res[cc], len - cc),INT_MAX)) > 0 ; cc += wc) {
	}
	(void) close(fd);
	return 1;
}

/* format a uint32_t */
static int
formatu32(uint8_t *buffer, uint32_t value)
{
	buffer[0] = (uint8_t)(value >> 24) & 0xff;
	buffer[1] = (uint8_t)(value >> 16) & 0xff;
	buffer[2] = (uint8_t)(value >> 8) & 0xff;
	buffer[3] = (uint8_t)value & 0xff;
	return sizeof(uint32_t);
}

/* format a string as (len, string) */
static int
formatstring(char *buffer, const uint8_t *s, size_t len)
{
	int	cc;

	cc = formatu32((uint8_t *)buffer, (int)MIN(len,INT_MAX));
	(void) memcpy(&buffer[cc], s, len);
	return cc + (int)MIN(len,INT_MAX);
}

/* format a bignum, checking for "interesting" high bit values */
static int
formatbignum(char *buffer, BIGNUM *bn)
{
	size_t	 len;
	uint8_t	*cp;
	int	 cc;

	len = (size_t) BN_num_bytes(bn);
	if ((cp = calloc(1, len + 1)) == NULL) {
		(void) fprintf(stderr, "calloc failure in formatbignum\n");
		return 0;
	}
	(void) BN_bn2bin(bn, cp + 1);
	cp[0] = 0x0;
	cc = (cp[1] & 0x80) ? formatstring(buffer, cp, len + 1) : formatstring(buffer, &cp[1], len);
	free(cp);
	return cc;
}

/***************************************************************************/
/* exported functions start here */
/***************************************************************************/

/* initialise a netpgp_t structure */
int
netpgp_init(netpgp_t *netpgp)
{
	__ops_io_t	*io;
	char		 id[MAX_ID_LENGTH];
	char		*homedir;
	char		*userid;
	char		*stream;
	char		*passfd;
	char		*results;
	int		 coredumps;
	int		 last;

#ifdef HAVE_SYS_RESOURCE_H
	struct rlimit	limit;

	coredumps = netpgp_getvar(netpgp, "coredumps") != NULL;
	if (!coredumps) {
		(void) memset(&limit, 0x0, sizeof(limit));
		if (setrlimit(RLIMIT_CORE, &limit) != 0) {
			(void) fprintf(stderr,
			"netpgp: warning - can't turn off core dumps\n");
			coredumps = 1;
		}
	}
#else
	coredumps = 1;
#endif
	if ((io = calloc(1, sizeof(*io))) == NULL) {
		(void) fprintf(stderr, "netpgp_init: bad alloc\n");
		return 0;
	}
	io->outs = stdout;
	if ((stream = netpgp_getvar(netpgp, "outs")) != NULL &&
	    strcmp(stream, "<stderr>") == 0) {
		io->outs = stderr;
	}
	io->errs = stderr;
	if ((stream = netpgp_getvar(netpgp, "errs")) != NULL &&
	    strcmp(stream, "<stdout>") == 0) {
		io->errs = stdout;
	}
	if ((results = netpgp_getvar(netpgp, "res")) == NULL) {
		io->res = io->errs;
	} else if (strcmp(results, "<stdout>") == 0) {
		io->res = stdout;
	} else if (strcmp(results, "<stderr>") == 0) {
		io->res = stderr;
	} else {
		if ((io->res = fopen(results, "w")) == NULL) {
			(void) fprintf(io->errs, "Can't open results %s for writing\n",
				results);
			free(io);
			return 0;
		}
	}
	netpgp->io = io;
	if ((passfd = netpgp_getvar(netpgp, "pass-fd")) != NULL &&
	    (netpgp->passfp = fdopen(atoi(passfd), "r")) == NULL) {
		(void) fprintf(io->errs, "Can't open fd %s for reading\n",
			passfd);
		return 0;
	}
	if (coredumps) {
		(void) fprintf(io->errs,
			"netpgp: warning: core dumps enabled\n");
	}
	if ((homedir = netpgp_getvar(netpgp, "homedir")) == NULL) {
		(void) fprintf(io->errs, "netpgp: bad homedir\n");
		return 0;
	}
	/* read from either gpg files or ssh keys */
	if (netpgp_getvar(netpgp, "ssh keys") == NULL) {
		if ((userid = netpgp_getvar(netpgp, "userid")) == NULL) {
			(void) memset(id, 0x0, sizeof(id));
			(void) conffile(netpgp, homedir, id, sizeof(id));
			if (id[0] != 0x0) {
				netpgp_setvar(netpgp, "userid", userid = id);
			}
		}
		if (userid == NULL) {
			if (netpgp_getvar(netpgp, "need userid") != NULL) {
				(void) fprintf(io->errs,
						"Cannot find user id\n");
				return 0;
			}
		} else {
			(void) netpgp_setvar(netpgp, "userid", userid);
		}
		netpgp->pubring = readkeyring(netpgp, "pubring");
		if (netpgp->pubring == NULL) {
			(void) fprintf(io->errs, "Can't read pub keyring\n");
			return 0;
		}
		netpgp->secring = readkeyring(netpgp, "secring");
		if (netpgp->secring == NULL) {
			(void) fprintf(io->errs, "Can't read sec keyring\n");
			return 0;
		}
	} else {
		last = (netpgp->pubring != NULL);
		if (!readsshkeys(netpgp, homedir, netpgp_getvar(netpgp, "need seckey"))) {
			(void) fprintf(io->errs, "Can't read ssh keys\n");
			return 0;
		}
		if ((userid = netpgp_getvar(netpgp, "userid")) == NULL) {
			set_first_pubring(netpgp->pubring, id, sizeof(id), last);
			netpgp_setvar(netpgp, "userid", userid = id);
		}
		if (userid == NULL) {
			if (netpgp_getvar(netpgp, "need userid") != NULL) {
				(void) fprintf(io->errs,
						"Cannot find user id\n");
				return 0;
			}
		} else {
			(void) netpgp_setvar(netpgp, "userid", userid);
		}
	}
	return 1;
}

/* finish off with the netpgp_t struct */
int
netpgp_end(netpgp_t *netpgp)
{
	unsigned	i;

	for (i = 0 ; i < netpgp->c ; i++) {
		if (netpgp->name[i] != NULL) {
			free(netpgp->name[i]);
		}
		if (netpgp->value[i] != NULL) {
			free(netpgp->value[i]);
		}
	}
	if (netpgp->name != NULL) {
		free(netpgp->name);
	}
	if (netpgp->value != NULL) {
		free(netpgp->value);
	}
	if (netpgp->pubring != NULL) {
		__ops_keyring_free(netpgp->pubring);
	}
	if (netpgp->secring != NULL) {
		__ops_keyring_free(netpgp->secring);
	}
	free(netpgp->io);
	return 1;
}

/* list the keys in a keyring */
int
netpgp_list_keys(netpgp_t *netpgp, const int psigs)
{
	if (netpgp->pubring == NULL) {
		(void) fprintf(stderr, "No keyring\n");
		return 0;
	}
	return __ops_keyring_list(netpgp->io, netpgp->pubring, psigs);
}

/* list the keys in a keyring, returning a JSON string */
int
netpgp_list_keys_json(netpgp_t *netpgp, char **json, const int psigs)
{
	mj_t	obj;
	int	ret;

	if (netpgp->pubring == NULL) {
		(void) fprintf(stderr, "No keyring\n");
		return 0;
	}
	(void) memset(&obj, 0x0, sizeof(obj));
	if (!__ops_keyring_json(netpgp->io, netpgp->pubring, &obj, psigs)) {
		(void) fprintf(stderr, "No keys in keyring\n");
		return 0;
	}
	ret = mj_asprint(json, &obj);
	mj_delete(&obj);
	return ret;
}

DEFINE_ARRAY(strings_t, char *);

#ifndef HKP_VERSION
#define HKP_VERSION	1
#endif

/* find and list some keys in a keyring */
int
netpgp_match_keys(netpgp_t *netpgp, char *name, const char *fmt, void *vp, const int psigs)
{
	const __ops_key_t	*key;
	unsigned		 k;
	strings_t		 pubs;
	FILE			*fp = (FILE *)vp;

	if (name[0] == '0' && name[1] == 'x') {
		name += 2;
	}
	(void) memset(&pubs, 0x0, sizeof(pubs));
	k = 0;
	do {
		key = __ops_getnextkeybyname(netpgp->io, netpgp->pubring,
						name, &k);
		if (key != NULL) {
			ALLOC(char *, pubs.v, pubs.size, pubs.c, 10, 10,
					"netpgp_match_keys", return 0);
			if (strcmp(fmt, "mr") == 0) {
				__ops_hkp_sprint_keydata(netpgp->io, netpgp->pubring,
						key, &pubs.v[pubs.c],
						&key->key.pubkey, psigs);
			} else {
				__ops_sprint_keydata(netpgp->io, netpgp->pubring,
						key, &pubs.v[pubs.c],
						"signature ",
						&key->key.pubkey, psigs);
			}
			if (pubs.v[pubs.c] != NULL) {
				pubs.c += 1;
			}
			k += 1;
		}
	} while (key != NULL);
	if (strcmp(fmt, "mr") == 0) {
		(void) fprintf(fp, "info:%d:%d\n", HKP_VERSION, pubs.c);
	} else {
		(void) fprintf(fp, "%d key%s found\n", pubs.c,
			(pubs.c == 1) ? "" : "s");
	}
	for (k = 0 ; k < pubs.c ; k++) {
		(void) fprintf(fp, "%s%s", pubs.v[k], (k < pubs.c - 1) ? "\n" : "");
		free(pubs.v[k]);
	}
	free(pubs.v);
	return pubs.c;
}

/* find and list some keys in a keyring - return JSON string */
int
netpgp_match_keys_json(netpgp_t *netpgp, char **json, char *name, const char *fmt, const int psigs)
{
	const __ops_key_t	*key;
	unsigned		 k;
	mj_t			 id_array;
	int			 ret;

	if (name[0] == '0' && name[1] == 'x') {
		name += 2;
	}
	(void) memset(&id_array, 0x0, sizeof(id_array));
	k = 0;
	*json = NULL;
	mj_create(&id_array, "array");
	do {
		key = __ops_getnextkeybyname(netpgp->io, netpgp->pubring,
						name, &k);
		if (key != NULL) {
			if (strcmp(fmt, "mr") == 0) {
#if 0
				__ops_hkp_sprint_keydata(netpgp->io, netpgp->pubring,
						key, &pubs.v[pubs.c],
						&key->key.pubkey, psigs);
#endif
			} else {
				ALLOC(mj_t, id_array.value.v, id_array.size,
					id_array.c, 10, 10, "netpgp_match_keys_json", return 0);
				__ops_sprint_mj(netpgp->io, netpgp->pubring,
						key, &id_array.value.v[id_array.c++],
						"signature ",
						&key->key.pubkey, psigs);
			}
			k += 1;
		}
	} while (key != NULL);
	ret = mj_asprint(json, &id_array);
	mj_delete(&id_array);
	return ret;
}

/* find and list some public keys in a keyring */
int
netpgp_match_pubkeys(netpgp_t *netpgp, char *name, void *vp)
{
	const __ops_key_t	*key;
	unsigned		 k;
	strings_t		 pubs;
	FILE			*fp = (FILE *)vp;

	(void) memset(&pubs, 0x0, sizeof(pubs));
	do {
		key = __ops_getnextkeybyname(netpgp->io, netpgp->pubring,
						name, &k);
		if (key != NULL) {
			char	out[1024 * 64];

			ALLOC(char *, pubs.v, pubs.size, pubs.c, 10, 10,
					"netpgp_match_pubkeys", return 0);
			(void) __ops_sprint_pubkey(key, out, sizeof(out));
			pubs.v[pubs.c++] = netpgp_strdup(out);
			k += 1;
		}
	} while (key != NULL);
	(void) fprintf(fp, "info:%d:%d\n", HKP_VERSION, pubs.c);
	for (k = 0 ; k < pubs.c ; k++) {
		(void) fprintf(fp, "%s", pubs.v[k]);
		free(pubs.v[k]);
	}
	free(pubs.v);
	return pubs.c;
}

/* find a key in a keyring */
int
netpgp_find_key(netpgp_t *netpgp, char *id)
{
	__ops_io_t	*io;

	io = netpgp->io;
	if (id == NULL) {
		(void) fprintf(io->errs, "NULL id to search for\n");
		return 0;
	}
	return __ops_getkeybyname(netpgp->io, netpgp->pubring, id) != NULL;
}

/* get a key in a keyring */
char *
netpgp_get_key(netpgp_t *netpgp, const char *name, const char *fmt)
{
	const __ops_key_t	*key;
	char			*newkey;

	if ((key = resolve_userid(netpgp, netpgp->pubring, name)) == NULL) {
		return NULL;
	}
	if (strcmp(fmt, "mr") == 0) {
		return (__ops_hkp_sprint_keydata(netpgp->io, netpgp->pubring,
				key, &newkey,
				&key->key.pubkey,
				netpgp_getvar(netpgp, "subkey sigs") != NULL) > 0) ? newkey : NULL;
	}
	return (__ops_sprint_keydata(netpgp->io, netpgp->pubring,
				key, &newkey, "signature",
				&key->key.pubkey,
				netpgp_getvar(netpgp, "subkey sigs") != NULL) > 0) ? newkey : NULL;
}

/* export a given key */
char *
netpgp_export_key(netpgp_t *netpgp, char *name)
{
	const __ops_key_t	*key;
	__ops_io_t		*io;

	io = netpgp->io;
	if ((key = resolve_userid(netpgp, netpgp->pubring, name)) == NULL) {
		return NULL;
	}
    
    char pass[MAX_PASSPHRASE_LENGTH];
    __ops_forget(pass, (unsigned)sizeof(pass)); //clear pass array
    if (netpgp->passfp) {
        __ops_getpassphrase(netpgp->passfp, pass, sizeof(pass));
    }

    char *result = __ops_export_key(io, key, (strlen(pass) > 0) ? (uint8_t *)pass : NULL);
    __ops_forget(pass, (unsigned)sizeof(pass));

	return result;
}

#define IMPORT_ARMOR_HEAD	"-----BEGIN PGP PUBLIC KEY BLOCK-----"

/* import a key into our keyring */
int
netpgp_import_key(netpgp_t *netpgp, char *f)
{
	__ops_io_t	*io;
	unsigned	 realarmor;
	int		 done;

	io = netpgp->io;
	realarmor = isarmoured(io, f, NULL, IMPORT_ARMOR_HEAD);
	done = __ops_keyring_fileread(netpgp->pubring, realarmor, f);
	if (!done) {
		(void) fprintf(io->errs, "Cannot import key from file %s\n", f);
		return 0;
	}
	return __ops_keyring_list(io, netpgp->pubring, 0);
}

/* import a key into our keyring */
int
netpgp_import_public_key(netpgp_t *netpgp, char *f)
{
	__ops_keyring_t	*keyring; // read keyring
	__ops_io_t	*io;
	unsigned	 realarmor;
	int		 done;
    __ops_key_t		*key;
    unsigned n = 0;


	io = netpgp->io;
    realarmor = isarmoured(io, f, NULL, IMPORT_ARMOR_HEAD);

//    keyring = readkeyring(netpgp, f);
    if ((keyring = calloc(1, sizeof(*keyring))) == NULL) {
		(void) fprintf(stderr, "readkeyring: bad alloc\n");
		return 0;
	}

	done = __ops_keyring_fileread(keyring, realarmor, f);
	if (!done) {
		(void) fprintf(io->errs, "Cannot import key from file %s\n", f);
		return 0;
	}

    char *ringfile = netpgp_getvar(netpgp, "pubring");
    for (n = 0, key = keyring->keys; n < keyring->keyc; ++n, ++key) {
		if (!__ops_is_key_secret(key)) {
            if (key->type == OPS_PTAG_CT_PUBLIC_KEY) {
                if (!appendkey(io, key, ringfile)) {
                    (void) fprintf(io->errs, "Cannot write pubkey to '%s'\n", ringfile);
                    return 0;
                }
            }
        }
    }


    // append to netpgp keyring (I could load again but don't have to)
    done = __ops_append_keyring(netpgp->pubring, keyring);

    if (keyring != NULL) {
        __ops_keyring_free(keyring);
        free(keyring);
    }

    return done;
}

///* import a key into our keyring */
//int
//netpgp_import_secure_key(netpgp_t *netpgp, char *f)
//{
//	__ops_io_t	*io;
//	unsigned	 realarmor;
//	int		 done;
//    
//	io = netpgp->io;
//	realarmor = isarmoured(io, f, NULL, IMPORT_ARMOR_HEAD);
//	done = __ops_keyring_fileread(netpgp->secring, realarmor, f);
//	if (!done) {
//		(void) fprintf(io->errs, "Cannot import key from file %s\n", f);
//		return 0;
//	}
//    
//    /* import secret key */
//    __ops_keyring_t *keyring = netpgp->secring;
//    __ops_key_t		*key;
//    unsigned n = 0;
//
//    for (n = 0, key = keyring->keys; n < keyring->keyc; ++n, ++key) {
//		if (!__ops_is_key_secret(key)) {
//            char *ringfile = netpgp_getvar(netpgp, "pubring");
//            if (!appendkey(io, key, ringfile)) {
//                (void) fprintf(io->errs, "Cannot write pubkey to '%s'\n", ringfile);
//                return 0;
//            }
//		}
//		(void) fputc('\n', io->res);
//	}
//
////    for (n = 0, key = keyring->keys; n < keyring->keyc; ++n, ++key) {
////		if (__ops_is_key_secret(key)) {
////            const unsigned		 noarmor = 1;
////            __ops_output_t		*create;
////            int             	 fd;
////
////            char *ringfile = netpgp_getvar(netpgp, "secring");
////            if ((fd = __ops_setup_file_append(&create, ringfile)) < 0) {
////                fd = __ops_setup_file_write(&create, ringfile, 0);
////            }
////            if (fd < 0) {
////                (void) fprintf(io->errs, "can't append secring '%s'\n", ringfile);
////                return 0;
////            }
////            if (!__ops_write_xfer_seckey(create, key, NULL, 0, noarmor)) {
////                (void) fprintf(io->errs, "Cannot write seckey\n");
////                return 0;
////            }
////            __ops_teardown_file_write(create, fd);
////		}
////	}
//
//	return __ops_keyring_list(io, netpgp->pubring, 0);
//}


/* generate a new key */
/* output directory have to exists */
int
netpgp_generate_key_rich(netpgp_t *netpgp, char *id, int numbits, char *output_directory, int save_to_default_keyring)
{
	__ops_output_t		*create;
	const unsigned		 noarmor = 0;
	__ops_key_t		*key;
	__ops_io_t		*io;
	uint8_t			*uid;
	char			 newid[1024];
	char			 filename[MAXPATHLEN];
	char			 dir[MAXPATHLEN];
	char			*cp;
	char			*ringfile;
	int             	 fd;

	uid = NULL;
	io = netpgp->io;
	/* generate a new key */
	if (id) {
		(void) snprintf(newid, sizeof(newid), "%s", id);
	} else {
		(void) snprintf(newid, sizeof(newid),
			"RSA %d-bit key <%s@localhost>", numbits, getenv("LOGNAME"));
	}
	uid = (uint8_t *)newid;
	key = __ops_rsa_new_selfsign_key(numbits, 65537UL, uid,
			netpgp_getvar(netpgp, "hash"),
			netpgp_getvar(netpgp, "cipher"));
	if (key == NULL) {
		(void) fprintf(io->errs, "Cannot generate key\n");
		return 0;
	}
	cp = NULL;
	__ops_sprint_keydata(netpgp->io, NULL, key, &cp, "signature ", &key->key.seckey.pubkey, 0);
	(void) fprintf(stdout, "%s", cp);
	/* write public key */
    if (output_directory) {
        (void) snprintf(dir, sizeof(dir), "%s", output_directory);
        (void) fprintf(io->errs, "netpgp: generated keys in directory %s\n", dir);
        (void) snprintf(ringfile = filename, sizeof(filename), "%s/pubring.gpg", dir);
        if (!appendkey(io, key, ringfile)) {
            (void) fprintf(io->errs, "Cannot write pubkey to '%s'\n", ringfile);
            return 0;
        }
    }
    
    /* write to default keyring */
    if (save_to_default_keyring) {
        ringfile = netpgp_getvar(netpgp, "pubring");
        if (!appendkey(io, key, ringfile)) {
            (void) fprintf(io->errs, "Cannot write pubkey to '%s'\n", ringfile);
            return 0;
        }
    }
    
	if (netpgp->pubring != NULL) {
		__ops_keyring_free(netpgp->pubring);
	}
    
    char pass[MAX_PASSPHRASE_LENGTH];
    __ops_forget(pass, (unsigned)sizeof(pass)); //clear pass array
    if (netpgp->passfp) {
        __ops_getpassphrase(netpgp->passfp, pass, sizeof(pass));
    }
    
	/* write secret key */
    if (output_directory) {
        (void) snprintf(ringfile = filename, sizeof(filename), "%s/secring.gpg", dir);
        if ((fd = __ops_setup_file_append(&create, ringfile)) < 0) {
            fd = __ops_setup_file_write(&create, ringfile, 0);
        }
        if (fd < 0) {
            (void) fprintf(io->errs, "can't append secring '%s'\n", ringfile);
            return 0;
        }
        if (!__ops_write_xfer_seckey(create, key, (strlen(pass) > 0) ? (uint8_t *)pass : NULL, strlen(pass), noarmor)) {
            (void) fprintf(io->errs, "Cannot write seckey\n");
            return 0;
        }
        __ops_teardown_file_write(create, fd);
    }
    
    /* write to default keyring */
    if (save_to_default_keyring) {
        ringfile = netpgp_getvar(netpgp, "secring");
        if ((fd = __ops_setup_file_append(&create, ringfile)) < 0) {
            fd = __ops_setup_file_write(&create, ringfile, 0);
        }
        if (fd < 0) {
            (void) fprintf(io->errs, "can't append secring '%s'\n", ringfile);
            return 0;
        }
        if (!__ops_write_xfer_seckey(create, key, (strlen(pass) > 0) ? (uint8_t *)pass : NULL, strlen(pass), noarmor)) {
            (void) fprintf(io->errs, "Cannot write seckey\n");
            return 0;
        }
        __ops_teardown_file_write(create, fd);
    }
	if (netpgp->secring != NULL) {
		__ops_keyring_free(netpgp->secring);
	}
    
    __ops_forget(pass, (unsigned)sizeof(pass));
	__ops_keydata_free(key);
	free(cp);
	return 1;
}

/* generate a new key */
int
netpgp_generate_key(netpgp_t *netpgp, char *id, int numbits)
{
    return netpgp_generate_key_rich(netpgp, id, numbits, NULL, 1);
}

/* encrypt a file */
int
netpgp_encrypt_file(netpgp_t *netpgp,
			const char *userid,
			const char *f,
			char *out,
			int armored)
{
	const __ops_key_t	*key;
	const unsigned		 overwrite = 1;
	const char		*suffix;
	__ops_io_t		*io;
	char			 outname[MAXPATHLEN];

	io = netpgp->io;
	if (f == NULL) {
		(void) fprintf(io->errs,
			"netpgp_encrypt_file: no filename specified\n");
		return 0;
	}
	suffix = (armored) ? ".asc" : ".gpg";
	/* get key with which to sign */
	if ((key = resolve_userid(netpgp, netpgp->pubring, userid)) == NULL) {
		return 0;
	}
	if (out == NULL) {
		(void) snprintf(outname, sizeof(outname), "%s%s", f, suffix);
		out = outname;
	}
	return (int)__ops_encrypt_file(io, f, out, key, (unsigned)armored,
                                   overwrite, netpgp_getvar(netpgp, "cipher"), netpgp_getvar(netpgp, "dont use subkey to encrypt") != NULL ? 1 : 0);
}

#define ARMOR_HEAD	"-----BEGIN PGP MESSAGE-----"

/* decrypt a file */
int
netpgp_decrypt_file(netpgp_t *netpgp, const char *f, char *out, int armored)
{
	const unsigned	 overwrite = 1;
	__ops_io_t	*io;
	unsigned	 realarmor;
	unsigned	 sshkeys;

	__OPS_USED(armored);
	io = netpgp->io;
	if (f == NULL) {
		(void) fprintf(io->errs,
			"netpgp_decrypt_file: no filename specified\n");
		return 0;
	}
	realarmor = isarmoured(io, f, NULL, ARMOR_HEAD);
	sshkeys = (unsigned)(netpgp_getvar(netpgp, "ssh keys") != NULL);
	return __ops_decrypt_file(netpgp->io, f, out, netpgp->secring,
				netpgp->pubring,
				realarmor, overwrite, sshkeys,
				netpgp->passfp, get_passphrase_cb);
}

/* sign a file */
int
netpgp_sign_file(netpgp_t *netpgp,
		const char *userid,
		const char *f,
		char *out,
		int armored,
		int cleartext,
		int detached)
{
	const __ops_key_t	*keypair;
	const __ops_key_t	*pubkey;
	__ops_seckey_t		*seckey;
	const unsigned		 overwrite = 1;
	__ops_io_t		*io;
	const char		*hashalg;
	int			 ret;

	io = netpgp->io;
	if (f == NULL) {
		(void) fprintf(io->errs,
			"netpgp_sign_file: no filename specified\n");
		return 0;
	}
	/* get key with which to sign */
	if ((keypair = resolve_userid(netpgp, netpgp->secring, userid)) == NULL) {
		return 0;
	}
	ret = 1;
	do {
		if (netpgp->passfp == NULL) {
			/* print out the user id */
			pubkey = __ops_getkeybyname(io, netpgp->pubring, userid);
			if (pubkey == NULL) {
				(void) fprintf(io->errs,
					"netpgp: warning - using pubkey from secring\n");
				__ops_print_keydata(io, netpgp->pubring, keypair, "signature ",
					&keypair->key.seckey.pubkey, 0);
			} else {
				__ops_print_keydata(io, netpgp->pubring, pubkey, "signature ",
					&pubkey->key.pubkey, 0);
			}
		}
		if (netpgp_getvar(netpgp, "ssh keys") == NULL) {
			/* now decrypt key */
			seckey = __ops_decrypt_seckey(keypair, netpgp->passfp);
			if (seckey == NULL) {
				(void) fprintf(io->errs, "Bad passphrase\n");
			}
		} else {
			__ops_keyring_t	*secring;

			secring = netpgp->secring;
			seckey = &secring->keys[0].key.seckey;
		}
	} while (seckey == NULL);
	/* sign file */
	hashalg = netpgp_getvar(netpgp, "hash");
	if (seckey->pubkey.alg == OPS_PKA_DSA) {
		hashalg = "sha1";
	}
	if (detached) {
		ret = __ops_sign_detached(io, f, out, seckey, hashalg,
				get_birthtime(netpgp_getvar(netpgp, "birthtime")),
				get_duration(netpgp_getvar(netpgp, "duration")),
				(unsigned)armored,
				overwrite);
	} else {
		ret = __ops_sign_file(io, f, out, seckey, hashalg,
				get_birthtime(netpgp_getvar(netpgp, "birthtime")),
				get_duration(netpgp_getvar(netpgp, "duration")),
				(unsigned)armored, (unsigned)cleartext,
				overwrite);
	}
	__ops_forget(seckey, (unsigned)sizeof(*seckey));
	return ret;
}

#define ARMOR_SIG_HEAD	"-----BEGIN PGP SIGNATURE-----\r\n"

/* verify a file */
int
netpgp_verify_file(netpgp_t *netpgp, const char *in, const char *out, int armored)
{
	__ops_validation_t	 result;
	__ops_io_t		*io;
	unsigned		 realarmor;

	__OPS_USED(armored);
	(void) memset(&result, 0x0, sizeof(result));
	io = netpgp->io;
	if (in == NULL) {
		(void) fprintf(io->errs,
			"netpgp_verify_file: no filename specified\n");
		return 0;
	}
	realarmor = isarmoured(io, in, NULL, ARMOR_SIG_HEAD);
	if (__ops_validate_file(io, &result, in, out, (const int)realarmor, netpgp->pubring)) {
		resultp(io, in, &result, netpgp->pubring);
		return 1;
	}
	if (result.validc + result.invalidc + result.unknownc == 0) {
		(void) fprintf(io->errs,
		"\"%s\": No signatures found - is this a signed file?\n",
			in);
	} else if (result.invalidc == 0 && result.unknownc == 0) {
		(void) fprintf(io->errs,
			"\"%s\": file verification failure: invalid signature time\n", in);
	} else {
		(void) fprintf(io->errs,
"\"%s\": verification failure: %u invalid signatures, %u unknown signatures\n",
			in, result.invalidc, result.unknownc);
	}
	return 0;
}

/* sign some memory */
int
netpgp_sign_memory(netpgp_t *netpgp,
		const char *userid,
		char *mem,
		size_t size,
		char *out,
		size_t outsize,
		const unsigned armored,
		const unsigned cleartext)
{
	const __ops_key_t	*keypair;
	const __ops_key_t	*pubkey;
	__ops_seckey_t		*seckey;
	__ops_memory_t		*signedmem;
	__ops_io_t		*io;
	const char		*hashalg;
	int			 ret;

	io = netpgp->io;
	if (mem == NULL) {
		(void) fprintf(io->errs,
			"netpgp_sign_memory: no memory to sign\n");
		return 0;
	}
	if ((keypair = resolve_userid(netpgp, netpgp->secring, userid)) == NULL) {
		return 0;
	}
	ret = 1;
	do {
		if (netpgp->passfp == NULL) {
			/* print out the user id */
			pubkey = __ops_getkeybyname(io, netpgp->pubring, userid);
			if (pubkey == NULL) {
				(void) fprintf(io->errs,
					"netpgp: warning - using pubkey from secring\n");
				__ops_print_keydata(io, netpgp->pubring, keypair, "signature ",
					&keypair->key.seckey.pubkey, 0);
			} else {
				__ops_print_keydata(io, netpgp->pubring, pubkey, "signature ",
					&pubkey->key.pubkey, 0);
			}
		}
		/* now decrypt key */
		seckey = __ops_decrypt_seckey(keypair, netpgp->passfp);
		if (seckey == NULL) {
			(void) fprintf(io->errs, "Bad passphrase\n");
		}
	} while (seckey == NULL);
	/* sign file */
	(void) memset(out, 0x0, outsize);
	hashalg = netpgp_getvar(netpgp, "hash");
	if (seckey->pubkey.alg == OPS_PKA_DSA) {
		hashalg = "sha1";
	}
	signedmem = __ops_sign_buf(io, mem, size, seckey,
				get_birthtime(netpgp_getvar(netpgp, "birthtime")),
				get_duration(netpgp_getvar(netpgp, "duration")),
				hashalg, armored, cleartext);
	if (signedmem) {
		size_t	m;

		m = MIN(__ops_mem_len(signedmem), outsize);
		(void) memcpy(out, __ops_mem_data(signedmem), m);
		__ops_memory_free(signedmem);
		ret = (int)m;
	} else {
		ret = 0;
	}
	__ops_forget(seckey, (unsigned)sizeof(*seckey));
	return ret;
}

/* verify memory */
int
netpgp_verify_memory(netpgp_t *netpgp, const void *in, const size_t size,
			void *out, size_t outsize, const int armored)
{
	__ops_validation_t	 result;
	__ops_memory_t		*signedmem;
	__ops_memory_t		*cat;
	__ops_io_t		*io;
	size_t			 m;
	int			 ret;

	(void) memset(&result, 0x0, sizeof(result));
	io = netpgp->io;
	if (in == NULL) {
		(void) fprintf(io->errs,
			"netpgp_verify_memory: no memory to verify\n");
		return 0;
	}
	signedmem = __ops_memory_new();
	__ops_memory_add(signedmem, in, size);
	if (out) {
		cat = __ops_memory_new();
	}
	ret = __ops_validate_mem(io, &result, signedmem,
				(out) ? &cat : NULL,
				armored, netpgp->pubring);
    /* signedmem is freed from pgp_validate_mem */
	if (ret) {
		resultp(io, "<stdin>", &result, netpgp->pubring);
		if (out) {
			m = MIN(__ops_mem_len(cat), outsize);
			(void) memcpy(out, __ops_mem_data(cat), m);
			__ops_memory_free(cat);
		} else {
			m = 1;
		}
		return (int)m;
	}
	if (result.validc + result.invalidc + result.unknownc == 0) {
		(void) fprintf(io->errs,
		"No signatures found - is this memory signed?\n");
	} else if (result.invalidc == 0 && result.unknownc == 0) {
		(void) fprintf(io->errs,
			"memory verification failure: invalid signature time\n");
	} else {
		(void) fprintf(io->errs,
"memory verification failure: %u invalid signatures, %u unknown signatures\n",
			result.invalidc, result.unknownc);
	}
	return 0;
}

/* encrypt some memory */
int
netpgp_encrypt_memory(netpgp_t *netpgp,
			const char *userid,
			void *in,
			const size_t insize,
			char *out,
			size_t outsize,
			int armored)
{
	const __ops_key_t	*keypair;
	__ops_memory_t		*enc;
	__ops_io_t		*io;
	size_t			 m;

	io = netpgp->io;
	if (in == NULL) {
		(void) fprintf(io->errs,
			"netpgp_encrypt_buf: no memory to encrypt\n");
		return 0;
	}
	if ((keypair = resolve_userid(netpgp, netpgp->pubring, userid)) == NULL) {
		return 0;
	}
	if (in == out) {
		(void) fprintf(io->errs,
			"netpgp_encrypt_buf: input and output bufs need to be different\n");
		return 0;
	}
	if (outsize < insize) {
		(void) fprintf(io->errs,
			"netpgp_encrypt_buf: input size is larger than output size\n");
		return 0;
	}
	enc = __ops_encrypt_buf(io, in, insize, keypair, (unsigned)armored,
				netpgp_getvar(netpgp, "cipher"), netpgp_getvar(netpgp, "dont use subkey to encrypt") != NULL ? 1 : 0);
	m = MIN(__ops_mem_len(enc), outsize);
	(void) memcpy(out, __ops_mem_data(enc), m);
	__ops_memory_free(enc);
	return (int)m;
}

/* decrypt a chunk of memory */
int
netpgp_decrypt_memory(netpgp_t *netpgp, const void *input, const size_t insize,
			char *out, size_t outsize, const int armored)
{
	__ops_memory_t	*mem;
	__ops_io_t	*io;
	unsigned	 realarmour;
	unsigned	 sshkeys;
	size_t		 m;

	__OPS_USED(armored);
	io = netpgp->io;
	if (input == NULL) {
		(void) fprintf(io->errs,
			"netpgp_decrypt_memory: no memory\n");
		return 0;
	}
	realarmour = isarmoured(io, NULL, input, ARMOR_HEAD);
	sshkeys = (unsigned)(netpgp_getvar(netpgp, "ssh keys") != NULL);
	mem = __ops_decrypt_buf(netpgp->io, input, insize, netpgp->secring,
				netpgp->pubring,
				realarmour, sshkeys,
				netpgp->passfp,
				get_passphrase_cb);
	m = MIN(__ops_mem_len(mem), outsize);
	(void) memcpy(out, __ops_mem_data(mem), m);
	__ops_memory_free(mem);
	return (int)m;
}

/* wrappers for the ops_debug_level functions we added to openpgpsdk */

/* set the debugging level per filename */
int
netpgp_set_debug(const char *f)
{
	return __ops_set_debug_level(f);
}

/* get the debugging level per filename */
int
netpgp_get_debug(const char *f)
{
	return __ops_get_debug_level(f);
}

/* return the version for the library */
const char *
netpgp_get_info(const char *type)
{
	return __ops_get_info(type);
}

/* list all the packets in a file */
int
netpgp_list_packets(netpgp_t *netpgp, char *f, int armor, char *pubringname)
{
	__ops_keyring_t	*keyring;
	const unsigned	 noarmor = 0;
	struct stat	 st;
	__ops_io_t	*io;
	char		 ringname[MAXPATHLEN];
	char		*homedir;
	int		 ret;

	io = netpgp->io;
	if (f == NULL) {
		(void) fprintf(io->errs, "No file containing packets\n");
		return 0;
	}
	if (stat(f, &st) < 0) {
		(void) fprintf(io->errs, "No such file '%s'\n", f);
		return 0;
	}
	homedir = netpgp_getvar(netpgp, "homedir");
	if (pubringname == NULL) {
		(void) snprintf(ringname, sizeof(ringname),
				"%s/pubring.gpg", homedir);
		pubringname = ringname;
	}
	if ((keyring = calloc(1, sizeof(*keyring))) == NULL) {
		(void) fprintf(io->errs, "netpgp_list_packets: bad alloc\n");
		return 0;
	}
	if (!__ops_keyring_fileread(keyring, noarmor, pubringname)) {
		free(keyring);
		(void) fprintf(io->errs, "Cannot read pub keyring %s\n",
			pubringname);
		return 0;
	}
	netpgp->pubring = keyring;
	netpgp_setvar(netpgp, "pubring", pubringname);
	ret = __ops_list_packets(io, f, (unsigned)armor,
					netpgp->secring,
					netpgp->pubring,
					netpgp->passfp,
					get_passphrase_cb);
	free(keyring);
	return ret;
}

/* set a variable */
int
netpgp_setvar(netpgp_t *netpgp, const char *name, const char *value)
{
	char	*newval;
	int	 i;

	/* protect against the case where 'value' is netpgp->value[i] */
	newval = netpgp_strdup(value);
	if ((i = findvar(netpgp, name)) < 0) {
		/* add the element to the array */
		if (size_arrays(netpgp, netpgp->size + 15)) {
			netpgp->name[i = netpgp->c++] = netpgp_strdup(name);
		}
	} else {
		/* replace the element in the array */
		if (netpgp->value[i]) {
			free(netpgp->value[i]);
			netpgp->value[i] = NULL;
		}
	}
	/* sanity checks for range of values */
	if (strcmp(name, "hash") == 0 || strcmp(name, "algorithm") == 0) {
		if (__ops_str_to_hash_alg(newval) == OPS_HASH_UNKNOWN) {
			free(newval);
			return 0;
		}
	}
	netpgp->value[i] = newval;
	return 1;
}

/* unset a variable */
int
netpgp_unsetvar(netpgp_t *netpgp, const char *name)
{
	int	i;

	if ((i = findvar(netpgp, name)) >= 0) {
		if (netpgp->value[i]) {
			free(netpgp->value[i]);
			netpgp->value[i] = NULL;
		}
		netpgp->value[i] = NULL;
		return 1;
	}
	return 0;
}

/* get a variable's value (NULL if not set) */
char *
netpgp_getvar(netpgp_t *netpgp, const char *name)
{
	int	i;

	return ((i = findvar(netpgp, name)) < 0) ? NULL : netpgp->value[i];
}

/* increment a value */
int
netpgp_incvar(netpgp_t *netpgp, const char *name, const int delta)
{
	char	*cp;
	char	 num[16];
	int	 val;

	val = 0;
	if ((cp = netpgp_getvar(netpgp, name)) != NULL) {
		val = atoi(cp);
	}
	(void) snprintf(num, sizeof(num), "%d", val + delta);
	netpgp_setvar(netpgp, name, num);
	return 1;
}

/* set the home directory value to "home/subdir" */
int
netpgp_set_homedir(netpgp_t *netpgp, char *home, const char *subdir, const int quiet)
{
	struct stat	st;
	char		d[MAXPATHLEN];

	if (home == NULL) {
		if (!quiet) {
			(void) fprintf(stderr, "NULL HOME directory\n");
		}
		return 0;
	}
	(void) snprintf(d, sizeof(d), "%s%s", home, (subdir) ? subdir : "");
	if (stat(d, &st) == 0) {
		if ((st.st_mode & S_IFMT) == S_IFDIR) {
			netpgp_setvar(netpgp, "homedir", d);
			return 1;
		}
		(void) fprintf(stderr, "netpgp: homedir \"%s\" is not a dir\n",
					d);
		return 0;
	}
	if (!quiet) {
		(void) fprintf(stderr,
			"netpgp: warning homedir \"%s\" not found\n", d);
	}
	netpgp_setvar(netpgp, "homedir", d);
	return 1;
}

/* validate all sigs in the pub keyring */
int
netpgp_validate_sigs(netpgp_t *netpgp)
{
	__ops_validation_t	result;

	return (int)__ops_validate_all_sigs(&result, netpgp->pubring, NULL);
}

/* print the json out on 'fp' */
int
netpgp_format_json(void *vp, const char *json, const int psigs)
{
	mj_t	 ids;
	FILE	*fp;
	int	 from;
	int	 idc;
	int	 tok;
	int	 to;
	int	 i;

	if ((fp = (FILE *)vp) == NULL || json == NULL) {
		return 0;
	}
	/* ids is an array of strings, each containing 1 entry */
	(void) memset(&ids, 0x0, sizeof(ids));
	from = to = tok = 0;
	/* convert from string into an mj structure */
	(void) mj_parse(&ids, json, &from, &to, &tok);
	if ((idc = mj_arraycount(&ids)) == 1 && strchr(json, '{') == NULL) {
		idc = 0;
	}
	(void) fprintf(fp, "%d key%s found\n", idc, (idc == 1) ? "" : "s");
	for (i = 0 ; i < idc ; i++) {
		format_json_key(fp, &ids.value.v[i], psigs);
	}
	/* clean up */
	mj_delete(&ids);
	return idc;
}

/* find a key in keyring, and write it in ssh format */
int
netpgp_write_sshkey(netpgp_t *netpgp, char *s, const char *userid, char *out, size_t size)
{
	const __ops_key_t	*key;
	__ops_keyring_t		*keyring;
	__ops_io_t		*io;
	unsigned		 k;
	size_t			 cc;
	char			 f[MAXPATHLEN];

	if ((io = calloc(1, sizeof(__ops_io_t))) == NULL) {
		(void) fprintf(stderr, "netpgp_save_sshpub: bad alloc 1\n");
		return 0;
	}
	io->outs = stdout;
	io->errs = stderr;
	io->res = stderr;
	netpgp->io = io;
	/* write new to temp file */
	savepubkey(s, f, sizeof(f));
	if ((keyring = calloc(1, sizeof(*keyring))) == NULL) {
		(void) fprintf(stderr, "netpgp_save_sshpub: bad alloc 2\n");
		return 0;
	}
	if (!__ops_keyring_fileread(netpgp->pubring = keyring, 1, f)) {
		(void) fprintf(stderr, "can't import key\n");
		return 0;
	}
	/* get rsa key */
	k = 0;
	key = __ops_getnextkeybyname(netpgp->io, netpgp->pubring, userid, &k);
	if (key == NULL) {
		(void) fprintf(stderr, "no key found for '%s'\n", userid);
		return 0;
	}
	if (key->key.pubkey.alg != OPS_PKA_RSA) {
		/* we're not interested in supporting DSA either :-) */
		(void) fprintf(stderr, "key not RSA '%s'\n", userid);
		return 0;
	}
	/* XXX - check trust sigs */
	/* XXX - check expiry */
	/* XXX - check start */
	/* XXX - check not weak key */
	/* get rsa e and n */
	(void) memset(out, 0x0, size);
	cc = formatstring((char *)out, (const uint8_t *)"ssh-rsa", 7);
	cc += formatbignum((char *)&out[cc], key->key.pubkey.key.rsa.e);
	cc += formatbignum((char *)&out[cc], key->key.pubkey.key.rsa.n);
	free(io);
	free(keyring);
	return (int)MIN(cc,INT_MAX);
}
