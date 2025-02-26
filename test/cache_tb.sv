// Author       : Zawaher Bin Asim  , UET Lahore 
// Description  : data cache test bench . It contain the main memory module to test the cache 
// Date         : 15 Aug 2024 


`include  "../define/cache_defs.svh"

interface mem_if;
    logic [DCACHE_DATA_WIDTH-1:0] memory_array [(2*`DCACHE_SETS)-1:0];
endinterface 

module cache_tb(
`ifdef Verilator
    input logic  clk
`endif 
);

localparam int MAX_ADDR = (2 * `DCACHE_SETS) - 1;

/**************************************************************************************************************************************************************
*                                                                                                                                                             *
*                                                           CACHE SIGNALS                                                                                     * 
*                                                                                                                                                             *
**************************************************************************************************************************************************************/

    // Declare the interface instance
    mem_if                          mem_if_inst();
    
    `ifndef Verilator
    reg                             clk;
    `endif 

    logic                           reset;

    // Inputs from processor to cache
    logic                           ld_req,st_req;                 //load_store_request from the processor
    logic                           dcache_flush;                  // flush the cache
    logic   [DCACHE_ADDR_WIDTH-1:0] pro2dcache_addr;
    logic   [DCACHE_DATA_WIDTH-1:0] pro2dcache_data;
    logic                           pro_ready;                     // signal tell processor is ready to take output


    // Outputs from cache to processor
    logic                           dcache2pro_ack;                // when the hit occures
    logic   [DCACHE_DATA_WIDTH-1:0] dcache2pro_data;
    logic                           dcache_ready;                  // ready signal that shows the cache is ready for the input

    // Inputs from  memory to cache
    logic                           mem2cache_ack;                 // when data written to mem or when data is taken from the mem
    logic   [DCACHE_DATA_WIDTH-1:0] mem2dcache_data;

    // Outputs from cache to memory
    logic                           dcache2mem_req;                // when the the data and address transfer to main mem in case of the miss + dirty 
    logic                           mem_wrb_req;                   // write in the main memory in case of the write back
    logic   [DCACHE_ADDR_WIDTH-1:0] dcache2mem_addr;
    logic   [DCACHE_DATA_WIDTH-1:0] dcache2mem_data;
   
/**************************************************************************************************************************************************************
*                                                                                                                                                             *
*                                                           AXI SIGNALS                                                                                       * 
*                                                                                                                                                             *
**************************************************************************************************************************************************************/

// Inputs from the master to axi
    logic   read;                       // this signals tells that the address coming from the cache is valid for the read  
    logic   write;                      // signal tells to write back in the mem and the data that is comming is valid for the write

    // Inputs from the Slave
    // for read
    logic   s_arready;                  // tells that slave is ready to take read address
    logic   s_rvalid;                   // tells that slave has outputed that valid data
    // for write
    logic   s_awready;                  // tells that slave is ready to take write address
    logic   s_wready;                   // tells that slave is ready to take write data
    logic   s_bvalid;                   // tells that slave has  written the data to main memeory    
    //  Output from the Axi 
    // In case of read
    logic   m_arvalid;                  // tells that the read address is valid 
    logic   m_rready;                   // tells that the master is ready to  take data
    // In case of write
    logic   m_awvalid;                  // tells that write address is valid
    logic   m_wvalid;                   // tells that write data is valid
    logic   m_bready;                   // tells that master is ready to take the write response         

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

logic [DCACHE_DATA_WIDTH-1:0] dummy_memory [(2*`DCACHE_SETS)-1:0];

dcache  DCACHE(

    .clk(clk),.reset(reset),

    // Inputs from processor to cache
    .ld_req(ld_req),.st_req(st_req),          
    .dcache_flush(dcache_flush),         
    .pro2dcache_addr(pro2dcache_addr),
    .pro2dcache_data(pro2dcache_data),
    .pro_ready(pro_ready),

    // Outputs from cache to processor
    .dcache2pro_ack(dcache2pro_ack),     
    .dcache2pro_data(dcache2pro_data),
    .dcache_ready(dcache_ready),

    // Inputs from  memory to cache
    .mem2cache_ack(mem2cache_ack),       
    .mem2dcache_data(mem2dcache_data),

    // Outputs from cache to memory
    .dcache2mem_req(dcache2mem_req),      
    .mem_wrb_req(mem_wrb_req),         
    .dcache2mem_addr(dcache2mem_addr),
    .dcache2mem_data(dcache2mem_data)
    
);

assign read  = dcache2mem_req && ~mem_wrb_req;
assign write = dcache2mem_req && mem_wrb_req;
assign mem2cache_ack = s_bvalid || s_rvalid;

