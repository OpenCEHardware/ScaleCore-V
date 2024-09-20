#ifndef HOSTED_SIMULATION_HPP
#define HOSTED_SIMULATION_HPP

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#if VM_TRACE
#if VM_TRACE_FST
#include <verilated_fst_c.h>
#else
#include <verilated_vdc_c.h>
#endif
#endif

#include "Vtop.h"

#include "axi.hpp"

class simulation;

class memory_mapped
{
	public:
		memory_mapped(simulation &sim, unsigned base, unsigned len);

		memory_mapped(const memory_mapped &other) = delete;
		memory_mapped(memory_mapped &&other);

		virtual ~memory_mapped();

		inline virtual bool read(unsigned address, unsigned &data)
		{
			address -= this->base;

			if (address + sizeof data > this->len)
				return false;

			return this->read_relative(address, data);
		}

		inline virtual bool write(unsigned address, unsigned data, unsigned strobe)
		{
			address -= this->base;

			if (address + sizeof data > this->len)
				return false;

			if (strobe == 0b1111)
				return this->write_relative(address, data);

			return this->write_relative_strobe(address, data, strobe);
		}

		inline unsigned get_base() const noexcept
		{
			return this->base;
		}

		inline unsigned get_len() const noexcept
		{
			return this->len;
		}

		virtual bool read_relative(unsigned address, unsigned &data) = 0;
		virtual bool write_relative(unsigned address, unsigned data) = 0;

	private:
		unsigned    base;
		unsigned    len;
		simulation& sim;

		bool write_relative_strobe(unsigned address, unsigned data, unsigned strobe);
};

class simulation
{
	friend class memory_mapped;

	public:
		simulation() = default;

		void run();

		inline void stop() noexcept
		{
			this->halt = true;
		}

		inline void set_trace_path(std::string trace_path) noexcept
		{
#if VM_TRACE
			this->trace_path = trace_path;
#endif
		}

	private:
		struct mapping
		{
			unsigned       start;
			unsigned       end;
			memory_mapped* agent;
		};

		std::unique_ptr<Vtop> top;
		axi_queue             imem_r_queue;
		axi_queue             dmem_r_queue;
		axi_queue             dmem_w_queue;
		std::vector<mapping>  mappings;
		bool                  halt = false;

#if VM_TRACE
		std::uint64_t                  time = 0;
#if VM_TRACE_FST
		std::unique_ptr<VerilatedFstC> trace;
#else
		std::unique_ptr<VerilatedVcdC> trace;
#endif
		std::string                    trace_path;
#endif

		void io_cycle();
		bool has_pending_io();

		void run_cycles(unsigned cycles);

		memory_mapped *resolve_address(unsigned address);
};

#endif
