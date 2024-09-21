#include "axi.hpp"
#include "simulation.hpp"

namespace
{
	constexpr unsigned char AXI_RESP_OK     = 0b00;
	constexpr unsigned char AXI_RESP_ERR    = 0b10;
	constexpr std::size_t   AXI_MAX_PENDING = 3;
}

void axi_queue::read_tx(
	unsigned char  rready,
	unsigned char &rvalid,
	unsigned char &rid,
	unsigned      &rdata,
	unsigned char &rresp,
	unsigned char &rlast
)
{
	if (rvalid) {
		auto &front = this->queue.front();

		if (front.pending)
			return;
		else if (front.read_index == front.write_index)
			this->queue.pop();
	}

	rvalid = 0;
	if (this->queue.empty())
		return;

	auto &front = this->queue.front();
	if (front.completed) {
		rid = front.channel_id;
		rdata = front.beats[front.read_index].data;
		rresp = front.error ? AXI_RESP_ERR : AXI_RESP_OK;
		rlast = front.read_index + 1 == front.write_index;
		rvalid = 1;
	}
}

void axi_queue::write_tx(
    unsigned char  bready,
    unsigned char &bvalid,
    unsigned char &bid,
    unsigned char &bresp
)
{
	if (bvalid) {
		if (this->queue.front().pending)
			return;

		this->queue.pop();
	}

	bvalid = 0;
	if (this->queue.empty())
		return;

	auto &front = this->queue.front();
	if (front.read_index == front.write_index) {
		bid = front.channel_id;
		bresp = front.error ? AXI_RESP_ERR : AXI_RESP_OK;
		bvalid = 1;
	}
}

void axi_queue::read_begin(unsigned char &arready, unsigned char arvalid)
{
	arready = 0;
	if (arvalid && this->queue.size() < AXI_MAX_PENDING)
		arready = 1;
}

void axi_queue::write_begin(unsigned char &awready, unsigned char awvalid, unsigned char &wready, unsigned char wvalid)
{
	if (this->queue.empty() || this->queue.back().completed) {
		wready = awready && wvalid;
		awready = awvalid && this->queue.size() < AXI_MAX_PENDING;
	} else {
		wready = wvalid;
		awready = 0;
	}
}

void axi_queue::addr_rx(
	unsigned char axready,
	unsigned char axvalid,
	unsigned char axid,
	unsigned char axlen,
	unsigned char axsize,
	unsigned char axburst,
	unsigned      axaddr
)
{
	if (!axready || !axvalid)
		return;

	this->queue.emplace();
	auto &back = this->queue.back();

	back.error = false;
	back.address = axaddr;
	back.pending = false;
	back.completed = false;
	back.channel_id = axid;
	back.expected_len = axlen + 1;

	if (axsize != 0b010 || axburst != 0b01 || (axaddr & 0b11) != 0)
		back.error = true;
}

bool axi_queue::write_rx(
	unsigned char &wready,
	unsigned char  wvalid,
	unsigned       wdata,
	unsigned char  wlast,
	unsigned char  wstrb
)
{
	if (!wready)
		return true;

	if (!wvalid) {
		if (this->queue.empty() || this->queue.back().completed) [[unlikely]] {
			wready = 0;
			return false;
		}

		return true;
	}

	auto &back = this->queue.back();

	if (back.write_index < axi_transaction::MAX_BURST) {
		auto &entry = back.beats[back.write_index++];
		entry.data = wdata;
		entry.strobe = wstrb;
	} else
		back.error = true;

	back.completed = static_cast<bool>(wlast);
	if (back.completed && !back.error)
		back.error = back.write_index != back.expected_len;

	return true;
}

void axi_queue::read_end(unsigned char rready, unsigned char rvalid)
{
	if (rvalid) {
		auto &front = this->queue.front();

		front.pending = !rready;
		if (rready)
			front.read_index++;
	}
}

void axi_queue::write_end(unsigned char bready, unsigned char bvalid)
{
	if (bvalid)
		queue.front().pending = !bready;
}
