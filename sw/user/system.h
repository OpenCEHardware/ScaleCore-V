/*
 * system.h - SOPC Builder system and BSP software package information
 *
 * Machine generated for CPU 'cpu' in SOPC Builder design 'cpu'
 * SOPC Builder design path: ../../cpu.sopcinfo
 *
 * Generated: Thu Aug 22 16:02:23 CST 2024
 */

/*
 * DO NOT MODIFY THIS FILE
 *
 * Changing this file will have subtle consequences
 * which will almost certainly lead to a nonfunctioning
 * system. If you do modify this file, be aware that your
 * changes will be overwritten and lost when this file
 * is generated again.
 *
 * DO NOT MODIFY THIS FILE
 */

/*
 * License Agreement
 *
 * Copyright (c) 2008
 * Altera Corporation, San Jose, California, USA.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 * This agreement shall be governed in all respects by the laws of the State
 * of California and by the laws of the United States of America.
 */

#ifndef __SYSTEM_H_
#define __SYSTEM_H_

/* Include definitions from linker script generator */
//#include "linker.h"


/*
 * CPU configuration
 *
 */

#define ALT_CPU_ARCHITECTURE "altera_nios2_gen2"
#define ALT_CPU_BIG_ENDIAN 0
#define ALT_CPU_BREAK_ADDR 0x00002820
#define ALT_CPU_CPU_ARCH_NIOS2_R1
#define ALT_CPU_CPU_FREQ 50000000u
#define ALT_CPU_CPU_ID_SIZE 1
#define ALT_CPU_CPU_ID_VALUE 0x00000000
#define ALT_CPU_CPU_IMPLEMENTATION "tiny"
#define ALT_CPU_DATA_ADDR_WIDTH 0xe
#define ALT_CPU_DCACHE_LINE_SIZE 0
#define ALT_CPU_DCACHE_LINE_SIZE_LOG2 0
#define ALT_CPU_DCACHE_SIZE 0
#define ALT_CPU_EXCEPTION_ADDR 0x00001020
#define ALT_CPU_FLASH_ACCELERATOR_LINES 0
#define ALT_CPU_FLASH_ACCELERATOR_LINE_SIZE 0
#define ALT_CPU_FLUSHDA_SUPPORTED
#define ALT_CPU_FREQ 50000000
#define ALT_CPU_HARDWARE_DIVIDE_PRESENT 0
#define ALT_CPU_HARDWARE_MULTIPLY_PRESENT 0
#define ALT_CPU_HARDWARE_MULX_PRESENT 0
#define ALT_CPU_HAS_DEBUG_CORE 1
#define ALT_CPU_HAS_DEBUG_STUB
#define ALT_CPU_HAS_ILLEGAL_INSTRUCTION_EXCEPTION
#define ALT_CPU_HAS_JMPI_INSTRUCTION
#define ALT_CPU_ICACHE_LINE_SIZE 0
#define ALT_CPU_ICACHE_LINE_SIZE_LOG2 0
#define ALT_CPU_ICACHE_SIZE 0
#define ALT_CPU_INST_ADDR_WIDTH 0xe
#define ALT_CPU_NAME "cpu"
#define ALT_CPU_OCI_VERSION 1
#define ALT_CPU_RESET_ADDR 0x00001000


/*
 * CPU configuration (with legacy prefix - don't use these anymore)
 *
 */

