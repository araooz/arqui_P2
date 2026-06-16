module pc_reg(input  clk, reset, enable,
              input  [31:0] PCNext,
              output reg [31:0] PC);

  always @(posedge clk or posedge reset) begin
    if (reset) PC <= 32'b0;
    else if (enable) PC <= PCNext;
  end
endmodule