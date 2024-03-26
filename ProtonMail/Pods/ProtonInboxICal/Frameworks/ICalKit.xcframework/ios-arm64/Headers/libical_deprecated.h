#ifndef LIBICAL_DEPRECATED_H
#define LIBICAL_DEPRECATED_H

/* Deprecated function macro */
#if defined(NO_DEPRECATION_WARNINGS)
#define LIBICAL_DEPRECATED(x) x
#else
#if !defined(LIBICAL_DEPRECATED)
#ifdef __GNUC__
#define LIBICAL_DEPRECATED(x) x __attribute__((deprecated))
#elif defined(_MSC_VER)
#define LIBICAL_DEPRECATED(x) __declspec(deprecated) x
#else
#define LIBICAL_DEPRECATED(x) x
#endif
#endif
#endif

#endif