#define NIOS2_BIG_ENDIAN 0
#define NIOS2_BREAK_ADDR 0x00002820
#define NIOS2_CPU_ARCH_NIOS2_R1
#define NIOS2_CPU_FREQ 50000000u
#define NIOS2_CPU_ID_SIZE 1
#define NIOS2_CPU_ID_VALUE 0x00000000
#define NIOS2_CPU_IMPLEMENTATION "tiny"
#define NIOS2_DATA_ADDR_WIDTH 0xe
#define NIOS2_DCACHE_LINE_SIZE 0
#define NIOS2_DCACHE_LINE_SIZE_LOG2 0
#define NIOS2_DCACHE_SIZE 0
#define NIOS2_EXCEPTION_ADDR 0x00001020
#define NIOS2_FLASH_ACCELERATOR_LINES 0
#define NIOS2_FLASH_ACCELERATOR_LINE_SIZE 0
#define NIOS2_FLUSHDA_SUPPORTED
#define NIOS2_HARDWARE_DIVIDE_PRESENT 0
#define NIOS2_HARDWARE_MULTIPLY_PRESENT 0
#define NIOS2_HARDWARE_MULX_PRESENT 0
#define NIOS2_HAS_DEBUG_CORE 1
#define NIOS2_HAS_DEBUG_STUB
#define NIOS2_HAS_ILLEGAL_INSTRUCTION_EXCEPTION
#define NIOS2_HAS_JMPI_INSTRUCTION
#define NIOS2_ICACHE_LINE_SIZE 0
#define NIOS2_ICACHE_LINE_SIZE_LOG2 0
#define NIOS2_ICACHE_SIZE 0
#define NIOS2_INST_ADDR_WIDTH 0xe
#define NIOS2_OCI_VERSION 1
#define NIOS2_RESET_ADDR 0x00001000


/*
 * Define for each module class mastered by the CPU
 *
 */

#define __ALTERA_AVALON_JTAG_UART
#define __ALTERA_AVALON_ONCHIP_MEMORY2
#define __ALTERA_AVALON_PIO
#define __ALTERA_AVALON_TIMER
#define __ALTERA_NIOS2_GEN2


/*
 * System configuration
 *
 */

#define ALT_DEVICE_FAMILY "Cyclone V"
#define ALT_ENHANCED_INTERRUPT_API_PRESENT
#define ALT_IRQ_BASE NULL
#define ALT_LOG_PORT "/dev/null"
#define ALT_LOG_PORT_BASE 0x0
#define ALT_LOG_PORT_DEV null
#define ALT_LOG_PORT_TYPE ""
#define ALT_NUM_EXTERNAL_INTERRUPT_CONTROLLERS 0
#define ALT_NUM_INTERNAL_INTERRUPT_CONTROLLERS 1
#define ALT_NUM_INTERRUPT_CONTROLLERS 1
#define ALT_STDERR "/dev/jtag_uart_0"
#define ALT_STDERR_BASE 0x30d8
#define ALT_STDERR_DEV jtag_uart_0
#define ALT_STDERR_IS_JTAG_UART
#define ALT_STDERR_PRESENT
#define ALT_STDERR_TYPE "altera_avalon_jtag_uart"
#define ALT_STDIN "/dev/jtag_uart_0"
#define ALT_STDIN_BASE 0x30d8
#define ALT_STDIN_DEV jtag_uart_0
#define ALT_STDIN_IS_JTAG_UART
#define ALT_STDIN_PRESENT
#define ALT_STDIN_TYPE "altera_avalon_jtag_uart"
#define ALT_STDOUT "/dev/jtag_uart_0"
#define ALT_STDOUT_BASE 0x30d8
#define ALT_STDOUT_DEV jtag_uart_0
#define ALT_STDOUT_IS_JTAG_UART
#define ALT_STDOUT_PRESENT
#define ALT_STDOUT_TYPE "altera_avalon_jtag_uart"
#define ALT_SYSTEM_NAME "cpu"


/*
 * hal configuration
 *
 */

#define ALT_INCLUDE_INSTRUCTION_RELATED_EXCEPTION_API
#define ALT_MAX_FD 4
#define ALT_SYS_CLK none
#define ALT_TIMESTAMP_CLK none


/*
 * jtag_uart_0 configuration
 *
 */

#define ALT_MODULE_CLASS_jtag_uart_0 altera_avalon_jtag_uart
#define JTAG_UART_0_BASE 0x800030d8
#define JTAG_UART_0_IRQ 0
#define JTAG_UART_0_IRQ_INTERRUPT_CONTROLLER_ID 0
#define JTAG_UART_0_NAME "/dev/jtag_uart_0"
#define JTAG_UART_0_READ_DEPTH 64
#define JTAG_UART_0_READ_THRESHOLD 8
#define JTAG_UART_0_SPAN 8
#define JTAG_UART_0_TYPE "altera_avalon_jtag_uart"
#define JTAG_UART_0_WRITE_DEPTH 64
#define JTAG_UART_0_WRITE_THRESHOLD 8


