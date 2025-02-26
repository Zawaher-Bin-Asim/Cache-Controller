// Author       : Zawaher Bin Asim  , UET Lahore 
// Description  : Controller of the data cache
// Date         : 13 Aug 2024 

`include "../define/cache_defs.svh"

module dcahche_controller  (

    input   logic       clk,reset,    
    //Inputs from the  processor 
    input   logic       ld_req,st_req,                  //load_store_request from the processor  ( they are acting as  valid signal)
    input   logic       dcache_flush,                   // flush the cache
    input   logic       pro_ready,                      // signal tell processor is ready to take output

    // Inputs from datapath to controller
    input   logic       dcache_hit_i,                   // hit on the cache
    input   logic       dcache_miss_i,                  // miss on the cache
    input   logic       dcache_dirty_i,                 // dirty bit
    input   logic       dcache_flush_done_i,            // signals that flushing has been done
    
    // Output from the controller to datapath
    output  logic       cache_wr_o,cache_rd_o,          // cache_read and the cache_wr request
    output  logic       cache_line_wr_o,                //  write signal to write in the cache line
    output  logic       mem_wrb_addr_o,                 // adrress selection in case of write back or the from where the data is brought in case of miss
    output  logic       dcache_flush_o,                 // flush signal for cache flushing 
    output  logic       flush_index_next_o,             // go to the next index for flushing in case it is not dirty
    output  logic       reserve_o,                      // reserver signal for storing the address and the data for the ld/st req


    // Output from the controller to processor
    output  logic       dcache2pro_ack,                 // when the hit occures (act as valid signal from the cache to processor)
    output  logic       dcache_ready,                   // ready signal that shows the cache is ready for the input
    
    // Output  from controller to the main memory     
    output  logic       dcache2mem_req,                 // when the the data and address transfer to main mem in case of the miss + dirty 
    output  logic       mem_wrb_req,                    // write in the main memory in case of the write back
    // Input from main memory to controller
    input   logic       mem2cache_ack                   // when data written to mem or when data is taken from the mem

    
);

// variables to store the operation
logic ld_reserve_req,st_reserve_req,dcache_flush_reserve;


dcache_states_e        c_state,n_state;


always_ff @( posedge clk or negedge reset ) begin 
    if (!reset)begin
        ld_reserve_req          <= 1'b0;
        st_reserve_req          <= 1'b0;
        dcache_flush_reserve    <= 1'b0;
    end
    else if (reserve_o) begin
        ld_reserve_req          <= ld_req;
        st_reserve_req          <= st_req;
        dcache_flush_reserve    <= dcache_flush;        
    end
    else begin
        ld_reserve_req          <= ld_reserve_req;
        st_reserve_req          <= st_reserve_req;
        dcache_flush_reserve    <= dcache_flush_reserve;
    end
    
end
//Controller Register
always_ff @(posedge clk or negedge reset)begin
    
    if (!reset)begin
        c_state      <= DCACHE_IDLE;
        
    end
    else begin
        c_state <= n_state;
    end 

end
    

// Next state always_comb block
always_comb begin
    case (c_state)
        DCACHE_IDLE: begin
            if (ld_req || st_req) begin
                n_state = DCACHE_PROCESS;
            end else if (dcache_flush) begin
                n_state = DCACHE_FLUSH;
            end else begin
                n_state = DCACHE_IDLE;
            end
        end

        DCACHE_PROCESS: begin
            if (dcache_hit_i) begin
                if (pro_ready)begin
                    n_state = DCACHE_IDLE;
                end
                else begin
                    n_state = WAIT_READY;
                end

            end else if (dcache_miss_i) begin
                if (dcache_dirty_i) begin
                    n_state = DCACHE_WRITE_BACK;
                end else begin
                    n_state = DCACHE_ALLOCATE;
                end
            end else begin
                n_state = DCACHE_PROCESS;
            end
        end

        DCACHE_ALLOCATE: begin
            if (mem2cache_ack) begin
                n_state = DCACHE_PROCESS;
            end else begin
                n_state = DCACHE_ALLOCATE;
            end
        end

        DCACHE_WRITE_BACK: begin
            if (mem2cache_ack) begin
                if (dcache_flush_reserve) begin
                    n_state = DCACHE_FLUSH;
                end else begin
                    n_state = DCACHE_ALLOCATE;
                end
            end else begin
                n_state = DCACHE_WRITE_BACK;
            end
        end

        DCACHE_FLUSH : begin
            if (dcache_flush_done_i) begin
                if (pro_ready)begin
                    n_state = DCACHE_IDLE;
                end
                else begin
                    n_state = WAIT_READY;
                end
            end else begin
                if (dcache_dirty_i) begin
                    n_state = DCACHE_WRITE_BACK;
                end else begin
                    n_state = DCACHE_FLUSH;
                end
            end
        end

        WAIT_READY : begin
            if (pro_ready)begin
                n_state  = DCACHE_IDLE;
            end
            else n_state = WAIT_READY;
           
        end

        default: n_state = DCACHE_IDLE;
    endcase
end


// Output always block 

always_comb begin 

    cache_wr_o          = 0;
    cache_rd_o          = 0;      
    dcache_flush_o      = 0;             
    cache_line_wr_o     = 0;          
    mem_wrb_addr_o      = 0;            
    dcache2pro_ack      = 0;            
    dcache2mem_req      = 0;             
    mem_wrb_req         = 0;           
    flush_index_next_o  = 0;
    reserve_o           = 0;
    dcache_ready        = 0;

    case (c_state)
        
        DCACHE_IDLE : begin
            if (dcache_flush)begin
                dcache_flush_o = 1'b1;
                dcache_ready   = 1'b1;
                reserve_o      = 1'b1;
            end
            else if (ld_req || st_req) begin
                reserve_o      = 1'b1;
                dcache_ready   = 1'b1;
            end
            else begin
                dcache_ready   = 1'b1;
            end                
        end 

        DCACHE_PROCESS : begin
            if (dcache_hit_i)begin
                if (ld_reserve_req)begin
                    cache_rd_o     = 1'b1;
                    dcache2pro_ack = 1'b1;

                end
                else if (st_reserve_req)begin
                    cache_wr_o     = 1'b1;
                    dcache2pro_ack = 1'b1;
                end
            end
            else if (dcache_miss_i)begin
                if (dcache_dirty_i)begin
                    dcache2mem_req = 1'b1;
                    mem_wrb_req    = 1'b1;
                    mem_wrb_addr_o = 1'b1;
                end
                else begin
                    dcache2mem_req = 1'b1;
                end
            end
        end

        DCACHE_ALLOCATE : begin
            if (mem2cache_ack)begin
                cache_line_wr_o  = 1'b1;
            end
            else begin
                dcache2mem_req = 1'b1;
            end
        end 

        DCACHE_WRITE_BACK : begin
            if (mem2cache_ack)begin
                if (dcache_flush_reserve)begin
                    flush_index_next_o = 1'b1;
                    dcache_flush_o     = 1'b1;
                end
                else begin
                    dcache2mem_req = 1'b1;    
                end
            end
            else begin
                dcache2mem_req = 1'b1;
                mem_wrb_req    = 1'b1;
                mem_wrb_addr_o = 1'b1;


            end
        end

        DCACHE_FLUSH : begin
            if (dcache_flush_done_i)begin
                dcache2pro_ack = 1'b1;
            end
            else begin            
                if (dcache_dirty_i)begin
                    
                    dcache2mem_req = 1'b1;
                    mem_wrb_req    = 1'b1;
                   
                end
                else begin

                    flush_index_next_o = 1'b1;
                    dcache_flush_o     = 1'b1;

                end
            end
        end

        WAIT_READY : begin
            if (pro_ready)begin
                dcache2pro_ack = 1'b1;
            end
            else begin
                dcache2pro_ack = 1'b1;
            end
        end


        default: begin
                cache_wr_o          = 0;
                cache_rd_o          = 0;      
                dcache_flush_o      = 0;             
                cache_line_wr_o     = 0;          
                mem_wrb_addr_o      = 0;            
                dcache2pro_ack      = 0;            
                dcache2mem_req      = 0;             
                mem_wrb_req         = 0;           
                flush_index_next_o  = 0;
                dcache_ready        = 0;
        end       
    endcase
    
end

endmodule



