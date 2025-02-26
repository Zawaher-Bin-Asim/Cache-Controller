// Author       : Zawaher Bin Asim  , UET Lahore 
// Description  : Datapath of the data cache
// Date         : 13 Aug 2024 


`include "../define/cache_defs.svh"


module dcache_datapath (

    // Inputs from controller to the datapath
    input   logic                           clk , reset,
    input   logic                           cache_wr_i,cache_rd_i,              // read and write request from the controller
    input   logic                           dcache_flush_i,                     // flush the dcache 
    input   logic                           cache_line_wr_i,                    // write the cache with the data from the main memory
    input   logic                           mem_wrb_addr_i,                     // adrress selection in case of write back or the from where the data is brought in case of miss 
    input   logic                           flush_index_next_i,                 // increment the flushing index in case of previous index is not dirty and returning adter write back in case of flush
    input   logic                           reserve_i,                          // reserve signal to reserve the address and the data from the processor on ld / st req
    input  logic                            dcache2pro_ack,                     // when the hit occures (act as valid signal from the cache to processor)
    // Outputs from datapath to controller
    output  logic                           dcache_hit_o,dcache_miss_o,         // hit and miss signals 
    output  logic                           dcache_dirty_o,                     // dirty_bit 
    output  logic                           dcache_flush_done_o,                // dcache flushing is done signal from datapath to controller

    // Inputs  from processor to th data cache and outputs from dcache to processor
    input   logic   [DCACHE_ADDR_WIDTH-1:0] pro2dcache_addr,
    input   logic   [DCACHE_DATA_WIDTH-1:0] pro2dcache_data,
    output  logic   [DCACHE_DATA_WIDTH-1:0] dcache2pro_data,
    input   logic                           pro_ready,                            // tells that processor is ready to take output

    // Inputs and outputs  between dcache and the main memeory
    input   logic   [DCACHE_DATA_WIDTH-1:0] mem2dcache_data, 
    output  logic   [DCACHE_ADDR_WIDTH-1:0] dcache2mem_addr,
    output  logic   [DCACHE_DATA_WIDTH-1:0] dcache2mem_data


);

// bits  of the address
type_pro2dcache_bits    pro2dcache_bits;

// Flushing index to track that which index is flushed
logic [DCACHE_IDX_BITS-1:0] flush_index;

// Array for the tag bits that conatins the tag for each index  of the cache
logic [DCACHE_TAG_BITS-1:0]dcache_tag_bits[`DCACHE_SETS-1:0];

// Array for the data bits that conatins the dat for each index  of the cache
logic [DCACHE_DATA_WIDTH-1:0]dcache_data_bits[`DCACHE_SETS-1:0];

// Array for the valid bit that contains the valid bit corresponding to each index
logic  dcache_valid_bit[`DCACHE_SETS-1:0];

