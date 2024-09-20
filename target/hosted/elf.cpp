#include <cstddef>
#include <cstdint>

#include <elf.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

#include "elf_loader.hpp"

elf_loader::elf_loader(simulation &sim, const char *path)
{
	int fd = ::open(path, O_RDONLY);
	if (fd < 0) {
		this->error = errno;
		return;
	}

	off_t end_offset = ::lseek(fd, 0, SEEK_END);
	if (end_offset < 0 || end_offset < sizeof(Elf32_Ehdr)) {
		::close(fd);
		this->error = errno;
		return;
	}

	auto elf_size = static_cast<std::size_t>(end_offset);

	void *elf_base = ::mmap(nullptr, elf_size, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0);
	if (elf_base == MAP_FAILED) {
		::close(fd);
		this->error = errno;
		return;
	}

	::close(fd);
	fd = -1;

	this->mappings.push_back(mapping{elf_base, elf_size});

	auto *header = static_cast<Elf32_Ehdr*>(elf_base);

	unsigned char *magic = header->e_ident;
	if (magic[0] != ELFMAG0 || magic[1] != ELFMAG1 || magic[2] != ELFMAG2 || magic[3] != ELFMAG3
	 || header->e_type != ET_EXEC || header->e_machine != EM_RISCV || header->e_version != EV_CURRENT
	 || header->e_phoff == 0 || header->e_phentsize < sizeof(Elf32_Phdr) || header->e_phnum == 0)
	{
		this->error = ENOEXEC;
		return;
	}

	auto *segment_base = static_cast<char *>(elf_base) + header->e_phoff;
	for (std::uint16_t i = 0; i < header->e_phnum; ++i) {
		auto *segment_header = reinterpret_cast<Elf32_Phdr *>(segment_base + i * header->e_phentsize);
		if (segment_header->p_type != PT_LOAD)
			continue;

		auto *data = static_cast<char *>(elf_base) + segment_header->p_offset;
		Elf32_Addr base = segment_header->p_vaddr;
		std::uint32_t file_size = segment_header->p_filesz;
		std::uint32_t region_size = segment_header->p_memsz;

		if (file_size > 0)
			this->segments.push_back(memory_region{sim, base, data, file_size});

		std::uint32_t zero_size = region_size - file_size;
		if (zero_size > 0) {
			void *zeroed = ::mmap(nullptr, zero_size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
			if (zeroed == MAP_FAILED) {
				this->error = errno;
				return;
			}

			this->mappings.push_back(mapping{zeroed, zero_size});
			this->segments.push_back(memory_region{sim, base, zeroed, zero_size});
		}
	}
}

elf_loader::~elf_loader()
{
	for (const auto &mapping : this->mappings)
		::munmap(mapping.base, mapping.length);
}
