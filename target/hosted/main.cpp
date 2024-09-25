#include <atomic>
#include <csignal>
#include <cstdio>
#include <cstring>
#include <filesystem>
#include <memory>
#include <utility>

#include <unistd.h>

#include "args.hxx"
#include "elf_loader.hpp"
#include "magic_io.hpp"
#include "simulation.hpp"

namespace
{
	constexpr unsigned HSV_CORE_RESET_PC = 0x0;

	std::atomic<simulation *> alarm_sim = nullptr;

	void simulation_timeout(int)
	{
		auto *sim = alarm_sim.exchange(nullptr);
		if (sim)
			sim->timeout();
	}
}

int main(int argc, char **argv)
{
	Verilated::commandArgs(argc, argv);

	for (char **arg = argv; *arg; ++arg) {
		if (**arg == '+') {
			*arg = NULL;
			argc = arg - argv;
			break;
		}
	}

	args::ArgumentParser parser("Hosted hscale-v simulator");

	args::ValueFlag<std::string> trace_out
	(
		parser, "path", "trace output file", {"trace"}
	);

	args::ValueFlag<unsigned> timeout
	(
		parser, "secs", "fail the simulation if it won't halt within a given timeout", {"timeout"}
	);

	args::Positional<std::string> image
	(
		parser, "image", "ELF executable to run", args::Options::Required
	);

	try {
		parser.ParseCLI(argc, argv);
	} catch(args::Help) {
		std::cerr << parser;
		return EXIT_FAILURE;
	} catch(args::ParseError e) {
		std::cerr << e.what() << std::endl << parser;
		return EXIT_FAILURE;
	} catch(args::ValidationError e) {
		std::cerr << e.what() << std::endl << parser;
		return EXIT_FAILURE;
	}

	simulation sim;

	bool tracing = false;
	if (trace_out) {
#if VM_TRACE
		sim.set_trace_path(*trace_out);
		tracing = true;
#else
		std::fputs("Warning: trace output was requested, but simulation was compiled without trace support\n", stderr);
#endif
	}

	elf_loader loader(sim, image->c_str());
	if (int error = loader.error(); error != 0) {
		std::fprintf(stderr, "Error: loading ELF image '%s': %s\n", image->c_str(), std::strerror(error));
		return EXIT_FAILURE;
	}

	auto entrypoint = loader.entrypoint();
	if (entrypoint != HSV_CORE_RESET_PC) {
		std::fprintf(stderr, "Error: image entrypoint is 0x%08x, but CPU starts at 0x%08x, fix your linker script\n", entrypoint, HSV_CORE_RESET_PC);
		return EXIT_FAILURE;
	}

	bool io_available = false;

	auto magic_io_base = loader.magic_io_base();
	if (magic_io_base)
		std::fprintf(stderr, "Inferred 0x%08x as magic I/O base from ELF symbol table\n", *magic_io_base);
	else
		std::fputs("Warning: --magic-io not set and value cannot be determined from ELF tables\n", stderr);

	std::unique_ptr<memory_mapped> magic_io;
	if (magic_io_base) {
		magic_io = std::make_unique<magic_io_agent>(sim, *magic_io_base);
		io_available = true;
	}

	if (!io_available && !tracing) {
		std::fputs(
			"Error: no host I/O devices were mapped and tracing is disabled, "
			"simulating with no output is useless\n",
			stderr
		);

		return EXIT_FAILURE;
	}

	if (timeout && *timeout > 0) {
		alarm_sim.store(&sim);
		std::signal(SIGALRM, simulation_timeout);
		::alarm(*timeout);
	} else if (timeout)
		std::fputs("Warning: --timeout=0 disables the timeout\n", stderr);

	int exit_code = sim.run();

#if VM_TRACE
	if (trace_out) {
		try {
			auto size = std::filesystem::file_size(*trace_out);

			unsigned factor;
			const char *suffix;

			if (size < 1024 * 1024) {
				factor = 1024;
				suffix = "KiB";
			} else if (size < 1024 * 1024 * 1024) {
				factor = 1024 * 1024;
				suffix = "MiB";
			} else {
				factor = 1024 * 1024 * 1024;
				suffix = "GiB";
			}

			std::fprintf(stderr, "Signal dump file size is %.1f %s\n", static_cast<float>(size) / factor, suffix);
		} catch (const std::filesystem::filesystem_error &) {
			std::fprintf(stderr, "Warning: failed to stat trace file: %s\n", trace_out->c_str());
		}
	}
#endif

	alarm_sim.store(nullptr);
	return exit_code;
}