// Array for the dirty bit that contains the dirty bit corresponding to each index
logic  dcache_dirty_bit[`DCACHE_SETS-1:0];


// reserve variables for the address and the data frm the processor
logic   [DCACHE_ADDR_WIDTH-1:0] pro2dcache_reserve_addr;
logic   [DCACHE_DATA_WIDTH-1:0] pro2dcache_reserve_data;

always_ff @( posedge clk or negedge reset  ) begin  
    if (!reset) begin

        pro2dcache_reserve_addr <= 'h0;
        pro2dcache_reserve_data <= 'h0;
        
    end
    else if (reserve_i)begin
        pro2dcache_reserve_addr <= pro2dcache_addr;
        pro2dcache_reserve_data <= pro2dcache_data;
    end
    else begin
        pro2dcache_reserve_addr <= pro2dcache_reserve_addr;
        pro2dcache_reserve_data <= pro2dcache_reserve_data;
    end

end

assign pro2dcache_bits.tag_bits   = pro2dcache_reserve_addr[DCACHE_ADDR_WIDTH-1:DCACHE_IDX_BITS + DCACHE_OFFSET_BITS];
assign pro2dcache_bits.index_bits = pro2dcache_reserve_addr[DCACHE_IDX_BITS + DCACHE_OFFSET_BITS - 1:DCACHE_OFFSET_BITS];
assign pro2dcache_bits.valid_bit  = dcache_valid_bit[pro2dcache_bits.index_bits];
assign pro2dcache_bits.dirty_bit  = dcache_dirty_bit[pro2dcache_bits.index_bits];

// check the matching of tag bits and valid bit then based on that hit or miss signal
always_comb begin 
    // Default Vales
    dcache_hit_o  = 1'b0;
    dcache_miss_o = 1'b0;
     
    if ((pro2dcache_bits.tag_bits == dcache_tag_bits[pro2dcache_bits.index_bits]) && (pro2dcache_bits.valid_bit))begin
            
            dcache_hit_o    = 1'b1;
    end
    else begin
        // If we miss the cache then check the dirty bit is 1 then we have to write back to main memory first then get the new data loaded from main memory            
        if (pro2dcache_bits.dirty_bit && (pro2dcache_bits.valid_bit))begin
                
                dcache_miss_o   =  1'b1;
                dcache_dirty_o  =  1'b1;
                dcache2mem_data =  dcache_data_bits[pro2dcache_bits.index_bits];
        end
        else if (dcache_flush_i && dcache_dirty_bit[flush_index] == 1'b1)begin
                dcache_dirty_o  = 1'b1;
                dcache2mem_data = dcache_data_bits[flush_index];
        end        
      
        else begin
                // If the dirty is zero then we will just get the data from the main mem corresponding to the address that don't match in the cache 

                dcache_miss_o   =  1'b1;
                dcache_dirty_o  =  1'b0;                
                
      end
    end

end
 



// MEMORY address to which write back is to be performed or from which the data is brought in case of miss 
always_comb begin
    if (mem_wrb_addr_i) begin

        dcache2mem_addr =  {{{DCACHE_TAG_BITS}{dcache_tag_bits[pro2dcache_bits.index_bits]}}, {{DCACHE_IDX_BITS}{pro2dcache_bits.index_bits}}, {{DCACHE_OFFSET_BITS}{1'b0}}};
   
    end
    else if (dcache_flush_i && dcache_dirty_bit[flush_index] == 1'b1)begin

        dcache2mem_addr = {{{DCACHE_TAG_BITS}{dcache_tag_bits[flush_index]}}, {{DCACHE_IDX_BITS}{flush_index}}, {{DCACHE_OFFSET_BITS}{1'b0}}};
    end
    else begin
        
        dcache2mem_addr =  pro2dcache_reserve_addr;
    end
end

// READ the data from cache
// Writing the cache in case of the data from the main memory (in case of miss) and the data from the processor
// Check if the tag matches and the valid is one 
// It doesnot matter id the dirty is one or the zero because  in both cases we set the dirty bit and replace the data
always_comb begin 

    if (cache_rd_i)begin                 
        if ((dcache2pro_ack && pro_ready) || (dcache2pro_ack && ~pro_ready))begin

            dcache2pro_data = dcache_data_bits[pro2dcache_bits.index_bits];    
        end
        else begin
            dcache2pro_data = 'h0; 
        end
       
    end

    else if (cache_wr_i)begin
            
        dcache_data_bits[pro2dcache_bits.index_bits] = pro2dcache_reserve_data;
        dcache_dirty_bit[pro2dcache_bits.index_bits] = 1'b1;                // setting the dirty bit
        
        if ((dcache2pro_ack && pro_ready) || (dcache2pro_ack && ~pro_ready))begin

            dcache2pro_data = dcache_data_bits[pro2dcache_bits.index_bits];    
        end
        else begin
            dcache2pro_data = 'h0; 
        end

    end
    else begin

        if (cache_line_wr_i)begin
        
            // In case of cache write (data from the main memory) , we set the tag bits , valid_bit and make dirty bit 0 and set the data 
            dcache_tag_bits[pro2dcache_bits.index_bits]  = pro2dcache_bits.tag_bits;
            dcache_valid_bit[pro2dcache_bits.index_bits] = 1'b1;
            dcache_dirty_bit[pro2dcache_bits.index_bits] = 1'b0;
            dcache_data_bits[pro2dcache_bits.index_bits] = mem2dcache_data;

        end
        // In case the flush is :
        if (flush_index_next_i)begin
            dcache_dirty_bit[flush_index] = 1'b0;
            dcache_valid_bit[flush_index] = 1'b0; 
        end

    end
        

end


// FLUSHING The CACHE
// CHECKING the dirty bit of each index and making valid 0 for the corresponding index 
// If dirty bit is 1 first write back to main memory then flush 

always_ff @( posedge clk or negedge reset ) begin 
    if (!reset) begin
        flush_index         <= 'h0;
        dcache_flush_done_o <= 1'b0;
    end else begin
        if (dcache_flush_i) begin
            if (flush_index == `DCACHE_SETS-1) begin
                flush_index         <= 'h0;
                dcache_flush_done_o <= 1'b1;
            end else begin 
                if (flush_index_next_i) begin
                    flush_index <= flush_index + 1; 
                end else begin 
                    flush_index <= flush_index; // flush index will retain its previous value
                end
            end
        end
    end
end





endmodule