/*
 * leds_hours_ls configuration
 *
 */

#define ALT_MODULE_CLASS_leds_hours_ls altera_avalon_pio
#define LEDS_HOURS_LS_BASE 0x800030a0
#define LEDS_HOURS_LS_BIT_CLEARING_EDGE_REGISTER 0
#define LEDS_HOURS_LS_BIT_MODIFYING_OUTPUT_REGISTER 0
#define LEDS_HOURS_LS_CAPTURE 0
#define LEDS_HOURS_LS_DATA_WIDTH 7
#define LEDS_HOURS_LS_DO_TEST_BENCH_WIRING 0
#define LEDS_HOURS_LS_DRIVEN_SIM_VALUE 0
#define LEDS_HOURS_LS_EDGE_TYPE "NONE"
#define LEDS_HOURS_LS_FREQ 50000000
#define LEDS_HOURS_LS_HAS_IN 0
#define LEDS_HOURS_LS_HAS_OUT 1
#define LEDS_HOURS_LS_HAS_TRI 0
#define LEDS_HOURS_LS_IRQ -1
#define LEDS_HOURS_LS_IRQ_INTERRUPT_CONTROLLER_ID -1
#define LEDS_HOURS_LS_IRQ_TYPE "NONE"
#define LEDS_HOURS_LS_NAME "/dev/leds_hours_ls"
#define LEDS_HOURS_LS_RESET_VALUE 0
#define LEDS_HOURS_LS_SPAN 16
#define LEDS_HOURS_LS_TYPE "altera_avalon_pio"


/*
 * leds_hours_ms configuration
 *
 */

#define ALT_MODULE_CLASS_leds_hours_ms altera_avalon_pio
#define LEDS_HOURS_MS_BASE 0x80003060
#define LEDS_HOURS_MS_BIT_CLEARING_EDGE_REGISTER 0
#define LEDS_HOURS_MS_BIT_MODIFYING_OUTPUT_REGISTER 0
#define LEDS_HOURS_MS_CAPTURE 0
#define LEDS_HOURS_MS_DATA_WIDTH 7
#define LEDS_HOURS_MS_DO_TEST_BENCH_WIRING 0
#define LEDS_HOURS_MS_DRIVEN_SIM_VALUE 0
#define LEDS_HOURS_MS_EDGE_TYPE "NONE"
#define LEDS_HOURS_MS_FREQ 50000000
#define LEDS_HOURS_MS_HAS_IN 0
#define LEDS_HOURS_MS_HAS_OUT 1
#define LEDS_HOURS_MS_HAS_TRI 0
#define LEDS_HOURS_MS_IRQ -1
#define LEDS_HOURS_MS_IRQ_INTERRUPT_CONTROLLER_ID -1
#define LEDS_HOURS_MS_IRQ_TYPE "NONE"
#define LEDS_HOURS_MS_NAME "/dev/leds_hours_ms"
#define LEDS_HOURS_MS_RESET_VALUE 0
#define LEDS_HOURS_MS_SPAN 16
#define LEDS_HOURS_MS_TYPE "altera_avalon_pio"


/*
 * leds_minutes_ls configuration
 *
 */

