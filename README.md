# multi_simv
A communication framework utilizing sockets and DPI (Direct Programming Interface) to interconnect multiple testbenches. This approach aims to accelerate simulation speeds and facilitate SoC (System-on-Chip) simulations. While conceptually similar to the distributed simulation feature (distsim) introduced in VCS 2023.

# multi_simv folder
Contains four separate testbenches as outlined in multi_simv.webbp.

Usage:
- Compilation: Execute 'make comp' in the output folder to compile all four testbenches.
- Simulation: Run 'make run' to initiate four simultaneous simv processes.
- Waveform Analysis: Use 'make verdi' to open and examine the four waveforms.

# reference folder
Houses a single testbench that instantiates all four modules from the multi_simv testbenches.

Usage:
- Compilation: In the output folder, run 'make comp' to compile the reference testbench.
- Simulation: Execute 'make run' to perform the simulation.
- Waveform Analysis: Employ 'make verdi' to open and inspect the waveform.

This setup allows for comparative analysis between the distributed simulation approach (multi_simv) and the traditional single-instance method (reference).

