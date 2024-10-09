#include "m.h"

const struct exc_map_entry m_exc_map[] =
{
	#define DECLARE_CAUSE(_description, _code) \
		{ .description = _description, .code = _code },

	#include "encoding.h"
	#undef DECLARE_CAUSE

	{ }
};