#define ALT_MODULE_CLASS_leds_minutes_ls altera_avalon_pio
#define LEDS_MINUTES_LS_BASE 0x800030c0
#define LEDS_MINUTES_LS_BIT_CLEARING_EDGE_REGISTER 0
#define LEDS_MINUTES_LS_BIT_MODIFYING_OUTPUT_REGISTER 0
#define LEDS_MINUTES_LS_CAPTURE 0
#define LEDS_MINUTES_LS_DATA_WIDTH 7
#define LEDS_MINUTES_LS_DO_TEST_BENCH_WIRING 0
#define LEDS_MINUTES_LS_DRIVEN_SIM_VALUE 0
#define LEDS_MINUTES_LS_EDGE_TYPE "NONE"
#define LEDS_MINUTES_LS_FREQ 50000000
#define LEDS_MINUTES_LS_HAS_IN 0
#define LEDS_MINUTES_LS_HAS_OUT 1
#define LEDS_MINUTES_LS_HAS_TRI 0
#define LEDS_MINUTES_LS_IRQ -1
#define LEDS_MINUTES_LS_IRQ_INTERRUPT_CONTROLLER_ID -1
#define LEDS_MINUTES_LS_IRQ_TYPE "NONE"
#define LEDS_MINUTES_LS_NAME "/dev/leds_minutes_ls"
#define LEDS_MINUTES_LS_RESET_VALUE 0
#define LEDS_MINUTES_LS_SPAN 16
#define LEDS_MINUTES_LS_TYPE "altera_avalon_pio"


/*
 * leds_minutes_ms configuration
 *
 */

#define ALT_MODULE_CLASS_leds_minutes_ms altera_avalon_pio
#define LEDS_MINUTES_MS_BASE 0x800030b0
#define LEDS_MINUTES_MS_BIT_CLEARING_EDGE_REGISTER 0
#define LEDS_MINUTES_MS_BIT_MODIFYING_OUTPUT_REGISTER 0
#define LEDS_MINUTES_MS_CAPTURE 0
#define LEDS_MINUTES_MS_DATA_WIDTH 7
#define LEDS_MINUTES_MS_DO_TEST_BENCH_WIRING 0
#define LEDS_MINUTES_MS_DRIVEN_SIM_VALUE 0
#define LEDS_MINUTES_MS_EDGE_TYPE "NONE"
#define LEDS_MINUTES_MS_FREQ 50000000
#define LEDS_MINUTES_MS_HAS_IN 0
#define LEDS_MINUTES_MS_HAS_OUT 1
#define LEDS_MINUTES_MS_HAS_TRI 0
#define LEDS_MINUTES_MS_IRQ -1
#define LEDS_MINUTES_MS_IRQ_INTERRUPT_CONTROLLER_ID -1
#define LEDS_MINUTES_MS_IRQ_TYPE "NONE"
#define LEDS_MINUTES_MS_NAME "/dev/leds_minutes_ms"
#define LEDS_MINUTES_MS_RESET_VALUE 0
#define LEDS_MINUTES_MS_SPAN 16
#define LEDS_MINUTES_MS_TYPE "altera_avalon_pio"


/*
 * memoria configuration
 *
 */

#define ALT_MODULE_CLASS_memoria altera_avalon_onchip_memory2
#define MEMORIA_ALLOW_IN_SYSTEM_MEMORY_CONTENT_EDITOR 0
#define MEMORIA_ALLOW_MRAM_SIM_CONTENTS_ONLY_FILE 0
#define MEMORIA_BASE 0x0000
#define MEMORIA_CONTENTS_INFO ""
#define MEMORIA_DUAL_PORT 0
#define MEMORIA_GUI_RAM_BLOCK_TYPE "AUTO"
#define MEMORIA_INIT_CONTENTS_FILE "cpu_memoria"
#define MEMORIA_INIT_MEM_CONTENT 1
#define MEMORIA_INSTANCE_ID "NONE"
#define MEMORIA_IRQ -1
#define MEMORIA_IRQ_INTERRUPT_CONTROLLER_ID -1
#define MEMORIA_NAME "/dev/memoria"
#define MEMORIA_NON_DEFAULT_INIT_FILE_ENABLED 0
#define MEMORIA_RAM_BLOCK_TYPE "AUTO"
#define MEMORIA_READ_DURING_WRITE_MODE "DONT_CARE"
#define MEMORIA_SINGLE_CLOCK_OP 0
#define MEMORIA_SIZE_MULTIPLE 1
#define MEMORIA_SIZE_VALUE 4096
#define MEMORIA_SPAN 4096
#define MEMORIA_TYPE "altera_avalon_onchip_memory2"
#define MEMORIA_WRITABLE 1


