#ifndef HOSTED_AXI_HPP
#define HOSTED_AXI_HPP

#include <queue>

struct axi_beat
{
	unsigned data;

	union
	{
		bool     read_error;
		unsigned strobe;
	};
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

	auto &back = this->queue.back();
	if (back.completed)
		return;

	auto *agent = callback(back.address);
	if (!agent) {
		back.error = true;
		back.write_index = 1;
		back.expected_len = 1;
		back.beats[0].data = 0xffffffff;
	}

	while (back.write_index < back.expected_len)
		if (back.write_index == axi_transaction::MAX_BURST)
			back.error = true;
		else {
			auto &beat = back.beats[back.write_index];
			beat.read_error = !agent->read(back.address, beat.data);

			back.address += 4;
			back.write_index++;
		}

	back.completed = true;
}

template<typename F>
void axi_queue::do_writes(F callback)
{
	if (this->queue.empty())
		return;

	auto &back = this->queue.back();
	if (!back.completed || back.read_index == back.write_index)
		return;

	auto *agent = callback(back.address);
	if (!agent) {
		back.error = true;
		back.read_index = 0;
		back.write_index = 0;
	}

	while (back.read_index < back.write_index) {
		auto &beat = back.beats[back.read_index];
		if (!agent->write(back.address, beat.data, beat.strobe))
			back.error = true;

		back.address += 4;
		back.read_index++;
	}
}

#endif
