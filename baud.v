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
