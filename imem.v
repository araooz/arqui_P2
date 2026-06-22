module imem(input  [31:0] a,
            output [31:0] rd);

  reg [31:0] RAM[255:0];

  wire [31:0] word0;
  wire [31:0] word1;

  initial begin
    $readmemh("riscvtest.mem", RAM);
  end

  assign word0 = RAM[a[31:2]];
  assign word1 = RAM[a[31:2] + 1];

  // Si PC[1] = 0, la instrucción empieza al inicio de la palabra.
  // Si PC[1] = 1, la instrucción empieza en la mitad alta de la palabra.
  assign rd = a[1] ? {word1[15:0], word0[31:16]} : word0;

endmodule