module compressed_decoder(input  [31:0] instr_raw,
                          output reg [31:0] instr,
                          output compressed,
                          output reg illegal_c);

  wire [15:0] c;

  wire [4:0] rd_rs1;
  wire [4:0] rs2;
  wire [4:0] rd_p;
  wire [4:0] rs1_p;
  wire [4:0] rs2_p;

  wire [11:0] imm_ci;
  wire [19:0] imm_lui;

  wire [11:0] imm_clw;
  wire [11:0] imm_clwsp;
  wire [11:0] imm_csw;
  wire [11:0] imm_cswsp;

  wire [12:0] imm_cb;
  wire [20:0] imm_cj;

  localparam [6:0] OPCODE_OP      = 7'b0110011;
  localparam [6:0] OPCODE_OP_IMM  = 7'b0010011;
  localparam [6:0] OPCODE_LUI     = 7'b0110111;
  localparam [6:0] OPCODE_LOAD    = 7'b0000011;
  localparam [6:0] OPCODE_STORE   = 7'b0100011;
  localparam [6:0] OPCODE_BRANCH  = 7'b1100011;
  localparam [6:0] OPCODE_JAL     = 7'b1101111;
  localparam [6:0] OPCODE_JALR    = 7'b1100111;

  assign c = instr_raw[15:0];

  assign compressed = (instr_raw[1:0] != 2'b11);

  assign rd_rs1 = c[11:7];
  assign rs2    = c[6:2];

  assign rd_p  = {2'b01, c[9:7]};
  assign rs1_p = {2'b01, c[9:7]};
  assign rs2_p = {2'b01, c[4:2]};

  // c.addi immediate: sign-extended 6-bit immediate
  assign imm_ci = {{6{c[12]}}, c[12], c[6:2]};

  // c.lui immediate: sign-extended 6-bit upper immediate
  assign imm_lui = {{14{c[12]}}, c[12], c[6:2]};

  // c.lw / c.sw immediate: uimm[6:2] = {c[5], c[12:10], c[6]}
  assign imm_clw = {5'b00000, c[5], c[12:10], c[6], 2'b00};
  assign imm_csw = {5'b00000, c[5], c[12:10], c[6], 2'b00};

  // c.lwsp immediate: uimm[7:2] = {c[3:2], c[12], c[6:4]}
  assign imm_clwsp = {4'b0000, c[3:2], c[12], c[6:4], 2'b00};

  // c.swsp immediate: uimm[7:2] = {c[8:7], c[12:9]}
  assign imm_cswsp = {4'b0000, c[8:7], c[12:9], 2'b00};

  // c.beqz / c.bnez immediate
  assign imm_cb = {{4{c[12]}}, c[12], c[6:5], c[2], c[11:10], c[4:3], 1'b0};

  // c.j / c.jal immediate
  assign imm_cj = {{9{c[12]}}, c[12], c[8], c[10:9], c[6], c[7],
                   c[2], c[11], c[5:3], 1'b0};

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

  function [31:0] s_type;
    input [11:0] imm;
    input [4:0] rs2_in;
    input [4:0] rs1_in;
    input [2:0] funct3;
    input [6:0] opcode;
    begin
      s_type = {imm[11:5], rs2_in, rs1_in, funct3, imm[4:0], opcode};
    end
  endfunction

  function [31:0] b_type;
    input [12:0] imm;
    input [4:0] rs2_in;
    input [4:0] rs1_in;
    input [2:0] funct3;
    input [6:0] opcode;
    begin
      b_type = {imm[12], imm[10:5], rs2_in, rs1_in, funct3,
                imm[4:1], imm[11], opcode};
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

  function [31:0] j_type;
    input [20:0] imm;
    input [4:0] rd_in;
    input [6:0] opcode;
    begin
      j_type = {imm[20], imm[10:1], imm[11], imm[19:12], rd_in, opcode};
    end
  endfunction

  always @(*) begin
    instr     = instr_raw;
    illegal_c = 1'b0;

    if (compressed) begin
      instr = 32'h00000013;

      case (c[1:0])

        // Quadrant 0
        2'b00: begin
          case (c[15:13])

            // c.lw rd', uimm(rs1') -> lw rd', uimm(rs1')
            3'b010: begin
              instr = i_type(imm_clw, rs1_p, 3'b010, rs2_p, OPCODE_LOAD);
            end

            // c.sw rs2', uimm(rs1') -> sw rs2', uimm(rs1')
            3'b110: begin
              instr = s_type(imm_csw, rs2_p, rs1_p, 3'b010, OPCODE_STORE);
            end

            default: begin
              illegal_c = 1'b1;
            end

          endcase
        end

        // Quadrant 1
        2'b01: begin
          case (c[15:13])

            // c.addi rd, imm -> addi rd, rd, imm
            3'b000: begin
              instr = i_type(imm_ci, rd_rs1, 3'b000, rd_rs1, OPCODE_OP_IMM);
            end

            // c.jal offset -> jal x1, offset
            3'b001: begin
              instr = j_type(imm_cj, 5'd1, OPCODE_JAL);
            end

            // c.lui rd, imm -> lui rd, imm
            // rd = x0 no es válido. rd = x2 sería c.addi16sp, no implementado.
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
                  if (c[12] == 1'b0)
                    instr = i_type({7'b0000000, c[6:2]},
                                   rd_p, 3'b101, rd_p, OPCODE_OP_IMM);
                  else
                    illegal_c = 1'b1;
                end

                // c.srai rd', shamt -> srai rd', rd', shamt
                2'b01: begin
                  if (c[12] == 1'b0)
                    instr = i_type({7'b0100000, c[6:2]},
                                   rd_p, 3'b101, rd_p, OPCODE_OP_IMM);
                  else
                    illegal_c = 1'b1;
                end

                // c.andi rd', imm -> andi rd', rd', imm
                2'b10: begin
                  instr = i_type(imm_ci, rd_p, 3'b111, rd_p, OPCODE_OP_IMM);
                end

                // c.sub, c.xor, c.or, c.and
                2'b11: begin
                  if (c[12] == 1'b0) begin
                    case (c[6:5])
                      2'b00: instr = r_type(7'b0100000, rs2_p, rd_p,
                                            3'b000, rd_p, OPCODE_OP); // c.sub
                      2'b01: instr = r_type(7'b0000000, rs2_p, rd_p,
                                            3'b100, rd_p, OPCODE_OP); // c.xor
                      2'b10: instr = r_type(7'b0000000, rs2_p, rd_p,
                                            3'b110, rd_p, OPCODE_OP); // c.or
                      2'b11: instr = r_type(7'b0000000, rs2_p, rd_p,
                                            3'b111, rd_p, OPCODE_OP); // c.and
                    endcase
                  end else begin
                    illegal_c = 1'b1;
                  end
                end
              endcase
            end

            // c.j offset -> jal x0, offset
            3'b101: begin
              instr = j_type(imm_cj, 5'd0, OPCODE_JAL);
            end

            // c.beqz rs1', offset -> beq rs1', x0, offset
            3'b110: begin
              instr = b_type(imm_cb, 5'd0, rs1_p, 3'b000, OPCODE_BRANCH);
            end

            // c.bnez rs1', offset -> bne rs1', x0, offset
            3'b111: begin
              instr = b_type(imm_cb, 5'd0, rs1_p, 3'b001, OPCODE_BRANCH);
            end

            default: begin
              illegal_c = 1'b1;
            end

          endcase
        end

        // Quadrant 2
        2'b10: begin
          case (c[15:13])

            // c.slli rd, shamt -> slli rd, rd, shamt
            3'b000: begin
              if ((c[12] == 1'b0) && (rd_rs1 != 5'd0))
                instr = i_type({7'b0000000, c[6:2]},
                               rd_rs1, 3'b001, rd_rs1, OPCODE_OP_IMM);
              else
                illegal_c = 1'b1;
            end

            // c.lwsp rd, uimm(x2) -> lw rd, uimm(x2)
            3'b010: begin
              if (rd_rs1 != 5'd0)
                instr = i_type(imm_clwsp, 5'd2, 3'b010, rd_rs1, OPCODE_LOAD);
              else
                illegal_c = 1'b1;
            end

            // c.jr, c.jalr, c.add
            3'b100: begin
              if (c[12] == 1'b0) begin
                if ((rd_rs1 != 5'd0) && (rs2 == 5'd0)) begin
                  // c.jr rs1 -> jalr x0, 0(rs1)
                  instr = i_type(12'b0, rd_rs1, 3'b000, 5'd0, OPCODE_JALR);
                end else begin
                  // c.mv no está pedido
                  illegal_c = 1'b1;
                end
              end else begin
                if ((rd_rs1 != 5'd0) && (rs2 == 5'd0)) begin
                  // c.jalr rs1 -> jalr x1, 0(rs1)
                  instr = i_type(12'b0, rd_rs1, 3'b000, 5'd1, OPCODE_JALR);
                end else if ((rd_rs1 != 5'd0) && (rs2 != 5'd0)) begin
                  // c.add rd, rs2 -> add rd, rd, rs2
                  instr = r_type(7'b0000000, rs2, rd_rs1,
                                 3'b000, rd_rs1, OPCODE_OP);
                end else begin
                  illegal_c = 1'b1;
                end
              end
            end

            // c.swsp rs2, uimm(x2) -> sw rs2, uimm(x2)
            3'b110: begin
              instr = s_type(imm_cswsp, rs2, 5'd2, 3'b010, OPCODE_STORE);
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