/*
 * pio_buzzer configuration
 *
 */

#define ALT_MODULE_CLASS_pio_buzzer altera_avalon_pio
#define PIO_BUZZER_BASE 0x80003050
#define PIO_BUZZER_BIT_CLEARING_EDGE_REGISTER 0
#define PIO_BUZZER_BIT_MODIFYING_OUTPUT_REGISTER 0
#define PIO_BUZZER_CAPTURE 0
#define PIO_BUZZER_DATA_WIDTH 1
#define PIO_BUZZER_DO_TEST_BENCH_WIRING 0
#define PIO_BUZZER_DRIVEN_SIM_VALUE 0
#define PIO_BUZZER_EDGE_TYPE "NONE"
#define PIO_BUZZER_FREQ 50000000
#define PIO_BUZZER_HAS_IN 0
#define PIO_BUZZER_HAS_OUT 1
#define PIO_BUZZER_HAS_TRI 0
#define PIO_BUZZER_IRQ -1
#define PIO_BUZZER_IRQ_INTERRUPT_CONTROLLER_ID -1
#define PIO_BUZZER_IRQ_TYPE "NONE"
#define PIO_BUZZER_NAME "/dev/pio_buzzer"
#define PIO_BUZZER_RESET_VALUE 0
#define PIO_BUZZER_SPAN 16
#define PIO_BUZZER_TYPE "altera_avalon_pio"


/*
 * pio_key_0 configuration
 *
 */

#define ALT_MODULE_CLASS_pio_key_0 altera_avalon_pio
#define PIO_KEY_0_BASE 0x80003080
#define PIO_KEY_0_BIT_CLEARING_EDGE_REGISTER 0
#define PIO_KEY_0_BIT_MODIFYING_OUTPUT_REGISTER 0
#define PIO_KEY_0_CAPTURE 0
#define PIO_KEY_0_DATA_WIDTH 1
#define PIO_KEY_0_DO_TEST_BENCH_WIRING 1
#define PIO_KEY_0_DRIVEN_SIM_VALUE 1
#define PIO_KEY_0_EDGE_TYPE "NONE"
#define PIO_KEY_0_FREQ 50000000
#define PIO_KEY_0_HAS_IN 1
#define PIO_KEY_0_HAS_OUT 0
#define PIO_KEY_0_HAS_TRI 0
#define PIO_KEY_0_IRQ -1
#define PIO_KEY_0_IRQ_INTERRUPT_CONTROLLER_ID -1
#define PIO_KEY_0_IRQ_TYPE "NONE"
#define PIO_KEY_0_NAME "/dev/pio_key_0"
#define PIO_KEY_0_RESET_VALUE 0
#define PIO_KEY_0_SPAN 16
#define PIO_KEY_0_TYPE "altera_avalon_pio"


/*
 * pio_key_1 configuration
 *
 */

#define ALT_MODULE_CLASS_pio_key_1 altera_avalon_pio
#define PIO_KEY_1_BASE 0x80003070
#define PIO_KEY_1_BIT_CLEARING_EDGE_REGISTER 0
#define PIO_KEY_1_BIT_MODIFYING_OUTPUT_REGISTER 0
#define PIO_KEY_1_CAPTURE 0
#define PIO_KEY_1_DATA_WIDTH 1
#define PIO_KEY_1_DO_TEST_BENCH_WIRING 1
#define PIO_KEY_1_DRIVEN_SIM_VALUE 1
#define PIO_KEY_1_EDGE_TYPE "NONE"
#define PIO_KEY_1_FREQ 50000000
#define PIO_KEY_1_HAS_IN 1
#define PIO_KEY_1_HAS_OUT 0
#define PIO_KEY_1_HAS_TRI 0
#define PIO_KEY_1_IRQ -1
#define PIO_KEY_1_IRQ_INTERRUPT_CONTROLLER_ID -1
#define PIO_KEY_1_IRQ_TYPE "NONE"
#define PIO_KEY_1_NAME "/dev/pio_key_1"
#define PIO_KEY_1_RESET_VALUE 0
#define PIO_KEY_1_SPAN 16
#define PIO_KEY_1_TYPE "altera_avalon_pio"


