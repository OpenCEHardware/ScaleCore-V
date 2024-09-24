#include <memory>

#include "Vtop.h"

#include "simulation.hpp"

namespace
{
	constexpr std::size_t AXI_MAX_PENDING = 3;
}

memory_mapped::memory_mapped(simulation &sim, unsigned base, unsigned len)
: sim{sim}, base{base}, len{len}
{
	unsigned start = base;
	unsigned end = base + len - 1;

	auto &mappings = sim.mappings;

	bool retry;
	do {
		retry = false;

		auto it = mappings.begin();
		while (it != mappings.end()) {
			if (end >= it->start && start <= it->end) {
				unsigned keep_lo = std::min(it->end + 1, std::max(it->start, start)) - it->start;
				unsigned keep_hi = it->end + 1 - std::max(it->start, std::min(it->end + 1, end + 1));

				if (keep_lo != 0 && keep_hi != 0) {
					simulation::mapping hi_half{it->end - keep_hi + 1, it->end, it->agent};

					it->end = it->start + keep_lo - 1;
					mappings.insert(++it, hi_half);

					retry = true;
					break;
				} else if (keep_lo != 0) {
					it->end = it->start + keep_lo - 1;
				} else if (keep_hi != 0) {
					it->start = it->end - keep_hi + 1;
				} else {
					mappings.erase(it);

					retry = true;
					break;
				}
			}

			++it;
		}
	} while (retry);

	auto it = mappings.begin();
	while (it != mappings.end()) {
		if (base < it->start)
			break;

		++it;
	}

	mappings.insert(it, simulation::mapping{base, end, this});
}

memory_mapped::memory_mapped(memory_mapped &&other)
: sim{other.sim}, base{other.base}, len{other.len}
{
	auto &mappings = this->sim.mappings;
	for (auto it = mappings.begin(); it != mappings.end(); ++it)
		if (it->agent == &other)
			it->agent = this;
}

memory_mapped::~memory_mapped()
{
	auto &mappings = this->sim.mappings;
	for (auto it = mappings.begin(); it != mappings.end(); ++it)
		if (it->agent == this) {
			mappings.erase(it);
			break;
		}
}

bool memory_mapped::write_relative_strobe(unsigned address, unsigned data, unsigned strobe)
{
	unsigned current;
	if (!this->read_relative(address, current))
		return false;

	unsigned mask = 0;

	if (strobe & 0b0001)
		mask |= 0x000000ff;

	if (strobe & 0b0010)
		mask |= 0x0000ff00;

	if (strobe & 0b0100)
		mask |= 0x00ff0000;

	if (strobe & 0b1000)
		mask |= 0xff000000;

	return this->write_relative(address, (data & mask) | (current & ~mask));
}

int simulation::run()
{
	this->exit_code_ = 0;

	if (!this->top) {
		this->top = std::make_unique<Vtop>();
		auto &top = *this->top;

#if VM_TRACE
		if (!this->trace_path.empty()) {
#if VM_TRACE_FST
			this->trace = std::make_unique<VerilatedFstC>();
#else
			this->trace = std::make_unique<VerilatedVcdC>();
#endif

			Verilated::traceEverOn(true);
			top.trace(&*this->trace, 0);
			this->trace->open(this->trace_path.c_str());

			this->trace_path.clear();
		}
#endif

		top.imem_rvalid = 0;
		top.imem_arready = 0;

		top.dmem_bvalid = 0;
		top.dmem_rvalid = 0;
		top.dmem_wready = 0;
		top.dmem_arready = 0;
		top.dmem_awready = 0;

		top.clk = 0;
		top.rst_n = 0;

		this->run_cycles(2);

		top.rst_n = 1;
		this->top->eval();
	}

	constexpr unsigned HOT_LOOP_CYCLES = 8;

	do {
		do
			this->run_cycles(HOT_LOOP_CYCLES);
		while (!this->has_pending_io() && !this->halt_);

		bool io_idle;
		do {
			do
				this->io_cycle();
			while (this->has_pending_io() && !this->halt_);

			if (this->halt_)
				break;

			io_idle = true;
			for (unsigned i = 0; i < HOT_LOOP_CYCLES; ++i) {
				this->run_cycles(1);

				if (this->has_pending_io()) {
					io_idle = false;
					break;
				}
			}
		} while (!io_idle);
	} while (!this->halt_);

	int exit_code = this->exit_code_;
	this->io_cycle();

	this->halt_ = false;
	this->exit_code_ = 0;

	return exit_code;
}

