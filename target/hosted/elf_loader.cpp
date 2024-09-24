#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <utility>

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
		this->error_ = errno;
		return;
	}

	off_t end_offset = ::lseek(fd, 0, SEEK_END);
	if (end_offset < 0 || end_offset < sizeof(Elf32_Ehdr)) {
		::close(fd);
		this->error_ = errno;
		return;
	}

	auto elf_size = static_cast<std::size_t>(end_offset);

	auto *elf_base = static_cast<char *>(::mmap(nullptr, elf_size, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0));
	if (elf_base == MAP_FAILED) {
		::close(fd);
		this->error_ = errno;
		return;
	}

	::close(fd);
	fd = -1;

	this->mappings.push_back(mapping{elf_base, elf_size});

	auto *header = reinterpret_cast<Elf32_Ehdr *>(elf_base);

	unsigned char *magic = header->e_ident;
	if (magic[EI_MAG0] != ELFMAG0 || magic[EI_MAG1] != ELFMAG1 || magic[EI_MAG2] != ELFMAG2
	 || magic[EI_MAG3] != ELFMAG3 || magic[EI_CLASS] != ELFCLASS32 || magic[EI_DATA] != ELFDATA2LSB
	 || magic[EI_VERSION] != EV_CURRENT || header->e_type != ET_EXEC || header->e_machine != EM_RISCV
	 || header->e_version != EV_CURRENT || header->e_phoff == 0 || header->e_phentsize < sizeof(Elf32_Phdr)
	 || header->e_phnum == 0)
	{
		std::fprintf(stderr, "Error: '%s' is not a valid ELF executable for 32-bit little-endian EM_RISCV\n", path);

		this->error_ = ENOEXEC;
		return;
	}

	for (std::uint16_t i = 0; i < header->e_phnum; ++i) {
		auto *segment_header = reinterpret_cast<Elf32_Phdr *>(elf_base + header->e_phoff + i * header->e_phentsize);
		if (segment_header->p_type == PT_DYNAMIC || segment_header->p_type == PT_INTERP) {
			std::fprintf(stderr, "Error: '%s' is not statically linked\n", path);

			this->error_ = ENOEXEC;
			return;
		}
	}

	for (std::uint16_t i = 0; i < header->e_phnum; ++i) {
		auto *segment_header = reinterpret_cast<Elf32_Phdr *>(elf_base + header->e_phoff + i * header->e_phentsize);
		if (segment_header->p_type != PT_LOAD)
			continue;

		bool read_only = !(segment_header->p_flags & PF_W);

		auto *data = elf_base + segment_header->p_offset;
		Elf32_Addr base = segment_header->p_vaddr;
		std::uint32_t file_size = segment_header->p_filesz;
		std::uint32_t region_size = segment_header->p_memsz;

		if (file_size > 0) {
			memory_region region{sim, base, data, file_size};
			if (read_only)
				region.set_read_only();

			this->segments.push_back(std::move(region));
		}

		std::uint32_t zero_size = region_size - file_size;
		if (zero_size > 0) {
			void *zeroed = ::mmap(nullptr, zero_size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
			if (zeroed == MAP_FAILED) {
				this->error_ = errno;
				return;
			}

			this->mappings.push_back(mapping{zeroed, zero_size});

			memory_region region{sim, base, zeroed, zero_size};
			if (read_only)
				region.set_read_only();

			this->segments.push_back(std::move(region));
		}
	}

	this->entrypoint_ = header->e_entry;

	Elf32_Shdr *sym_table = nullptr;
	for (std::uint16_t i = 0; i < header->e_shnum; ++i) {
		auto *section_header = reinterpret_cast<Elf32_Shdr *>(elf_base + header->e_shoff + i * header->e_shentsize);
		if (section_header->sh_type == SHT_SYMTAB) {
			sym_table = section_header;
			break;
		}
	}

	const char *str_table = nullptr;
	if (sym_table && sym_table->sh_link != SHN_UNDEF) {
		auto *section_header = reinterpret_cast<Elf32_Shdr *>(elf_base + header->e_shoff + sym_table->sh_link * header->e_shentsize);
		str_table = elf_base + section_header->sh_offset;
	}

	for (std::uint32_t sym_offset = 0; sym_table && sym_offset < sym_table->sh_size; sym_offset += sym_table->sh_entsize) {
		auto *symbol = reinterpret_cast<Elf32_Sym *>(elf_base + sym_table->sh_offset + sym_offset);
		if (str_table && !std::strcmp(str_table + symbol->st_name, "tohost")) {
			this->magic_io_base_ = symbol->st_value;
			break;
		}
	}
}

elf_loader::~elf_loader()
{
	for (const auto &mapping : this->mappings)
		::munmap(mapping.base, mapping.length);
}
