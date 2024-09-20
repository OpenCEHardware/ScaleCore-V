#include <cstring>
#include <utility>

#include "args.hxx"
#include "elf_loader.hpp"
#include "simulation.hpp"

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

	if (trace_out) {
#if VM_TRACE
		sim.set_trace_path(std::move(*trace_out));
#else
		std::cerr << "Warning: trace output was requested, but simulation was compiled without trace support\n";
#endif
	}

	elf_loader loader(sim, image->c_str());
	if (int error = loader.get_errno(); error != 0) {
		std::cerr << "Error: loading ELF image '" << *image << "': " << std::strerror(error) << '\n';
		return EXIT_FAILURE;
	}

	sim.run();
	return EXIT_SUCCESS;
}
