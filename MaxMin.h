#ifndef MAX_MIN_H
#define MAX_MIN_H

typedef nx_struct max_min_msg{
	nx_uint16_t value;
} max_min_msg_t;

enum {
	AM_MAX_MIN_MSG = 7,
};

#endif
