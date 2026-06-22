module compressed_decoder(input  [31:0] instr_raw,
                          output reg [31:0] instr,
                          output compressed,
                          output reg illegal_c);

  wire [15:0] c;

  wire [4:0] rd_rs1;
  wire [4:0] rs2;
  wire [4:0] rd_p;
  wire [4:0] rs2_p;

  wire [11:0] imm_ci;
  wire [19:0] imm_lui;

  localparam [6:0] OPCODE_OP     = 7'b0110011;
  localparam [6:0] OPCODE_OP_IMM = 7'b0010011;
  localparam [6:0] OPCODE_LUI    = 7'b0110111;

  assign c = instr_raw[15:0];

  assign compressed = (instr_raw[1:0] != 2'b11);

  assign rd_rs1 = c[11:7];
  assign rs2    = c[6:2];

  assign rd_p  = {2'b01, c[9:7]};
  assign rs2_p = {2'b01, c[4:2]};

  assign imm_ci  = {{6{c[12]}}, c[12], c[6:2]};
  assign imm_lui = {{14{c[12]}}, c[12], c[6:2]};

  function [31:0] r_type;
    input [6:0] funct7;
    input [4:0] rs2_in;
    input [4:0] rs1_in;
    input [2:0] funct3;
    input [4:0] rd_in;
    input [6:0] opcode;
    begin
      r_type = {funct7, rs2_in, rs1_in, funct3, rd_in, opcode};
    end
  endfunction

  function [31:0] i_type;
    input [11:0] imm;
    input [4:0] rs1_in;
    input [2:0] funct3;
    input [4:0] rd_in;
    input [6:0] opcode;
    begin
      i_type = {imm, rs1_in, funct3, rd_in, opcode};
    end
  endfunction

  function [31:0] u_type;
    input [19:0] imm;
    input [4:0] rd_in;
    input [6:0] opcode;
    begin
      u_type = {imm, rd_in, opcode};
    end
  endfunction

  always @(*) begin
    instr     = instr_raw;
    illegal_c = 1'b0;

    if (compressed) begin
      instr = 32'h00000013;

      case (c[1:0])

        2'b01: begin
          case (c[15:13])

            // c.addi rd, imm -> addi rd, rd, imm
            3'b000: begin
              instr = i_type(imm_ci, rd_rs1, 3'b000, rd_rs1, OPCODE_OP_IMM);
            end

            // c.lui rd, imm -> lui rd, imm
            // rd = x0 no es válido. rd = x2 corresponde a c.addi16sp, no implementado aquí.
            3'b011: begin
              if ((rd_rs1 != 5'd0) && (rd_rs1 != 5'd2))
                instr = u_type(imm_lui, rd_rs1, OPCODE_LUI);
              else
                illegal_c = 1'b1;
            end

            // c.srli, c.srai, c.sub, c.xor, c.or, c.and
            3'b100: begin
              case (c[11:10])

                // c.srli rd', shamt -> srli rd', rd', shamt
                2'b00: begin
                  instr = i_type({7'b0000000, c[6:2]},
                                 rd_p, 3'b101, rd_p, OPCODE_OP_IMM);
                end

                // c.srai rd', shamt -> srai rd', rd', shamt
                2'b01: begin
                  instr = i_type({7'b0100000, c[6:2]},
                                 rd_p, 3'b101, rd_p, OPCODE_OP_IMM);
                end

                // c.andi no está pedido en la Parte 1
                2'b10: begin
                  illegal_c = 1'b1;
                end

                // c.sub, c.xor, c.or, c.and
                2'b11: begin
                  if (c[12] == 1'b0) begin
                    case (c[6:5])
                      // c.sub rd', rs2' -> sub rd', rd', rs2'
                      2'b00: instr = r_type(7'b0100000, rs2_p, rd_p,
                                            3'b000, rd_p, OPCODE_OP);

                      // c.xor rd', rs2' -> xor rd', rd', rs2'
                      2'b01: instr = r_type(7'b0000000, rs2_p, rd_p,
                                            3'b100, rd_p, OPCODE_OP);

                      // c.or rd', rs2' -> or rd', rd', rs2'
                      2'b10: instr = r_type(7'b0000000, rs2_p, rd_p,
                                            3'b110, rd_p, OPCODE_OP);

                      // c.and rd', rs2' -> and rd', rd', rs2'
                      2'b11: instr = r_type(7'b0000000, rs2_p, rd_p,
                                            3'b111, rd_p, OPCODE_OP);
                    endcase
                  end else begin
                    illegal_c = 1'b1;
                  end
                end
              endcase
            end

            default: begin
              illegal_c = 1'b1;
            end

          endcase
        end

        2'b10: begin
          case (c[15:13])

            // c.slli rd, shamt -> slli rd, rd, shamt
            3'b000: begin
              instr = i_type({7'b0000000, c[6:2]},
                             rd_rs1, 3'b001, rd_rs1, OPCODE_OP_IMM);
            end

            // c.add rd, rs2 -> add rd, rd, rs2
            3'b100: begin
              if ((c[12] == 1'b1) && (rd_rs1 != 5'd0) && (rs2 != 5'd0))
                instr = r_type(7'b0000000, rs2, rd_rs1,
                               3'b000, rd_rs1, OPCODE_OP);
              else
                illegal_c = 1'b1;
            end

            default: begin
              illegal_c = 1'b1;
            end
          endcase
        end

        default: begin
          illegal_c = 1'b1;
        end
      endcase
    end
  end

endmodule