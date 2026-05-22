`timescale 1ns/1ps;

//`include "uart.v"
//`include "uart_reference.v"

module tb_uart;
parameter DATA_WIDTH = 8;
parameter BAUD       = 115200;
parameter CLK_FREQ   = 100_000_000;
parameter OVERSAMPLE = 16;
reg sys_clk,sys_rst_l;//common input

reg xmitH;//both input
reg uart_REC_dataH;//both input
reg [DATA_WIDTH-1:0]xmit_dataH;//both input

integer tx_pass_count,tx_fail_count;
integer rx_pass_count,rx_fail_count;

wire  uart_clk_ref;

//    wire uart_clk;//input clk..need to remove it

//dut wires
wire uart_XMIT_dataH_dut,xmit_doneH_dut,xmit_active_dut,rec_readyH_dut,rec_busy_dut;
wire [DATA_WIDTH-1:0] rec_dataH_dut;

//ref wires
wire uart_XMIT_dataH_ref,xmit_doneH_ref,xmit_active_ref,rec_readyH_ref,rec_busy_ref;
wire [DATA_WIDTH-1:0] rec_dataH_ref;


uart#(.DATA_WIDTH(DATA_WIDTH),.BAUD(BAUD),.CLK_FREQ(CLK_FREQ),.OVERSAMPLE(OVERSAMPLE))  dut (
    .sys_clk(sys_clk),
    .sys_rst_l(sys_rst_l),//common

    .xmitH(xmitH),
    .uart_REC_dataH(uart_REC_dataH),
    .xmit_dataH(xmit_dataH),//both inputs

    .uart_XMIT_dataH(uart_XMIT_dataH_dut),
    .xmit_active(xmit_active_dut),
    .xmit_doneH(xmit_doneH_dut),

    .rec_readyH(rec_readyH_dut),
    .rec_busy(rec_busy_dut),
    .rec_dataH(rec_dataH_dut),

    .uart_clk(uart_clk_ref)
);

uart_reference #(.DATA_WIDTH(DATA_WIDTH)) ref_1(
    .uart_clk(uart_clk_ref),
    .sys_rst_l(sys_rst_l),

    .xmitH(xmitH),
    .uart_REC_dataH(uart_REC_dataH),
    .xmit_dataH(xmit_dataH),//both inputs

    .uart_XMIT_dataH(uart_XMIT_dataH_ref),
    .xmit_active(xmit_active_ref),
    .xmit_doneH(xmit_doneH_ref),

    .rec_readyH(rec_readyH_ref),
    .rec_busy(rec_busy_ref),
    .rec_dataH(rec_dataH_ref)
);

initial begin
    sys_clk=0;
    forever #5 sys_clk=~sys_clk;
end


task transmitter_send;

input [DATA_WIDTH-1:0] val;

begin
    @(negedge uart_clk_ref);
    xmit_dataH=val;
    xmitH=1;
    repeat(2) @(posedge uart_clk_ref);
    xmitH=0;
    wait(xmit_doneH_dut);
end
endtask

task receiver_driver_valid;
    input [DATA_WIDTH-1:0] value;
    integer x;
    begin
        uart_REC_dataH=1'b0;
        repeat(16) @(posedge uart_clk_ref);
        for(x=0;x<DATA_WIDTH;x=x+1) begin
            uart_REC_dataH=value[x];
            repeat(16) @(posedge uart_clk_ref);
        end
        uart_REC_dataH=1'b1;
        repeat(16) @(posedge uart_clk_ref);
    end
endtask

task receiver_driver_invalid_2;
    begin
        uart_REC_dataH=1'b0;
        repeat(2) @(posedge uart_clk_ref);
        uart_REC_dataH=1'b1;
        repeat(16) @(posedge uart_clk_ref);
    end
endtask

task receiver_driver_invalid;
    input [DATA_WIDTH-1:0] value;
    integer x;
    begin
        uart_REC_dataH=1'b0;
        repeat(16) @(posedge uart_clk_ref);
        for(x=0;x<DATA_WIDTH;x=x+1) begin
            uart_REC_dataH=value[x];
            repeat(16) @(posedge uart_clk_ref);
        end
        uart_REC_dataH=1'b0;//stop bit is 0..so output shd be discarded..0
        repeat(16) @(posedge uart_clk_ref);

    end

endtask

task system_reset;
    begin
        // @(negedge uart_clk)//to see if it asynchronous or not
        sys_rst_l=0;//reset on
        repeat(100) @(posedge sys_clk);
        sys_rst_l=1;//reset off
    end
endtask

task transmitter_testing;

