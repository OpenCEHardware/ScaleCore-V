import itertools

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles, Timer, Edge
from cocotb.result import TestFailure
from cocotb_bus.drivers import BitDriver
import random

expected_results = []
is_signed = []

# Define structures as classes
class ExecMemCommon:
    def __init__(self):
        self.token = 0
        self.pc = 0
        self.pc_increment = 0
        self.rs1_addr = 0
        self.rs2_addr = 0
        self.rd_addr = 0
        self.rs1 = 0
        self.rs2 = 0
        self.immediate = 0

    def randomize(self):
        self.token = random.randint(0, 0xFF)
        self.pc = random.randint(0, 0xFFFFFFFF)
        self.pc_increment = self.pc + 4
        self.rs1_addr = random.randint(0, 31)
        self.rs2_addr = random.randint(0, 31)
        self.rd_addr = random.randint(0, 31)
        self.rs1 = random.randint(0, 0xFFFFFFFF)
        self.rs2 = random.randint(0, 0xFFFFFFFF)
        #self.rs1 = random.randint(1, 1)
        #self.rs2 = random.randint(-2, 2)
        self.immediate = random.randint(0, 0xFFFFFFFF)
        #self.immediate = random.randint(-3, 3)


    async def drive(self, dut):
        dut.common.token <= self.token
        dut.common.pc <= self.pc
        dut.common.pc_increment <= self.pc_increment
        dut.common.rs1_addr <= self.rs1_addr
        dut.common.rs2_addr <= self.rs2_addr
        dut.common.rd_addr <= self.rd_addr
        dut.common.rs1 <= self.rs1
        dut.common.rs2 <= self.rs2
        dut.common.immediate <= self.immediate

# Define ALU opcodes
OPCODES = {
    'OPCODE_ADD':   0b00000,
    'OPCODE_ADDI':  0b00001,
    'OPCODE_SUB':   0b00010,
    'OPCODE_AND':   0b00011,
    'OPCODE_ANDI':  0b00100,
    'OPCODE_OR':    0b00101,
    'OPCODE_ORI':   0b00110,
    'OPCODE_XOR':   0b00111,
    'OPCODE_XORI':  0b01000,
    'OPCODE_SLL':   0b01001,
    'OPCODE_SLLI':  0b01010,
    'OPCODE_SRL':   0b01011,
    'OPCODE_SRLI':  0b01100,
    'OPCODE_SRA':   0b01101,
    'OPCODE_SRAI':  0b01110,
    'OPCODE_SLT':   0b01111,
    'OPCODE_SLTI':  0b10000,
    'OPCODE_SLTU':  0b10001,
    'OPCODE_SLTIU': 0b10010,
    'OPCODE_LUI':   0b10011,
    'OPCODE_AUIPC': 0b10100
}

@cocotb.coroutine
async def reset_dut(dut):
    """Reset the DUT."""
    dut.rst_core_n.value = 0
    await ClockCycles(dut.clk_core, 5)
    dut.rst_core_n.value = 1
    await RisingEdge(dut.clk_core)


@cocotb.coroutine
async def check_output(dut, expected_valid_o):
    """Check the outputs of the ALU."""

    assert int(dut.valid_o.value) == int(expected_valid_o)

    expected_result = expected_results.pop(0) & 0xFFFFFFFF

    assert dut.result.value == expected_result


@cocotb.coroutine
async def drive_inputs(dut, opcode, common, illegal=0, flush_req=0):
    """Drive the inputs of the ALU."""
    dut.opcode.value = opcode
    dut.flush_req.value = flush_req
    dut.illegal.value = illegal
    dut.token.value = common.token
    dut.pc.value = common.pc
    dut.pc_increment.value = common.pc_increment
    dut.rs1_addr.value = common.rs1_addr
    dut.rs2_addr.value = common.rs2_addr
    dut.rd_addr.value = common.rd_addr
    dut.rs1.value = common.rs1
    dut.rs2.value = common.rs2
    dut.immediate.value = common.immediate

def to_signed_32bit(n):
    # Convert to signed if the number is greater than 0x7FFFFFFF
    if n > 0x7FFFFFFF:
        n -= 0x100000000
    return n

def arithmetic_right_shift(value, shift_amount):
    # RISC-V RV32I uses only the lower 5 bits of the shift amount
    shift_amount &= 0x1F  # equivalent to modulo 32
    
    if shift_amount == 0:
        return value  # no shift
    elif shift_amount >= 31:
        # Shift by 31 or more behaves like shifting by 31
        return -1 if value < 0 else 0
    
    # Perform arithmetic right shift with sign extension
    if value < 0:
        # Negative value: Python handles signed shift natively
        return value >> shift_amount
    else:
        # Positive value: Simply shift right
        return value >> shift_amount

