#include <cinttypes>
#include <cstdint>
#include <cstdio>

#include <unistd.h>

#include "magic_io.hpp"

namespace
{
	enum htif_addr : unsigned
	{
		HTIF_TOHOST_LO   = 0,
		HTIF_TOHOST_HI   = 1,
		HTIF_FROMHOST_LO = 2,
		HTIF_FROMHOST_HI = 3,
	};

	enum htif_syscall : unsigned
	{
		HTIF_SYSCALL_WRITE = 64,
	};
}

bool magic_io_agent::write_relative(unsigned address, unsigned data)
{
	if (address != HTIF_TOHOST_LO)
		return true;
	else if (data & 1) {
		this->get_sim().halt(static_cast<int>(data >> 1));
		return true;
	}

	unsigned buffer_base = data;

	auto *agent = this->get_sim().resolve_address(buffer_base);
	if (!agent) {
		std::fprintf(stderr, "[magic] unmapped buffer address: 0x%08x\n", data);
		return false;
	}

	std::uint64_t magic_args[8] = { };
	for (unsigned i = 0; i < sizeof magic_args / sizeof(unsigned); ++i) {
		unsigned word;
		unsigned address = buffer_base + i * sizeof(unsigned);

		if (!agent->read(address, word)) {
			std::fprintf(stderr, "[magic] bad buffer read: 0x%08x\n", address);
			return false;
		}

		auto arg_index = i / (sizeof magic_args[0] / sizeof word);
		magic_args[arg_index] = magic_args[arg_index] >> 32 | static_cast<std::uint64_t>(word) << 32;
	}

	auto syscall_no = static_cast<unsigned>(magic_args[0]);
	switch (syscall_no) {
		case HTIF_SYSCALL_WRITE: {
			unsigned write_address = static_cast<unsigned>(magic_args[2]);

			auto *agent = this->get_sim().resolve_address(write_address);
			if (!agent) {
				std::fprintf(stderr, "[magic] unmapped write() address: 0x%08x\n", write_address);
				return false;
			}

			while (magic_args[3]--) {
				unsigned char read_byte;
				if (!agent->read_byte(write_address, read_byte)) {
					std::fprintf(stderr, "[magic] write() buffer error at 0x%08x\n", write_address);
					return false;
				}

				std::putchar(read_byte);
				std::fflush(stdout);
				write_address++;
			}

			break;
		}

		default:
			std::fprintf(stderr, "[magic] unknown syscall number %u\n", syscall_no);
			return false;
	}

	return true;
}
