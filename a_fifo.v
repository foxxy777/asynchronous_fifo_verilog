`timescale 1ns/1ps

module a_fifo
  #(parameter    DATA_W    = 8,
                 ADDR_W = 4,
                 MEM_D    = (1 << ADDR_W))
     //Reading port
    (output reg  [DATA_W-1:0]        dout, 
     output reg                          empty,
     input wire                          rd,
     input wire                          rclk,        
     //Writing port.	 
     input wire  [DATA_W-1:0]        din,  
     output reg                          full,
     input wire                          wr,
     input wire                          wclk,
	 
output [ADDR_W-1:0]  NW_ptr_w,
output [ADDR_W-1:0]  NR_ptr_w,
output Almost_empty_w,
output Almost_full_w,

     input wire                          rst 
 );



    /////Internal connections & variables//////
    reg   [DATA_W-1:0]              Mem [MEM_D-1:0];
    wire  [ADDR_W-1:0]           NW_ptr, NR_ptr;
    wire                                Equal;
    wire                                Wr_en, Rd_en;
    wire                                Almost_full, Almost_empty;
    reg                                 Almost_what;
    wire                                Asyn_full, Asyn_empty;
    
 assign NR_ptr_w = NR_ptr;
 assign NW_ptr_w = NW_ptr;

    //////////////Code///////////////
    //Data ports logic:
    //(Uses a dual-port RAM).
    //'dout' logic:
    always @ (posedge rclk)
        if (rd & !empty)
            dout <= Mem[NR_ptr];
            
    //'din' logic:
    always @ (posedge wclk)
        if (wr & !full)
            Mem[NW_ptr] <= din;

    //Fifo addresses support logic: 
    //'Next Addresses' enable logic:
    assign Wr_en = wr & ~full;
    assign Rd_en  = rd  & ~empty;
           
    //Addreses (Gray counters) logic:
    GrayCounter GrayCounter_pWr
       (.graynum(NW_ptr),
        .en(Wr_en),
        .rst(rst),
        .clk(wclk)
       );
       
    GrayCounter GrayCounter_pRd
       (.graynum(NR_ptr),
        .en(Rd_en),
        .rst(rst),
        .clk(rclk)
       );
     

    //'Equal' logic:
    assign Equal = (NW_ptr == NR_ptr);

    //'Quadrant selectors' logic:
    assign Almost_full = (NW_ptr[ADDR_W-2] ~^ NR_ptr[ADDR_W-1]) &
                         (NW_ptr[ADDR_W-1] ^  NR_ptr[ADDR_W-2]);
                            
    assign Almost_empty = (NW_ptr[ADDR_W-2] ^  NR_ptr[ADDR_W-1]) &
                         (NW_ptr[ADDR_W-1] ~^ NR_ptr[ADDR_W-2]);

    assign Almost_empty_w = Almost_empty;
    assign Almost_full_w = Almost_full;

                         
    //'Almost' latch logic:
    always @ (Almost_full, Almost_empty, rst) begin //D Latch w/ Asynchronous Clear & Preset.
        if (Almost_empty | !rst)
            Almost_what = 0;  //Going 'Empty'.
        else if (Almost_full)
            Almost_what = 1;  //Going 'Full'.
    end
    
            
    //'full' logic for the writing port:
    assign Asyn_full = Almost_what & Equal;  //'Full' Fifo.
    ////assign Asyn_full = Almost_full & Equal;  //'Full' Fifo.
    
    //always @ (posedge wclk, posedge Asyn_full) begin //D Flip-Flop w/ Asynchronous Preset.
    always @ (posedge wclk) begin //D Flip-Flop w/ Asynchronous Preset.
        if (Asyn_full)
            full <= 1;
        else
            full <= 0;
    end     
    //'empty' logic for the reading port:
    assign Asyn_empty = ~Almost_what & Equal;  //'Empty' Fifo.
    ////assign Asyn_empty = (Almost_empty & Equal)|!rst;  //'Empty' Fifo.
    ////assign Asyn_empty = (Almost_empty|!rst) & Equal;  //'Empty' Fifo.
    
    //always @ (posedge rclk, posedge Asyn_empty) begin //D Flip-Flop w/ Asynchronous Preset.
    //这里posedge rclk是要的
    always @ (posedge rclk) begin //D Flip-Flop w/ Asynchronous Preset.
        if (Asyn_empty)
            empty <= 1;
        else
            empty <= 0;
    end
            
endmodule

module GrayCounter
   #(parameter   NUM_WIDTH = 4)
   
    (output reg  [NUM_WIDTH-1:0]    graynum,  //'Gray' code count output.
    
     input wire                         en,  //Count enable.
     input wire                         rst,   //Count reset.
    
     input wire                         clk);

    /////////Internal connections & variables///////
    reg    [NUM_WIDTH-1:0]         binarynum;

    /////////Code///////////////////////
    
    always @ (posedge clk)
        if (!rst) begin
            binarynum   <= {NUM_WIDTH{1'b 0}} + 1;  //Gray count begins @ '1' with
            graynum <= {NUM_WIDTH{1'b 0}};      // first 'en'.
        end
        else if (en) begin
            binarynum   <= binarynum + 1;
            graynum <= {binarynum[NUM_WIDTH-1],
                              binarynum[NUM_WIDTH-2:0] ^ binarynum[NUM_WIDTH-1:1]};
        end
    
endmodule
