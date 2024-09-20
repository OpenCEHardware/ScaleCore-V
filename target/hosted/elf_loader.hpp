#ifndef HOSTED_ELF_LOADER_HPP
#define HOSTED_ELF_LOADER_HPP

#include <vector>

#include "memory_region.hpp"
#include "simulation.hpp"

class elf_loader
{
	public:
		elf_loader(simulation &sim, const char *path);

		~elf_loader();

		inline int get_errno() const noexcept
		{
			return this->error;
		}

	private:
		struct mapping
		{
			void       *base;
			std::size_t length;
		};

		std::vector<memory_region> segments;
		std::vector<mapping>       mappings;
		int                        error = 0;
};

#endif
