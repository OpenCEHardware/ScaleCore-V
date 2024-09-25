cores := hsv_host_image hsv_host_sw hsv_picolibc
subdirs := machine user

define core/hsv_host_sw
  $(this)/deps := hsv_machine_sw hsv_user_sw hsv_picolibc
  $(this)/cross := riscv32-none-elf-
  $(this)/hooks := cc objcopy obj

  $(this)/obj_deps := picolibc/picolibc.specs

  $(this)/cc_flags  = $$(if $$(enable_opt),-O3 -ffast-math) -g \
                      -march=rv32i_zicsr -mabi=ilp32 --specs=$$(obj)/picolibc/picolibc.specs
  $(this)/ld_flags := --oslib=semihost
  $(this)/ld_binary := hsv_host_image

  $(this)/objcopy_src := hsv_host_image
  $(this)/objcopy_obj := hsv_host_image.bin
endef

define core/hsv_picolibc
  $(this)/hooks := meson obj

  $(this)/obj_deps := /$(here)cross-riscv32-none-elf.txt

  $(this)/meson_src := picolibc
  $(this)/meson_objs := picolibc/picolibc.specs

  $(this)/meson_args = \
    -Dincludedir=include \
    -Dlibdir=lib \
    -Dspecsdir=. \
    -Dmultilib=false \
    -Dprefix=$$(src)/$$(obj)/picolibc \
    --cross-file $(here)cross-riscv32-none-elf.txt
endef
