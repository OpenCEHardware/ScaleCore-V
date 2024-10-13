#include "config.h"
#include "m.h"

const struct insn_map_entry m_insn_map[] =
{
#if M_DEBUG_INSN
	#define DECLARE_INSN(_mnemonic, _match, _mask) \
		{ .mnemonic = #_mnemonic, .match = _match, .mask = _mask },

	#include "encoding.h"
	#undef DECLARE_INSN
#endif

	{ }
};
