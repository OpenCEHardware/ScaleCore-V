#include <cstdio>
#include <cstring>
#include <memory>
#include <utility>

#include "args.hxx"
#include "elf_loader.hpp"
#include "magic_io.hpp"
#include "simulation.hpp"

namespace
{
	constexpr unsigned HSV_CORE_RESET_PC = 0x0;
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
		parser, "trace", "trace output file", {"trace"}
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
		sim.set_trace_path(std::move(*trace_out));
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

	return sim.run();
}
