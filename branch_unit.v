module branch_unit(input  [31:0] a, b,
                   input  [2:0]  funct3,
                   output reg    taken);

  always @* begin
    case(funct3)
      3'b000:  taken = (a == b); // beq
      3'b001:  taken = (a != b); // bne
      3'b100:  taken = ($signed(a) < $signed(b)); // blt
      3'b101:  taken = ($signed(a) >= $signed(b)); // bge
      default: taken = 1'b0;
    endcase
  end
endmodule