// Author       : Zawaher Bin Asim  , UET Lahore 
// Description  : data cache main 
// Date         : 15 Aug 2024 


`include "../define/cache_defs.svh"

module dcache (

    input   logic                           clk,reset,

    // Inputs from processor to cache
    input   logic                           ld_req,st_req,                  //load_store_request from the processor
    input   logic                           dcache_flush,                   // flush the cache
    input   logic   [DCACHE_ADDR_WIDTH-1:0] pro2dcache_addr,
    input   logic   [DCACHE_DATA_WIDTH-1:0] pro2dcache_data,
    input   logic                           pro_ready,                     // signal tell processor is ready to take output


    // Outputs from cache to processor
    output  logic                           dcache2pro_ack,               // when the hit occures
    output  logic   [DCACHE_DATA_WIDTH-1:0] dcache2pro_data,
    output  logic                           dcache_ready,                 // ready signal that shows the cache is ready for the input

    // Inputs from  memory to cache
    input   logic                           mem2cache_ack,                // when data written to mem or when data is taken from the mem
    input   logic   [DCACHE_DATA_WIDTH-1:0] mem2dcache_data,

    // Outputs from cache to memory
    output  logic                           dcache2mem_req,               // when the the data and address transfer to main mem in case of the miss + dirty 
    output  logic                           mem_wrb_req,                  // write in the main memory in case of the write back
    output  logic   [DCACHE_ADDR_WIDTH-1:0] dcache2mem_addr,
    output  logic   [DCACHE_DATA_WIDTH-1:0] dcache2mem_data
    
);

 // Output from the controller to datapath ===> inputs to datapath
  logic       cache_wr_o,cache_rd_o;                                    // cache_read and the cache_wr request
  logic       cache_line_wr_o;                                          //  write signal to write in the cache line
  logic       mem_wrb_addr_o;                                           // adrress selection in case of write back or the from where the data is brought in case of miss
  logic       dcache_flush_o;                                           // flush signal for cache flushing 
  logic       flush_index_next_o;                                       // go to the next index for flushing in case it is not dirty
  logic       reserve_o;                                                // reserver signal for storing the address and the data for the ld/st req
// Outputs from datapath to controller ======> inputs to controller
  logic       dcache_hit_o,dcache_miss_o;                               // hit and miss signals 
  logic       dcache_dirty_o;                                           // dirty_bit 
  logic       dcache_flush_done_o;                                      // dcache flushing is done signal from datapath to controller


dcache_datapath DCACHE_DP (

    // Inputs from controller to the datapath
    .clk(clk) , .reset(reset),
    .cache_wr_i(cache_wr_o),
    .cache_rd_i(cache_rd_o),             
    .dcache_flush_i(dcache_flush_o),                    
    .cache_line_wr_i(cache_line_wr_o),                  
    .mem_wrb_addr_i(mem_wrb_addr_o),                     
    .flush_index_next_i(flush_index_next_o),
    .reserve_i(reserve_o),
    .dcache2pro_ack(dcache2pro_ack),             

    // Outputs from datapath to controller
    .dcache_hit_o(dcache_hit_o),
    .dcache_miss_o(dcache_miss_o),      
    .dcache_dirty_o(dcache_dirty_o),                   
    .dcache_flush_done_o(dcache_flush_done_o),        

    // Inputs  from processor to th data cache and outputs from dcache to processor
    .pro2dcache_addr(pro2dcache_addr),
    .pro2dcache_data(pro2dcache_data),
    .dcache2pro_data(dcache2pro_data),
    .pro_ready(pro_ready),

    // Inputs and outputs  between dcache and the main memeory
    .mem2dcache_data(mem2dcache_data), 
    .dcache2mem_addr(dcache2mem_addr),
    .dcache2mem_data(dcache2mem_data)


);

dcahche_controller DCACHE_CT (

    .clk(clk),.reset(reset),
    
    //Inputs from the  processor 
    .ld_req(ld_req),
    .st_req(st_req),               
    .dcache_flush(dcache_flush),
    .pro_ready(pro_ready),   
    
    // Inputs from datapath to controller
    .dcache_hit_i(dcache_hit_o),               
    .dcache_miss_i(dcache_miss_o),              
    .dcache_dirty_i(dcache_dirty_o),             
    .dcache_flush_done_i(dcache_flush_done_o),     
                 
    // Output from the controller to datapath
    .cache_wr_o(cache_wr_o),.cache_rd_o(cache_rd_o),    
    .cache_line_wr_o(cache_line_wr_o),            
    .mem_wrb_addr_o(mem_wrb_addr_o),             
    .dcache_flush_o(dcache_flush_o),              
    .flush_index_next_o(flush_index_next_o),
    .reserve_o(reserve_o),       

    // Output from the controller to processor
    .dcache2pro_ack(dcache2pro_ack),
    .dcache_ready(dcache_ready),             

    // Output  from controller to the main memory     
    .dcache2mem_req(dcache2mem_req),              
    .mem_wrb_req(mem_wrb_req),                
    
    // Input from main memory to controller
    .mem2cache_ack(mem2cache_ack)             

    
);


    
endmodule