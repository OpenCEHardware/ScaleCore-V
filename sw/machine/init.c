#include <stdlib.h>

int u_main(void);

int __attribute__((noreturn)) main()
{
	exit(u_main());

	while (1)
		asm volatile("wfi");
}