begin

    //transmitter test1
    transmitter_send(8'hAA);//1010_1010
    transmitter_send(8'h55);//0101_0101
    transmitter_send(8'hFF);//1111_1111
    transmitter_send(8'h00);//0000_0000
    transmitter_send(8'h45);//0100_0101

end

endtask

task receiver_testing;

    begin

        receiver_driver_valid(8'h69);//test1
        receiver_driver_valid(8'hFF);//test1
        receiver_driver_valid(8'hAA);//test1
//        receiver_driver_invalid(8'h69);//test2
        receiver_driver_valid(8'h55);//test3
 //       receiver_driver_invalid(8'h55);//test4
//        receiver_driver_valid(8'haa);//test5
    //  receiver_driver_invalid(8'haa);//test6
        receiver_driver_valid(8'h96);//test7
       receiver_driver_invalid_2;
       receiver_driver_valid(8'h00);//test7

//        repeat(20) @(posedge uart_clk_ref);
//            $display("\n================ FINAL REPORT ================");
//            $display("TX PASS COUNT = %0d", tx_pass_count);
//            $display("TX FAIL COUNT = %0d", tx_fail_count);
//            $display("RX PASS COUNT = %0d", rx_pass_count);
//            $display("RX FAIL COUNT = %0d", rx_fail_count);
//            $display("==============================================\n");

//        $finish;

    end

endtask

task mid_transaction_reset;
    begin
        $display("\n================ MID TRANSACTION RESET TEST ================\n");
        fork
            begin
                // transmitter active
                transmitter_send(8'hA5);
            end
            begin
                // receiver active
                receiver_driver_valid(8'h3C);
            end
            begin
                // wait until both are likely active
                repeat(40) @(posedge uart_clk_ref);
                $display("[%0t] APPLYING RESET DURING ACTIVE TX/RX", $time);
                sys_rst_l = 0;

                // asynchronous reset hold
                repeat(40) @(posedge sys_clk);
                sys_rst_l = 1;
                $display("[%0t] RESET RELEASED", $time);
            end
        join
        // allow DUT to stabilizev
        repeat(50) @(posedge uart_clk_ref);
        receiver_driver_valid(8'hCC);
         repeat(200) @(posedge uart_clk_ref);

        $display("\n================ RESET RECOVERY COMPLETE ===================\n");
    end
endtask


//always @(posedge xmit_doneH_dut) begin
//    #1;
//    if( uart_XMIT_dataH_dut==uart_XMIT_dataH_ref && xmit_active_dut==xmit_active_ref) begin
//        tx_pass_count=tx_pass_count+1;
//        $display("[%0t] TX PASS | dut=%b ref=%b",$time,uart_XMIT_dataH_dut,uart_XMIT_dataH_ref);
//    end
//    else begin
//        tx_fail_count=tx_fail_count+1;
//        $display("[%0t] TX FAIL",$time);
//        $display(" DUT : tx=%b active=%b",uart_XMIT_dataH_dut,xmit_active_dut);
//        $display(" REF : tx=%b active=%b",uart_XMIT_dataH_ref,xmit_active_ref);
//    end
//    $display("************************************************");
//end
//always @(posedge rec_readyH_dut) begin
//    #1;
//    if(rec_dataH_dut==rec_dataH_ref) begin
//        rx_pass_count=rx_pass_count+1;
//        $display("[%0t] RX PASS | data=%0h",$time,rec_dataH_dut);
//    end
//    else begin
//        rx_fail_count=rx_fail_count+1;
//        $display("[%0t] RX FAIL",$time);
//        $display(" DUT DATA = %0h",rec_dataH_dut);
//        $display(" REF DATA = %0h",rec_dataH_ref);
//    end
//    $display("************************************************");
//end

always @(posedge uart_clk_ref) begin
#1;
//    if(xmit_doneH_dut||xmit_doneH_ref) begin
        if( uart_XMIT_dataH_dut==uart_XMIT_dataH_ref && xmit_doneH_dut==xmit_doneH_ref && xmit_active_dut==xmit_active_ref ) begin
            tx_pass_count = tx_pass_count+1;
            $display("[%0t] TX PASS | dut=%b ref=%b",$time,uart_XMIT_dataH_dut,uart_XMIT_dataH_ref);
        end
        else begin
            tx_fail_count=tx_fail_count+1;
            $display("[%0t] TX FAIL.................................................", $time);
            $display(" DUT : tx=%h done=%b active=%b",uart_XMIT_dataH_dut,xmit_doneH_dut,xmit_active_dut);
            $display(" REF : tx=%h done=%b active=%b",uart_XMIT_dataH_ref,xmit_doneH_ref,xmit_active_ref);
        end
       $display("***********************************************************************************************");

//    end

//    if(rec_readyH_dut||rec_readyH_ref) begin
        if( rec_readyH_dut==rec_readyH_ref && rec_busy_dut==rec_busy_ref && rec_dataH_dut==rec_dataH_ref) begin
            rx_pass_count =rx_pass_count+ 1;
            $display("[%0t] RX PASS | data = %0h",$time,rec_dataH_dut);
        end
        else begin
            rx_fail_count=rx_fail_count+ 1;
            $display("[%0t] RX FAIL.................................................", $time);
            $display(" [FAIL] DUT : ready=%b busy=%b data=%0b(hex=%0h)",rec_readyH_dut,rec_busy_dut,rec_dataH_dut,rec_dataH_dut);
            $display(" [FAIL] REF : ready=%b busy=%b data=%0b(hex=%0h)",rec_readyH_ref,rec_busy_ref,rec_dataH_ref,rec_dataH_ref);
        end
               $display("***********************************************************************************************");

//    end
end

initial begin

    xmit_dataH=0;
    xmitH=0;
    uart_REC_dataH=1;

    tx_pass_count=0;
    tx_fail_count=0;
    rx_pass_count=0;
    rx_fail_count=0;

    system_reset();

    repeat(2) @(posedge uart_clk_ref);

    fork
        transmitter_testing();
        receiver_testing();
    join
    repeat(30)@(posedge uart_clk_ref);
    // mid_transaction_reset();

    fork
        transmitter_send(8'h5A);
        receiver_driver_valid(8'hC3);
    join

    repeat(20) @(posedge uart_clk_ref);

    $display("\n================ FINAL REPORT ================");
    $display("TX PASS COUNT = %0d", tx_pass_count);
    $display("TX FAIL COUNT = %0d", tx_fail_count);
    $display("RX PASS COUNT = %0d", rx_pass_count);
    $display("RX FAIL COUNT = %0d", rx_fail_count);
    $display("==============================================\n");

    $finish;

end
endmodule
