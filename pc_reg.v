module pc_reg (input  clk, reset, enable  
                input  [31:0] pcF, 
                output [31:0] pcF_next);
    reg pcF_next; 

    always @(posedge clk or posedge reset) begin 
        if (reset) pcF_next <= 0;
        else if (enable) pcF_next <= pcF;
    end
endmodule