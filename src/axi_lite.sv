// Author       : Zawaher Bin Asim  , UET Lahore 
// Description  : the file contains the controller for the axi_4_lite  
// Date         : 20 Aug 2024 

module axi_lite (
    
    input   logic   clk,reset,
    
    // Inputs from the master to axi
    input   logic   read,                       // this signals tells that the address coming from the cache is valid for the read  
    input   logic   write,                      // signal tells to write back in the mem and the data that is comming is valid for the write

    // Inputs from the Slave
    // for read
    input   logic   s_arready,                  // tells that slave is ready to take read address
    input   logic   s_rvalid,                   // tells that slave has outputed that valid data
    // for writene takes a
    input   logic   s_awready,                  // tells that slave is ready to take write address
    input   logic   s_wready,                   // tells that slave is ready to take write data
    input   logic   s_bvalid,                   // tells that slave has  written the data to main memeory    
    //  Output from the Axi 
    // In case of read
    output  logic   m_arvalid,                  // tells that the read address is valid 
    output  logic   m_rready,                   // tells that the master is ready to  take data
    // In case of write
    output  logic   m_awvalid,                  // tells that write address is valid
    output  logic   m_wvalid,                   // tells that write data is valid
    output  logic   m_bready                   // tells that master is ready to take the write response         
 
);


typedef enum logic[2:0] {
    IDLE,
    WAIT_READ_READY,
    WAIT_S_RVALID,
    WAIT_WRITE_READY,
    WAIT_WRITE_ADDR_READY,
    WAIT_WRITE_DATA_READY,
    WAIT_S_BVALID
} states_e;

states_e    c_state,n_state;

always_ff @( posedge clk or negedge reset ) begin 
    if (!reset)begin
        c_state <= IDLE;
    end
    else begin
        c_state <= n_state;
    end 
    
end

// Next state always block
always_comb begin 
    case (c_state)
        IDLE    : begin
            if (read && ~s_arready)begin
                n_state = WAIT_READ_READY;
            end
            else if (read && s_arready) begin
                n_state = WAIT_S_RVALID;
            end      
            else if (write && ~s_awready && ~s_wready) begin
                n_state = WAIT_WRITE_READY;
            end 
            else if (write && ~s_awready)begin
                n_state = WAIT_WRITE_ADDR_READY;
            end
            else if (write && ~s_wready)begin
                n_state = WAIT_WRITE_DATA_READY;
            end
            else if (write && s_awready &&  s_wready)begin
                n_state = WAIT_S_BVALID;
            end
            else       n_state = IDLE;    
              
        end

        WAIT_READ_READY : begin
            if (s_arready) n_state = WAIT_S_RVALID;
            else           n_state = WAIT_READ_READY;
        end

        WAIT_WRITE_READY : begin
            if (s_wready && ~s_awready)begin
                n_state = WAIT_WRITE_ADDR_READY;
            end
            else if (s_awready && ~s_wready)begin
                n_state = WAIT_WRITE_DATA_READY;
            end
            else if(s_awready && s_wready)begin
                n_state = WAIT_S_BVALID;
            end
            else n_state = WAIT_WRITE_READY;
        end

        WAIT_WRITE_ADDR_READY : begin
            if (s_awready)begin
                n_state = WAIT_S_BVALID;
            end
            else n_state = WAIT_WRITE_ADDR_READY;
        end

        WAIT_WRITE_DATA_READY : begin
            if (s_wready)begin
                n_state = WAIT_S_BVALID;
            end
            else n_state = WAIT_WRITE_DATA_READY;
        end

        WAIT_S_RVALID : begin
            if (s_rvalid) n_state = IDLE;
            else          n_state = WAIT_S_RVALID; 
        end

        WAIT_S_BVALID : begin
            if (s_bvalid) n_state = IDLE;
            else          n_state = WAIT_S_BVALID;
        end 

        default: n_state = IDLE; 
endcase
    
end


// Output logic always block
always_comb begin 
    m_arvalid = 1'b0;      
    m_rready  = 1'b0;     
    m_awvalid = 1'b0;     
    m_wvalid  = 1'b0;     
    m_bready  = 1'b0;                      
                
    
    case (c_state)
        IDLE    : begin
            // Thes signals for all the cases of the read  and write remain same but the next  states are different so i am not writing the output signals for all cases 
            if (read)begin
                m_arvalid = 1'b1;
                m_rready  = 1'b1;
            end      
            else if (write) begin
                m_awvalid = 1'b1;
                m_wvalid  = 1'b1;
                m_bready  = 1'b1;
            end      
              
        end

        WAIT_READ_READY : begin
            if (s_arready) begin
                m_arvalid = 1'b1;
                m_rready  = 1'b1;        
            end
            else begin 
                m_arvalid = 1'b1;
                m_rready  = 1'b1;
            end     
        end

        WAIT_WRITE_READY : begin
            if (s_wready || s_awready)begin
                m_awvalid = 1'b1;
                m_wvalid  = 1'b1;
                m_bready  = 1'b1;
            end
            else begin
                m_awvalid = 1'b1;
                m_wvalid  = 1'b1;
                m_bready  = 1'b1;
            end
        end

        WAIT_WRITE_ADDR_READY : begin
            if (s_awready)begin
                m_awvalid = 1'b1;
                m_bready  = 1'b1;
            end
            else begin
                m_awvalid = 1'b1;
                m_bready  = 1'b1;
            end

        end

        WAIT_WRITE_DATA_READY : begin
            if (s_wready)begin
                m_wvalid  = 1'b1;
                m_bready  = 1'b1;
            end
            else begin
                m_wvalid  = 1'b1;
                m_bready  = 1'b1;                
            end
        end

        WAIT_S_RVALID : begin
            if (s_rvalid) begin
                m_rready  = 1'b1;
            end
            else begin
                m_rready  = 1'b1;
            end

        end

        WAIT_S_BVALID : begin
            if (s_bvalid) begin
                m_bready  = 1'b1;
            end 
            else begin
                m_bready  = 1'b1;
            end        
        end 

        default: begin
            m_arvalid = 1'b0;      
            m_rready  = 1'b0;     
            m_awvalid = 1'b0;     
            m_wvalid  = 1'b0;     
            m_bready  = 1'b0;                                
        end 
    endcase
    
end 


    
endmodule
