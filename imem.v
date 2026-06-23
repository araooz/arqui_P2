module imem(input  [31:0] a,
            output [31:0] rd);

  reg [15:0] RAM[511:0];

  initial begin
    $readmemh("riscvtest.mem", RAM);
  end

  assign rd = {RAM[a[31:1] + 1], RAM[a[31:1]]};

endmodule
