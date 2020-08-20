`timescale 1ns/1ns
module a_fifo_testbench();

reg rst;
reg wclk,rclk;
reg [7:0] din;
reg wr,rd;

wire full,empty;
wire [7:0] dout;

wire [3:0]  NR_ptr_w,NW_ptr_w;
wire Almost_full_w,Almost_empty_w;
parameter PERIOD_W = 10;

initial begin
    wclk = 0;
    forever #(PERIOD_W/2) wclk = ~wclk;
end

parameter PERIOD_R = 20;

initial begin
    rclk = 0;
    forever #(PERIOD_R/2) rclk = ~rclk;
end



a_fifo a_fifo_inst(
    .wclk(wclk),
    .rclk(rclk),
   

    .din(din),
    .wr(wr),
    .full(full),

    .dout(dout),
    .rd(rd),
    .empty(empty),


    .NW_ptr_w(NW_ptr_w),
    .NR_ptr_w(NR_ptr_w),
    .Almost_empty_w(Almost_empty_w),
    .Almost_full_w(Almost_full_w),

     .rst(rst)
);


integer i;
initial 
begin
    rst = 1'b0;
    #20
    rst = 1;
    #20
    //这里注意：因为设了第二个clk是20ns，所以这里rst要从10变成20才行哦，不然会
    //漏初始化pNR这个指针的初值
    /*
    wr = 1'b1;
    for(i = 0;i<8;i=i+1)begin
        din = i;
        #10;
    end
    wr =1'b0;
    */

   loop;

   #10;//这个地方加不加都行
   rd = 1'b1;
   #200;
   $finish;
    end

    task loop;
        begin
            wr = 1'b1;
            for(i = 0;i<8;i=i+1)begin
                din = i;
                #10;
            end
            wr =1'b0;
        end
    endtask

        endmodule
