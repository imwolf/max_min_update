#ifndef QUERY_H
#define QUERY_H

typedef nx_struct query_msg_t{
	nx_uint16_t sender_id;
	nx_uint16_t type;
	nx_uint16_t value;
} query_msg_t;

enum {
	AM_QUERY_MSG = 7,
	QUERY_TYPE = 0,
	RESPONSE_TYPE = 1,
};

enum {
	INVALID = 0,
	MAX_CHILDREN_SIZE = 16,
};

#endif
