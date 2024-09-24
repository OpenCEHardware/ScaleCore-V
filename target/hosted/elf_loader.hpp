#ifndef HOSTED_ELF_LOADER_HPP
#define HOSTED_ELF_LOADER_HPP

#include <optional>
#include <vector>

#include "memory_region.hpp"
#include "simulation.hpp"

class elf_loader
{
	public:
		elf_loader(simulation &sim, const char *path);

		~elf_loader();

		inline unsigned entrypoint() const noexcept
		{
			return this->entrypoint_;
		}

		inline int error() const noexcept
		{
			return this->error_;
		}

		inline std::optional<unsigned> magic_io_base() const noexcept
		{
			return this->magic_io_base_;
		}

	private:
		struct mapping
		{
			void       *base;
			std::size_t length;
		};

		std::vector<memory_region> segments;
		std::vector<mapping>       mappings;
		unsigned                   entrypoint_;
		int                        error_;
		std::optional<unsigned>    magic_io_base_;
};

#endif
