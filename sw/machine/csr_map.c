#include "config.h"
#include "m.h"

const struct csr_map_entry m_csr_map[] =
{
#if M_DEBUG_CSR
	#define DECLARE_CSR(_name, _csr) \
		{ .name = #_name, .csr = _csr },

	#include "encoding.h"
	#undef DECLARE_CSR
#endif

	{ }
};
