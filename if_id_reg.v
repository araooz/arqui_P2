module if_id_reg (
    input clk,
    input reset,
    input enable,
    input clear,

    input [31:0] pcF,
    input [31:0] instrF,

    output [31:0] pcD,
    output [31:0] instrD,
    );

    always @(posedge clk) begin
        if (reset) begin
            pcD <= 0;
            instrD <= 0;
        end
        else if (clear) begin
            pcD <= 0;
            instrD <= 0;
        end 
        else if (enable) begin
                pcD <= pcF;
                instrD <= instrF;
        end
    end
endmodule
    