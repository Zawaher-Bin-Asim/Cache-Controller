// Author       : Zawaher Bin Asim  , UET Lahore 
// Description  : Defines and the parameters of the data cache
// Date         : 13 Aug 2024 

`ifndef cache_defs
`define cache_defs

// Width of main registers and buses
`define XLEN    32
`define DCACHE_SETS 1024


parameter DCACHE_ADDR_WIDTH = `XLEN;
parameter DCACHE_DATA_WIDTH = `XLEN;
parameter DCACHE_NO_OF_SETS  = `DCACHE_SETS; // 1024;
parameter DCACHE_LINE_WIDTH  = 32 ;  // In bits
parameter DCACHE_OFFSET_BITS = $clog2(DCACHE_LINE_WIDTH / 8);
parameter DCACHE_IDX_BITS    = $clog2(DCACHE_NO_OF_SETS); 
parameter DCACHE_TAG_BITS    = DCACHE_ADDR_WIDTH - DCACHE_IDX_BITS - DCACHE_OFFSET_BITS; 


typedef struct packed {
    logic  [DCACHE_TAG_BITS-1:0] tag_bits;
    logic  [DCACHE_IDX_BITS-1:0] index_bits;
    logic                        valid_bit, dirty_bit;

} type_pro2dcache_bits;

typedef enum logic [2:0]{ 

    DCACHE_IDLE,
    DCACHE_PROCESS,
    DCACHE_ALLOCATE,
    DCACHE_WRITE_BACK,
    DCACHE_FLUSH,
    WAIT_READY
    
 } dcache_states_e;

`endif 