axi_lite AXI_LITE(
    
    .clk(clk),.reset(reset),
    
    // Inputs from the master to axi
    .read(read),                     
    .write(write),                  

    // Inputs from the Slave
    // for read
    .s_arready(s_arready),           
    .s_rvalid(s_rvalid),             
    // for write
    .s_awready(s_awready),           
    .s_wready(s_wready),         
    .s_bvalid(s_bvalid),    

    //  Output from the Axi 
    // In case of read
    .m_arvalid(m_arvalid),          
    .m_rready(m_rready),           
    // In case of write
    .m_awvalid(m_awvalid),         
    .m_wvalid(m_wvalid),           
    .m_bready(m_bready)                   

);

main_mem MAIN_MEMORY(
    
    .clk(clk), .reset(reset),
    // Data and Address from the cache 
    .dcache2mem_data(dcache2mem_data),
    .dcache2mem_addr(dcache2mem_addr),
    
    // Inputs from the AXI =======> Outputs to the AXI
    // for read
    .s_arready(s_arready),                  // tells that slave is ready to take read address
    .s_rvalid(s_rvalid),                   // tells that slave has outputted valid data
    // for write
    .s_awready(s_awready),                  // tells that slave is ready to take write address
    .s_wready(s_wready),                   // tells that slave is ready to take write data
    .s_bvalid(s_bvalid),                   // tells that slave has written the data to main memory

    //  Outputs from the AXI ======> Inputs to main memory 
    // In case of read
    .m_arvalid(m_arvalid),                  // tells that the read address is valid 
    .m_rready(m_rready),                   // tells that the master is ready to take data
    // In case of write
    .m_awvalid(m_awvalid),                  // tells that write address is valid
    .m_wvalid(m_wvalid),                   // tells that write data is valid
    .m_bready(m_bready),                   // tells that master is ready to take the write response         

    // Outputs of the memory module to cache
    .mem2dcache_data(mem2dcache_data),
    
    .mem_if(mem_if_inst)  
);    
    
`ifndef Verilator
    initial begin
    // Clock generation
        clk <= 0;
        forever #5 clk <= ~clk;
    end
`endif 


 // Main test sequence
    initial begin
        
        init_signals();
