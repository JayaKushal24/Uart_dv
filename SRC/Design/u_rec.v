module baud#(parameter BAUD =115200,CLK_FREQ=100_000_000)(
input sys_clk,sys_rst_l,
output reg uart_clk
    );

localparam CLK_DIV=(CLK_FREQ)/(BAUD*16);//(100_000_000/115200)=(868/16)=54..
//localparam CLK_DIV=(CLK_FREQ)/(BAUD*16*2);
reg [$clog2(CLK_DIV/2)-1:0]count;

    always @(posedge sys_clk or negedge sys_rst_l)begin
        if(!sys_rst_l)begin
            uart_clk<=0;
            count<=0;
        end
        else begin
                if(count==CLK_DIV/2-1)begin
                    uart_clk<=~uart_clk;
                    count<=0;
                end
                else count<=count+1;
        end
    end


endmodule

[jayakushal@feserver my_uart]$
[jayakushal@feserver my_uart]$ cat u_rec.v
`timescale 1ns / 1ps

module u_rec #(parameter DATA_WIDTH=8) (
    input sys_rst_l, uart_clk, uart_REC_dataH,
    output reg rec_readyH, rec_busyH,
    output reg [DATA_WIDTH-1:0] rec_dataH
    );
    reg [1:0] c_state, n_state;
    reg [1:0] sync_ff;
    reg [3:0] bit_index;
    reg [3:0] baud_count;
    reg [DATA_WIDTH-1:0] shift_reg;
    localparam IDLE  = 2'b00,WAIT = 2'b01,DATA  = 2'b10,STOP  = 2'b11;
    always @ (posedge uart_clk or negedge sys_rst_l) begin
        if (!sys_rst_l) begin
            c_state<=IDLE;
            sync_ff<=2'b11;
            shift_reg<={DATA_WIDTH{1'b0}};
            rec_dataH<={DATA_WIDTH{1'b0}};
        end
        else begin
            c_state<=n_state;
            sync_ff[0]<=uart_REC_dataH;
            sync_ff[1]<=sync_ff[0];
        end
    end

    always @ (posedge uart_clk or negedge sys_rst_l) begin
        if (!sys_rst_l) begin
            baud_count<=4'd0;
            rec_busyH<=1'b0;
        end
        else begin
            if ((c_state==WAIT)||(c_state==STOP))  baud_count<=baud_count+1'b1;
            else                                    baud_count<=4'b0000;
        end
    end

    always @(*)begin
        n_state=c_state;
        case(c_state)
            IDLE: begin
                rec_readyH=1'b1;
                if (!uart_REC_dataH)    n_state=WAIT;
                else                    n_state = IDLE;
                bit_index=4'd0;
            end

            WAIT: begin
                if(bit_index==4'd0) begin
                    if (baud_count==4'b0110)    n_state = DATA;
                    else                        n_state = WAIT;
                end
                else if(bit_index==DATA_WIDTH+1) begin
                    if (baud_count==4'b1110)    n_state = STOP;
                    else                        n_state = WAIT;
                end
                else begin
                    if (baud_count == 4'b1110)  n_state = DATA;
                    else                        n_state = WAIT;
                end
            end

            DATA: begin
                if((bit_index==4'd0)&&(sync_ff[1]!=1'b0)) begin
                    n_state=IDLE;
                end
                else begin
                    rec_busyH=1'b1;
                    rec_readyH=1'b0;
                    shift_reg={sync_ff[1],shift_reg[DATA_WIDTH-1:1]};
                    bit_index =bit_index+1;
                    n_state=WAIT;
                end
            end

            STOP: begin
                if(sync_ff[1]) begin
                    rec_dataH=shift_reg;
                    rec_readyH=1'b1;
                end
                else
                    rec_readyH=1'b0;
                shift_reg={DATA_WIDTH{1'b0}};
                rec_busyH=1'b0;
                n_state=IDLE;
            end
            default: n_state = IDLE;
        endcase
    end

endmodule
