#ifndef HOSTED_AXI_HPP
#define HOSTED_AXI_HPP

#include <queue>

struct axi_beat
{
	unsigned data;
	unsigned strobe;
};

struct axi_transaction
{
	static constexpr std::size_t MAX_BURST = 8;

	unsigned address;
	unsigned read_index;
	unsigned write_index;
	unsigned expected_len;
	unsigned channel_id;
	bool     error;
	bool     completed;
	bool     pending;
	axi_beat beats[MAX_BURST];
};

class axi_queue
{
	public:
		axi_queue() = default;

		void read_begin(unsigned char &arready, unsigned char arvalid);
		void read_end(unsigned char rready, unsigned char rvalid);

		void write_begin(unsigned char &awready, unsigned char awvalid, unsigned char &wready, unsigned char wvalid);
		void write_end(unsigned char bready, unsigned char bvalid);

		void addr_rx(
			unsigned char axready,
			unsigned char axvalid,
			unsigned char axid,
			unsigned char axlen,
			unsigned char axsize,
			unsigned char axburst,
			unsigned      axaddr
		);

		bool write_rx(
			unsigned char &wready,
			unsigned char  wvalid,
			unsigned       wdata,
			unsigned char  wlast,
			unsigned char  wstrb
		);

		void read_tx(
			unsigned char  rready,
			unsigned char &rvalid,
			unsigned char &rid,
			unsigned      &rdata,
			unsigned char &rresp,
			unsigned char &rlast
		);

		void write_tx(
			unsigned char  bready,
			unsigned char &bvalid,
			unsigned char &bid,
			unsigned char &bresp
		);

		template<typename F>
		void do_reads(F callback);

		template<typename F>
		void do_writes(F callback);

	private:
		std::queue<axi_transaction> queue;
};

template<typename F>
void axi_queue::do_reads(F callback)
{
	if (this->queue.empty())
		return;

	auto &front = this->queue.front();
	if (front.completed)
		return;

	auto *agent = callback(front.address);
	if (!agent) {
		front.error = true;
		front.write_index = 1;
		front.beats[0].data = 0xffffffff;
	}

	while (!front.error && front.write_index < front.expected_len)
		if (front.write_index == axi_transaction::MAX_BURST)
			front.error = true;
		else {
			auto &beat = front.beats[front.write_index];
			if (!agent->read(front.address, beat.data))
				front.error = true;

			front.address += 4;
			front.write_index++;
		}

	front.completed = true;
}

template<typename F>
void axi_queue::do_writes(F callback)
{
	if (this->queue.empty())
		return;

	auto &front = this->queue.front();
	if (!front.completed || front.read_index == front.write_index)
		return;

	auto *agent = callback(front.address);
	if (!agent) {
		front.error = true;
		front.read_index = 0;
		front.write_index = 0;
	}

	while (!front.error && front.read_index < front.write_index) {
		auto &beat = front.beats[front.read_index];
		if (!agent->write(front.address, beat.data, beat.strobe))
			front.error = true;

		front.address += 4;
		front.read_index++;
	}
}

#endif
