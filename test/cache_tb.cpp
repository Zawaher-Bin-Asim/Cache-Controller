#include <cstdlib>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include <Vcache_tb.h>

#define MAX_SIM_TIME 20

vluint64_t sim_time = 0;

int main(int argc, char **argv) {

    const int array_size = 1000000;

    Verilated::commandArgs(argc, argv);

    // Instantiate the signed multiplier module in C++
    Vcache_tb* dut = new Vcache_tb;

    // Tracing the Verilated output
    Verilated::traceEverOn(true);

    // Create the "m_trace" object and pass it to dut, 10 is the depth of the hierarchy
    VerilatedVcdC* m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 99);
    m_trace->open("waveform.vcd");

    

    for (int i = 0; i < array_size; i++) {
        vluint64_t max_sim_time = sim_time + MAX_SIM_TIME;

        while (!Verilated::gotFinish() && sim_time < max_sim_time) {

            dut->clk ^= 1;
            // Evaluate the design
            dut->eval();
            // Dump signals into VCD file
            m_trace->dump(sim_time);
            // Increment simulation time
            sim_time++;
        }
    }

    // Closing the tracing of signals
    m_trace->close();

    // Deleting the dut
    delete dut;

    // Exiting the simulation
    return EXIT_SUCCESS;
}