@cocotb.coroutine
async def sender(dut, common):
    while True:
        # Assert valid signal only if ready is asserted

        if dut.ready_o.value:

            # Randomly select an opcode from the available operations
            opcode = random.choice(list(OPCODES.values()))
            #opcode = OPCODES['OPCODE_LUI']        
            # Randomize the inputs
            common.randomize()

            if opcode in [OPCODES['OPCODE_ADD'],OPCODES['OPCODE_ADDI'],OPCODES['OPCODE_SUB'],OPCODES['OPCODE_SRA'], \
            OPCODES['OPCODE_SRAI'],OPCODES['OPCODE_SLT'],OPCODES['OPCODE_SLTI']]:
                common.rs1 = to_signed_32bit(common.rs1)
                common.rs2 = to_signed_32bit(common.rs1)
                common.immediate = to_signed_32bit(common.immediate)

            # Update expected results based on the selected opcode
            if opcode == OPCODES['OPCODE_ADD']:
                expected_results.append(common.rs1 + common.rs2)
            elif opcode == OPCODES['OPCODE_ADDI']:
                expected_results.append(common.rs1 + common.immediate)
            elif opcode == OPCODES['OPCODE_SUB']:
                expected_results.append(common.rs1 - common.rs2)
            elif opcode == OPCODES['OPCODE_AND']:
                expected_results.append(common.rs1 & common.rs2)
            elif opcode == OPCODES['OPCODE_ANDI']:
                expected_results.append(common.rs1 & common.immediate)
            elif opcode == OPCODES['OPCODE_OR']:
                expected_results.append(common.rs1 | common.rs2)
            elif opcode == OPCODES['OPCODE_ORI']:
                expected_results.append(common.rs1 | common.immediate)  
            elif opcode == OPCODES['OPCODE_XOR']:
                expected_results.append(common.rs1 ^ common.rs2)
            elif opcode == OPCODES['OPCODE_XORI']:
                expected_results.append(common.rs1 ^ common.immediate)

            elif opcode == OPCODES['OPCODE_SLL']:
                expected_results.append(common.rs1 << (common.rs2 % 32))  # Logical shift left 
            elif opcode == OPCODES['OPCODE_SLLI']:
                expected_results.append(common.rs1 << (common.immediate % 32)) 
            elif opcode == OPCODES['OPCODE_SRL']:
                expected_results.append(common.rs1 >> (common.rs2 % 32)) # Logical shift right
            elif opcode == OPCODES['OPCODE_SRLI']:
                expected_results.append(common.rs1 >> (common.immediate % 32)) 
            elif opcode == OPCODES['OPCODE_SRA']:
                expected_results.append(arithmetic_right_shift(common.rs1, common.rs2))
            elif opcode == OPCODES['OPCODE_SRAI']:
                expected_results.append(arithmetic_right_shift(common.rs1, common.immediate))


            elif opcode == OPCODES['OPCODE_SLT']:
                expected_results.append(1 if common.rs1 < common.rs2 else 0)
            elif opcode == OPCODES['OPCODE_SLTI']:
                expected_results.append(1 if common.rs1 < common.immediate else 0)
            elif opcode == OPCODES['OPCODE_SLTU']:
                expected_results.append(1 if (common.rs1) < (common.rs2) else 0)  # Unsigned comparison
            elif opcode == OPCODES['OPCODE_SLTIU']:
                expected_results.append(1 if (common.rs1) < (common.immediate) else 0) 


            elif opcode == OPCODES['OPCODE_LUI']:
                expected_results.append(common.rs1 + common.immediate)  # LUI might just be used for loading immediate values; adjust as needed
            elif opcode == OPCODES['OPCODE_AUIPC']:
                expected_results.append(common.pc + common.immediate)  # AUIPC might just be used for computing relative addresses; adjust as needed
            else:
                # Handle cases where the opcode does not have an expected result
                expected_results.append(None)
            
            # Drive inputs with the selected opcode
            await drive_inputs(dut, opcode, common)
            dut.valid_i.value = 1
            await RisingEdge(dut.clk_core)
            dut.valid_i.value = 0
            # Wait for a random amount of time before sending data more
            await Timer(random.randint(1, 5), units='ns')

        else:
            await RisingEdge(dut.ready_o)  # Wait for the receiver to be ready

@cocotb.coroutine
async def receiver(dut):
    while True:
        # Randomly set the ready signal
        dut.ready_i.value = random.choice([0, 1])
        duration = random.choice([0, 5])
        await ClockCycles(dut.clk_core, duration)

@cocotb.test()
async def alu_test_add(dut):
    """Test the ALU functionality with all opcodes."""

    # Set up the clock
    clock = Clock(dut.clk_core, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Reset the DUT
    await reset_dut(dut)

    # Initialize variables
    common = ExecMemCommon()

    # Start sender and receiver coroutines
    cocotb.start_soon(sender(dut,common))
    cocotb.start_soon(receiver(dut))

    for _ in range(1000000):

        await RisingEdge(dut.clk_core)
        
        # Check if the ALU result is valid
        if dut.valid_o.value and dut.ready_i.value:
            # Check the ALU output
            await check_output(dut, 1)
    
    await ClockCycles(dut.clk_core, 10)


    print("All operation tests passed successfully!")