bool simulation::has_pending_io()
{
	auto &top = *this->top;

	return top.imem_arready
	    || top.imem_arvalid
	    || top.imem_rvalid
	    || top.dmem_bvalid
	    || top.dmem_rvalid
	    || top.dmem_wready
	    || top.dmem_wvalid
	    || top.dmem_arready
	    || top.dmem_arvalid
	    || top.dmem_arready
	    || top.dmem_awvalid;
}

void simulation::io_cycle()
{
	auto &top = *this->top;

	this->imem_r_queue.read_tx(
		top.imem_rready,
		top.imem_rvalid,
		top.imem_rid,
		top.imem_rdata,
		top.imem_rresp,
		top.imem_rlast
	);

	this->dmem_r_queue.read_tx(
		top.dmem_rready,
		top.dmem_rvalid,
		top.dmem_rid,
		top.dmem_rdata,
		top.dmem_rresp,
		top.dmem_rlast
	);

	this->dmem_w_queue.write_tx(
		top.dmem_bready,
		top.dmem_bvalid,
		top.dmem_bid,
		top.dmem_bresp
	);

	this->imem_r_queue.read_begin(top.imem_arready, top.imem_arvalid);
	this->dmem_r_queue.read_begin(top.dmem_arready, top.dmem_arvalid);
	this->dmem_w_queue.write_begin(top.dmem_awready, top.dmem_awvalid, top.dmem_wready, top.dmem_wvalid);

	top.eval();

	this->imem_r_queue.addr_rx(
		top.imem_arready,
		top.imem_arvalid,
		top.imem_arid,
		top.imem_arlen,
		top.imem_arsize,
		top.imem_arburst,
		top.imem_araddr
	);

	this->dmem_r_queue.addr_rx(
		top.dmem_arready,
		top.dmem_arvalid,
		top.dmem_arid,
		top.dmem_arlen,
		top.dmem_arsize,
		top.dmem_arburst,
		top.dmem_araddr
	);

	this->dmem_w_queue.addr_rx(
		top.dmem_awready,
		top.dmem_awvalid,
		top.dmem_awid,
		top.dmem_awlen,
		top.dmem_awsize,
		top.dmem_awburst,
		top.dmem_awaddr
	);

	bool write_rx_ok = this->dmem_w_queue.write_rx(
		top.dmem_wready,
		top.dmem_wvalid,
		top.dmem_wdata,
		top.dmem_wlast,
		top.dmem_wstrb
	);

	this->imem_r_queue.read_end(top.imem_rready, top.imem_rvalid);
	this->dmem_r_queue.read_end(top.dmem_rready, top.dmem_rvalid);
	this->dmem_w_queue.write_end(top.dmem_bready, top.dmem_bvalid);

	auto callback = [this](unsigned address)
	{
		return this->resolve_address(address);
	};

	this->imem_r_queue.do_reads(callback);
	this->dmem_r_queue.do_reads(callback);
	this->dmem_w_queue.do_writes(callback);

	if (!write_rx_ok) [[unlikely]]
		top.eval();

	this->run_cycles(1);
}

void simulation::run_cycles(unsigned cycles)
{
	auto &top = *this->top;
	for (unsigned i = 0; i < cycles; ++i) {
#if VM_TRACE
		if (this->trace)
			trace->dump(this->time++);
#endif

		top.clk = 0;
		top.eval();

#if VM_TRACE
		if (this->trace)
			trace->dump(this->time++);
#endif

		top.clk = 1;
		top.eval();
	}
}

memory_mapped *simulation::resolve_address(unsigned address)
{
	for (auto &mapping : this->mappings)
	{
		if (address < mapping.start)
			return nullptr;
		else if (mapping.end >= address)
			return mapping.agent;
	}

	return nullptr;
}