/*
 * pio_key_2 configuration
 *
 */

#define ALT_MODULE_CLASS_pio_key_2 altera_avalon_pio
#define PIO_KEY_2_BASE 0x80003040
#define PIO_KEY_2_BIT_CLEARING_EDGE_REGISTER 0
#define PIO_KEY_2_BIT_MODIFYING_OUTPUT_REGISTER 0
#define PIO_KEY_2_CAPTURE 0
#define PIO_KEY_2_DATA_WIDTH 1
#define PIO_KEY_2_DO_TEST_BENCH_WIRING 1
#define PIO_KEY_2_DRIVEN_SIM_VALUE 1
#define PIO_KEY_2_EDGE_TYPE "NONE"
#define PIO_KEY_2_FREQ 50000000
#define PIO_KEY_2_HAS_IN 1
#define PIO_KEY_2_HAS_OUT 0
#define PIO_KEY_2_HAS_TRI 0
#define PIO_KEY_2_IRQ -1
#define PIO_KEY_2_IRQ_INTERRUPT_CONTROLLER_ID -1
#define PIO_KEY_2_IRQ_TYPE "NONE"
#define PIO_KEY_2_NAME "/dev/pio_key_2"
#define PIO_KEY_2_RESET_VALUE 0
#define PIO_KEY_2_SPAN 16
#define PIO_KEY_2_TYPE "altera_avalon_pio"


/*
 * pio_switches configuration
 *
 */

#define ALT_MODULE_CLASS_pio_switches altera_avalon_pio
#define PIO_SWITCHES_BASE 0x80003090
#define PIO_SWITCHES_BIT_CLEARING_EDGE_REGISTER 0
#define PIO_SWITCHES_BIT_MODIFYING_OUTPUT_REGISTER 0
#define PIO_SWITCHES_CAPTURE 0
#define PIO_SWITCHES_DATA_WIDTH 2
#define PIO_SWITCHES_DO_TEST_BENCH_WIRING 1
#define PIO_SWITCHES_DRIVEN_SIM_VALUE 0
#define PIO_SWITCHES_EDGE_TYPE "NONE"
#define PIO_SWITCHES_FREQ 50000000
#define PIO_SWITCHES_HAS_IN 1
#define PIO_SWITCHES_HAS_OUT 0
#define PIO_SWITCHES_HAS_TRI 0
#define PIO_SWITCHES_IRQ -1
#define PIO_SWITCHES_IRQ_INTERRUPT_CONTROLLER_ID -1
#define PIO_SWITCHES_IRQ_TYPE "NONE"
#define PIO_SWITCHES_NAME "/dev/pio_switches"
#define PIO_SWITCHES_RESET_VALUE 0
#define PIO_SWITCHES_SPAN 16
#define PIO_SWITCHES_TYPE "altera_avalon_pio"


/*
 * timer configuration
 *
 */

#define ALT_MODULE_CLASS_timer altera_avalon_timer
#define TIMER_ALWAYS_RUN 0
#define TIMER_BASE 0x80003020
#define TIMER_COUNTER_SIZE 32
#define TIMER_FIXED_PERIOD 0
#define TIMER_FREQ 50000000
#define TIMER_IRQ 1
#define TIMER_IRQ_INTERRUPT_CONTROLLER_ID 0
#define TIMER_LOAD_VALUE 49999999
#define TIMER_MULT 1.0
#define TIMER_NAME "/dev/timer"
#define TIMER_PERIOD 1
#define TIMER_PERIOD_UNITS "s"
#define TIMER_RESET_OUTPUT 0
#define TIMER_SNAPSHOT 1
#define TIMER_SPAN 32
#define TIMER_TICKS_PER_SEC 1
#define TIMER_TIMEOUT_PULSE_OUTPUT 0
#define TIMER_TYPE "altera_avalon_timer"

#endif /* __SYSTEM_H_ */
