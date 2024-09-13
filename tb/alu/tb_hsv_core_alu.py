import itertools

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer
from cocotb_bus.drivers import BitDriver

@cocotb.test()
async def alu(dut):
    await cocotb.start(Clock(dut.clk_core, 2).start())

    await Timer(1)

    await ClockCycles(dut.clk_core, 1 << 16)


