`define TESTCASES 10


module uart_reference#(parameter DATA_WIDTH=8)(
    input   uart_clk,sys_rst_l,xmitH,uart_REC_dataH,
    input   [DATA_WIDTH-1:0] xmit_dataH,

    output reg uart_XMIT_dataH,xmit_doneH,rec_readyH,rec_busy,xmit_active,
    output reg [DATA_WIDTH-1:0] rec_dataH
);
        integer i,j,k,l;
        reg flag_txn,flag_rxn;
        reg [DATA_WIDTH-1:0] captured_data_txn;
        reg [DATA_WIDTH:0] captured_data_rx;

        always @(negedge sys_rst_l or posedge uart_clk) begin
                if(!sys_rst_l)begin
                        uart_XMIT_dataH<=1'b1;
                        xmit_doneH<=1'b1;
                        rec_readyH<=1'b1;
                        rec_busy<=1'b0;
                        xmit_active<=1'b0;
                        rec_dataH<={(DATA_WIDTH){1'b0}};
                        flag_txn<=1'b0;
                        flag_rxn<=1'b0;
                        captured_data_txn<=0;//clears
                        captured_data_rx<=0;
                end
        end


        //transmitter block
        initial begin
//         @(posedge uart_clk);
                for(i =0;i<`TESTCASES;i=i+1) begin
                        wait(sys_rst_l == 1);begin
                                uart_XMIT_dataH=1'b1;
                                xmit_doneH=1'b1;
                                xmit_active=1'b0;
                                //maybe a statment of wait until xmitH==1 shd be added.here so it wont proceed to next line...
//                              $display("XMIT",xmit_dataH);
                                @(xmitH);
                                if(xmitH && !flag_txn)begin
                                        flag_txn=1;
                                        captured_data_txn=xmit_dataH;
                                end
                                @(posedge uart_clk);
                                wait(flag_txn==1);
                                begin
                                                xmit_doneH=0;
                                                xmit_active=1'b1;
                                                //start bit
                                                uart_XMIT_dataH=0;
                                                repeat(16)@(posedge uart_clk);
                                                //data bit
                                                for(k=0;k<=DATA_WIDTH-1;k=k+1)begin
                                                        uart_XMIT_dataH=captured_data_txn[k];
                                                        repeat(16)@(posedge uart_clk);
                                                end
                                                //stop bit
                                                uart_XMIT_dataH=1'b1;
                                                repeat(16)@(posedge uart_clk);
                                                xmit_doneH=1;
                                                flag_txn=0;
                                                xmit_active=1'b0;
                                end
                        end
                end
        end



initial begin
    for(integer j =0; j<`TESTCASES; j=j+1) begin
        wait(sys_rst_l==1);
        begin
            rec_busy=1'b0;
            rec_readyH=1'b1;
            wait(uart_REC_dataH==0);//waiting for start bit
            if(uart_REC_dataH==0 && !flag_rxn)
                flag_rxn=1;
            wait(flag_rxn==1);
            begin
                captured_data_rx=0;
                repeat(8)@(posedge uart_clk);//waiting till midpoint of start bit
                if(uart_REC_dataH==0) begin//checking for glitch
                    rec_busy=1'b1;
                    rec_readyH=1'b0;
                    for(l=0;l<=DATA_WIDTH;l=l+1) begin
                        captured_data_rx={uart_REC_dataH,captured_data_rx[DATA_WIDTH:1]};
                        repeat(16)@(posedge uart_clk);
                    end
                    if(uart_REC_dataH==1) begin
                        rec_dataH=captured_data_rx[DATA_WIDTH:1];
                        rec_readyH=1'b1;
                    end
                    else begin
                        rec_readyH=1'b0;
                    end
                    rec_busy=1'b0;
                    flag_rxn=1'b0;
                end
                else //glitch is detected
                    rec_busy=1'b0;
                    rec_readyH=1'b1;
                    flag_rxn=1'b0;
                end
            end
        end
    end
endmodule
