# Home

Welcome to the documentation for **OpenCEHardware’s ScaleCore-V** hardware module. This resource provides a comprehensive guide to understanding and working with the ScaleCore-V block, detailing its current capabilities, configurations, and design specifications.

## Navigation

To help you get the most out of this documentation, we've organized it into the following sections:

<div class="grid cards" markdown>

- :fontawesome-solid-book: [Revisions](block/revisions.md): History of updates and changes made to the ScaleCore-V module.
- :fontawesome-solid-gavel: [Document Conventions](block/conventions.md): Definitions, abbreviations, and standards used throughout the document.
- :fontawesome-solid-lightbulb: [Introduction](block/introduction.md): Overview of the ScaleCore-V module and its key features.
- :fontawesome-solid-diagram-project: [Block Diagram](block/diagram.md): Visual representation of the ScaleCore-V microarchitecture.
- :fontawesome-solid-gear: [Configuration](block/configuration.md): Information about module parameters, typedefs, and RTL interfaces.
- :fontawesome-solid-network-wired: [Protocols](block/protocols.md): Details on communication and operational protocols within ScaleCore-V.
- :fontawesome-solid-memory: [Memory Map](block/memory.md): Structure and allocation of memory resources in the ScaleCore-V.
- :fontawesome-solid-clipboard-list: [Registers](block/registers.md): Description of registers utilized in the ScaleCore-V system.
- :fontawesome-solid-clock: [Clock Domains](block/clocks.md): Clock structure and domain management within ScaleCore-V.
- :fontawesome-solid-wave-square: [Reset Domains](block/resets.md): Information on reset mechanisms and domain organization.
- :fontawesome-solid-bell: [Interrupts](block/interrupts.md): Management and handling of interrupts within the ScaleCore-V module.
- :fontawesome-solid-flag: [Arbitration](block/arbitration.md): Methods for arbitration and shared resource access control.
- :fontawesome-solid-bug: [Debugging](block/debugging.md): Techniques and tools for debugging the ScaleCore-V system.
- :fontawesome-solid-table: [Synthesis](block/synthesis.md): Overview of design synthesis and performance results.
- :fontawesome-solid-table: [Verification](block/verification.md): Verification strategies, environments, and testbenches used with ScaleCore-V.
Here's the updated **Microarchitecture** section with the correct sub-modules:
- **Microarchitecture:**
    - :fontawesome-solid-cube: [Fetch](block/microarchitecture/fetch.md): Fetching and instruction retrieval mechanism.
    - :fontawesome-solid-cube: [Decode](block/microarchitecture/decode.md): Instruction decoding and preparation for execution.
    - :fontawesome-solid-cube: [Issue](block/microarchitecture/issue.md): Issuing instructions to relevant execution units.
    - :fontawesome-solid-cube: [ALU](block/microarchitecture/alu.md): Arithmetic and logical operations performed by the ALU.
    - :fontawesome-solid-cube: [Branch](block/microarchitecture/branch.md): Branch prediction and handling mechanisms.
    - :fontawesome-solid-cube: [Foo](block/microarchitecture/foo.md): Additional unit for extra operations.
    - :fontawesome-solid-cube: [Memory](block/microarchitecture/memory.md): Memory management and access control.
    - :fontawesome-solid-cube: [Control-Status](block/microarchitecture/control-status.md): Control and status register management.
    - :fontawesome-solid-cube: [Commit](block/microarchitecture/commit.md): Commit process for finalized instructions.
    - :fontawesome-solid-cube: [Skid-Buffer](block/microarchitecture/skid-buffer.md): Buffering for pipeline delays and instruction stalls.
    - :fontawesome-solid-cube: [FIFO](block/microarchitecture/fifo.md): First-In-First-Out buffer management for data handling.

</div>


## Acknowledgements

Please check the [References](block/references.md) section for more information.