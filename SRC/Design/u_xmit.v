`timescale 1ns / 1ps

module u_xmit #(parameter DATA_WIDTH = 8)(
    input  uart_clk,sys_rst_l,xmitH,
    input  [DATA_WIDTH-1:0] xmit_dataH,
    output reg uart_XMIT_dataH,xmit_active,xmit_doneH
);

    reg [3:0] bit_count;
    reg [3:0] baud_count;
    reg flag;
    reg [DATA_WIDTH-1:0] captured_data;

    always @(posedge uart_clk or negedge sys_rst_l) begin
        if (!sys_rst_l) begin
                bit_count<=0;
                baud_count<=0;
                uart_XMIT_dataH<=1'b1;
                xmit_doneH<=1'b1;
                xmit_active<=1'b0;
                flag<=1'b0;
                captured_data<=0;
        end
        else begin
            xmit_doneH <= 1'b1;
            if (xmitH && !flag) begin
                    flag<=1'b1;
                    xmit_active<=1'b1;
                    baud_count<=0;
                    bit_count<=0;
                    xmit_doneH <= 1'b0;
                    captured_data<=xmit_dataH;
                    uart_XMIT_dataH<=1'b0;
            end
            else if (flag) begin
                    xmit_doneH <= 1'b0;
                    xmit_active <= 1'b1;
                    if (baud_count == 15) begin
                            baud_count <= 0;
                            if (bit_count == DATA_WIDTH + 1) begin
                                    bit_count       <= 0;
                                    flag            <= 1'b0;
                                    xmit_doneH      <= 1'b1;
                                    xmit_active     <= 1'b0;
                                    uart_XMIT_dataH <= 1'b1;
                            end
                            else begin
                                    bit_count <= bit_count + 1;
                                    if(bit_count==DATA_WIDTH)   uart_XMIT_dataH<=1'b1;
                                    else                        uart_XMIT_dataH<=captured_data[bit_count];
                            end
                    end
                    else begin
                        baud_count <= baud_count + 1;
                    end
               end
               else begin
                       xmit_active     <= 1'b0;
                       uart_XMIT_dataH <= 1'b1;
               end
        end
    end
endmodule
