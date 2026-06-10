module imem(input  [31:0] a,
            output [31:0] rd);
  
  reg [31:0] RAM[63:0]; 

  initial begin
    $readmemh("riscvtest.mem",RAM); 
        // 123452B7 -- lui  x5, 0x12345    # x5 = 0x12345000
        // 67828293 -- addi x5, x5, 0x678  # x5 = 0x12345678
        // 0F0F0337 -- lui  x6, 0x0F0F0    # x6 = 0x0F0F0000
        // 0F030313 -- addi x6, x6, 0x0F0  # x6 = 0x0F0F00F0
        // 0062C2B3 -- xor  x5, x5, x6     # x5 = 0x12345678 ^ 0x0F0F00F0 = 0x1D3B5688
        // 0062C333 -- xor  x6, x5, x6     # x6 = 0x1D3B5688 ^ 0x0F0F00F0 = 0x12345678
        // 0062C2B3 -- xor  x5, x5, x6     # x5 = 0x1D3B5688 ^ 0x12345678 = 0x0F0F00F0
        // 06502223 -- sw   x5, 100(x0)    # mem[100] = 0x0F0F00F0
        // 06602423 -- sw   x6, 104(x0)    # mem[104] = 0x12345678
        // 00000063 -- beq  x0, x0, 0      # infinite loop
  end

  assign rd = RAM[a[31:2]]; // word aligned
endmodule