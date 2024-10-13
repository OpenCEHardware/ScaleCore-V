#ifndef HOSTED_SIMULATION_HPP
#define HOSTED_SIMULATION_HPP

#include <atomic>
#include <cstdint>
#include <cstdlib>
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

		inline virtual bool read_byte(unsigned address, unsigned char &data)
		{
			unsigned word;
			if (!this->read(address & ~0b11, word))
				return false;

			data = (word >> (8 * (address & 0b11))) & 0xff;
			return true;
		}

		inline virtual bool read(unsigned address, unsigned &data)
		{
			address -= this->base;

			if (address >= this->len + sizeof data)
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

		inline simulation &get_sim() noexcept
		{
			return this->sim;
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

		int run();

		inline void timeout() noexcept
		{
			this->timed_out_ = true;
			this->halt(EXIT_FAILURE);
		}

		inline void halt(int code) noexcept
		{
			this->exit_code_ = code;
			this->halt_.store(true, std::memory_order_release);
		}

		inline void set_trace_path(std::string trace_path) noexcept
		{
#if VM_TRACE
			this->trace_path = trace_path;
#endif
		}

		memory_mapped *resolve_address(unsigned address);

		std::uint64_t cycles() const noexcept
		{
			return this->time_ / 2;
		}

	private:
		struct mapping
		{
			unsigned       start;
			unsigned       end;
			memory_mapped* agent;
		};

		std::unique_ptr<Vtop> top;
		std::uint64_t         time_ = 0;
		axi_queue             imem_r_queue;
		axi_queue             dmem_r_queue;
		axi_queue             dmem_w_queue;
		std::vector<mapping>  mappings;
		std::atomic_bool      halt_ = false;
		int                   exit_code_;
		bool                  timed_out_ = false;

#if VM_TRACE
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

		inline bool halting() noexcept
		{
			return this->halt_.load(std::memory_order_acquire);
		}
};

#endif
