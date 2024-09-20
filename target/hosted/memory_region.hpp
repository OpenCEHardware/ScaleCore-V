#ifndef HOSTED_MEMORY_REGION_HPP
#define HOSTED_MEMORY_REGION_HPP

#include "simulation.hpp"

class memory_region : public memory_mapped
{
	public:
		inline memory_region(simulation &sim, unsigned base, void *mem, unsigned len)
		: memory_mapped{sim, base, len}, mem{mem}
		{}

		inline memory_region(simulation &sim, unsigned base, const void *mem, unsigned len)
		: memory_region{sim, base, const_cast<void *>(mem), len}
		{
			this->read_only = true;
		}

		inline void set_read_only() noexcept
		{
			this->read_only = true;
		}

		inline virtual bool read_relative(unsigned address, unsigned &data)
		{
			data = *reinterpret_cast<const unsigned *>(static_cast<const char *>(this->mem) + address);
			return true;
		}

		inline virtual bool write_relative(unsigned address, unsigned data)
		{
			if (this->read_only)
				return false;

			*reinterpret_cast<unsigned *>(static_cast<char *>(this->mem) + address) = data;
			return true;
		}

	private:
		void *mem;
		bool  read_only = false;
};

#endif