// Perform reset
        reset_sequence();
        @(posedge clk);
        
        for (int i = 0 ; i < (2*`DCACHE_SETS); i++ )begin
            dummy_memory[i] = mem_if_inst.memory_array [i];
        end
            
        @(posedge clk);    

        // Randomly select and execute fork-join blocks
        repeat (10) begin
            select_random_fork_join();
        end


    $finish;
    end


    // Initialize signals
    task init_signals();
        ld_req          <= 0;
        st_req          <= 0;
        dcache_flush    <= 0;
        pro2dcache_addr <= 0;
        pro2dcache_data <= 0;
        pro_ready       <= 0;
    endtask 

    // Reset task
    task reset_sequence();
        begin
            reset <= 1;
            @(posedge clk);
            reset <= 0;
            @(posedge clk);
            reset <= 1;
        end
    endtask



// Task to flush the cache
    task flush_cache();
        begin
            dcache_flush <= 1;
            @(posedge clk);
            dcache_flush <= 0;
            @(posedge clk);
        end
    endtask

    task  pro_ready_for_flush();
        @(posedge clk);
        pro_ready <= 1'b1;
        while (!dcache2pro_ack)begin
            @(posedge clk);
        end
        pro_ready <= 1'b0;
        repeat(1) @(posedge clk);
    endtask 

    
    task driver();
        logic [DCACHE_ADDR_WIDTH-1:0] addr;
        logic [DCACHE_DATA_WIDTH-1:0] data;
        logic operation; // 0 for read, 1 for write
        logic [DCACHE_ADDR_WIDTH-1:0] masked_addr;

        begin
            // Randomly select the operation (0 = read, 1 = write)
            operation = $urandom_range(0, 1);

            // Randomly generate address and data within valid range
            addr = $urandom;
            data = $urandom;

            // Check if the address exceeds the valid range
            if (addr > MAX_ADDR) begin
                $display("Address 0x%h is greater than the valid range 0x%h.", addr, MAX_ADDR);
                masked_addr = addr % (2 * `DCACHE_SETS);  // Mask the address
                $display("Masking address to 0x%h.", masked_addr);
            end else begin
                masked_addr = addr;
            end

            if (operation == 0) begin
                // Perform a read operation
                ld_req <= 1;
                pro2dcache_addr <= masked_addr;
                @(posedge clk);
                while (!dcache_ready) begin
                    @(posedge clk);
                end
                ld_req <= 0;
                repeat ($urandom_range(0, 2)) @(posedge clk);
            end else begin
                // Perform a write operation
                st_req <= 1;
                pro2dcache_addr <= masked_addr;
                pro2dcache_data <= data;
                dummy_memory[masked_addr] <= data; // Update the dummy memory
                @(posedge clk);
                while (!dcache_ready) begin
                    @(posedge clk);
                end
                st_req <= 0;
                repeat ($urandom_range(0, 2)) @(posedge clk);
            end
        end
    endtask

 
    task monitor();
        logic [DCACHE_DATA_WIDTH-1:0] expected_data ;
        
        
        begin
            // Wait for a cache request to start
            @(posedge clk);
            pro_ready <= 1'b1;
            
            expected_data <= dummy_memory[pro2dcache_addr];

            @(posedge clk);

            // Wait for cache acknowledgment
            while (!dcache2pro_ack) begin
                @(posedge clk);
            end
            
            // Compare the cache output with the dummy memory
            if (dcache2pro_data === expected_data) begin
                $display ("=====================Test Passed=======================");
                $display("Output : %d", dcache2pro_data);
            end
            else begin
                $display("======================Test Failed=======================");
                $display("Expected_Data : %d   |  Actual_Data : %d ", expected_data, dcache2pro_data);    
            end
            pro_ready <= 1'b0;
            repeat(1) @(posedge clk);
        end
    endtask


    task select_random_fork_join();
        int rand_choice;

        begin
            rand_choice = $urandom_range(0, 2); // Randomly select between 0 and 2
            
            case (rand_choice)
                0: begin
                    // Execute driver and monitor
                    fork
                        driver();
                        monitor();
                    join
                end

                1: begin
                    // Execute flush_cache and pro_ready_for_flush
                    fork
                        flush_cache();
                        pro_ready_for_flush();
                    join
                end

                2: begin
                    // Execute driver and monitor again
                    fork
                        driver();
                        monitor();
                    join
                end

                default: begin
                    // Fallback case, should not be reached
                    $display("Unexpected case in select_random_fork_join.");
                end
            endcase
        end
    endtask


endmodule


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module main_mem (

    input   logic                           clk, reset,
    // Data and Address from the cache 
    input   logic   [DCACHE_DATA_WIDTH-1:0] dcache2mem_data,
    input   logic   [DCACHE_ADDR_WIDTH-1:0] dcache2mem_addr,
    
    // Inputs from the AXI =======> Outputs to the AXI
    // for read
    output  logic   s_arready,                  // tells that slave is ready to take read address
    output  logic   s_rvalid,                   // tells that slave has outputted valid data
    // for write
    output  logic   s_awready,                  // tells that slave is ready to take write address
    output  logic   s_wready,                   // tells that slave is ready to take write data
    output  logic   s_bvalid,                   // tells that slave has written the data to main memory

    //  Outputs from the AXI ======> Inputs to main memory 
    // In case of read
    input  logic   m_arvalid,                  // tells that the read address is valid 
    input  logic   m_rready,                   // tells that the master is ready to take data
    // In case of write
    input  logic   m_awvalid,                  // tells that write address is valid
    input  logic   m_wvalid,                   // tells that write data is valid
    input  logic   m_bready,                   // tells that master is ready to take the write response         

    // Outputs of the memory module to cache
    output  logic   [DCACHE_DATA_WIDTH-1:0] mem2dcache_data,
    
    mem_if          mem_if // Interface instance
);

always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
        // Initialize memory to  with some  random pattern if needed
        integer i;
        for (i = 0; i < (2*`DCACHE_SETS); i++) begin
            mem_if.memory_array[i] <= $random;
        end
        
        // Initialize ready signals to 1
        s_arready <= 1'b1;
        s_rvalid  <= 1'b0;
        s_awready <= 1'b1;
        s_wready  <= 1'b1;
        s_bvalid  <= 1'b0;
    end else begin

        s_arready <= 1'b1;
        s_awready <= 1'b1;
        s_wready  <= 1'b1;

        // Handle read address ready
        if (m_arvalid && !s_arready) begin
            s_arready <= 1'b1;
        end
        
        
        // Handle read data valid
        if (m_arvalid && m_rready && s_arready) begin
            s_rvalid <= 1'b1;
            mem2dcache_data <= mem_if.memory_array[dcache2mem_addr];
            s_arready <= 1'b0;
        end else begin
            s_rvalid <= 1'b0;
        end

        // Handle write  ready
        if (m_awvalid && m_wvalid && (!s_awready | !s_wready)) begin
            s_awready <= 1'b1;
            s_wready <= 1'b1;
        end
        
        
        // Handle write response valid
        if (s_wready && s_awready && m_bready && m_awvalid && m_wvalid) begin
            s_bvalid  <= 1'b1;
            mem_if.memory_array[dcache2mem_addr] <= dcache2mem_data;
            s_awready <= 1'b0;
            s_wready  <= 1'b0;
        end else begin
            s_bvalid <= 1'b0;
        end
    end
end


endmodule
