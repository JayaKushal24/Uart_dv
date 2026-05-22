`timescale 1ns / 1ps

`include "baud.v"
`include "u_rec.v"
`include "u_xmit.v"


module uart#(
    parameter DATA_WIDTH = 8,
    parameter BAUD       = 115200,
    parameter CLK_FREQ   = 100_000_000,
    parameter OVERSAMPLE = 16
) (
    input   sys_clk,sys_rst_l,xmitH,uart_REC_dataH,
    input  [DATA_WIDTH-1:0] xmit_dataH,

    output uart_XMIT_dataH,xmit_doneH,rec_readyH,rec_busy,xmit_active,
    output [DATA_WIDTH-1:0] rec_dataH
        //  ,output  uart_clk
);

wire uart_clk;

baud  #(.BAUD(BAUD),.CLK_FREQ(CLK_FREQ))baud_mod(.sys_clk(sys_clk),.sys_rst_l(sys_rst_l),.uart_clk(uart_clk));

u_rec #(.DATA_WIDTH(DATA_WIDTH))  receiver (.uart_clk(uart_clk),.sys_rst_l(sys_rst_l),.uart_REC_dataH(uart_REC_dataH),
                .rec_readyH(rec_readyH),.rec_dataH(rec_dataH),.rec_busyH(rec_busy));


u_xmit #(.DATA_WIDTH(DATA_WIDTH)) transmitter(.uart_clk(uart_clk),.xmitH(xmitH),.xmit_dataH(xmit_dataH),
            .uart_XMIT_dataH(uart_XMIT_dataH),.sys_rst_l(sys_rst_l),.xmit_active(xmit_active),.xmit_doneH(xmit_doneH));



endmodule

