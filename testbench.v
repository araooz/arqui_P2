module testbench();

  reg clk;
  reg reset;

  wire [31:0] WriteData;
  wire [31:0] DataAdr;
  wire MemWrite;

  top dut(
    .clk(clk),
    .reset(reset),
    .WriteData(WriteData),
    .DataAdr(DataAdr),
    .MemWrite(MemWrite)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
  // dmem usa direcciones word-aligned: RAM[address >> 2]
  dut.dmem.RAM[10] = 32'h0000007b; // address 40
  dut.dmem.RAM[16] = 32'h0000004d; // address 64

  reset = 1;
  #22;
  reset = 0;
end

  always @(negedge clk) begin
    if (MemWrite) begin
      case (DataAdr)

        32'd40: begin
          if (WriteData !== 32'h0000007b) begin
            $display("FAIL c.sw: expected 0000007b, got %h", WriteData);
            $stop;
          end else begin
            $display("PASS c.sw: mem[40] = %h", WriteData);
          end
        end

        32'd0: begin
  if (WriteData !== 32'h0000007b) begin
    $display("FAIL c.lw: expected 0000007b, got %h", WriteData);
    $stop;
  end else begin
    $display("PASS c.lw: mem[0] = %h", WriteData);
  end
end

        32'd64: begin
          if (WriteData !== 32'h0000004d) begin
            $display("FAIL c.swsp: expected 0000004d, got %h", WriteData);
            $stop;
          end else begin
            $display("PASS c.swsp: mem[64] = %h", WriteData);
          end
        end

        32'd4: begin
          if (WriteData !== 32'h0000004d) begin
            $display("FAIL c.lwsp: expected 0000004d, got %h", WriteData);
            $stop;
          end else begin
            $display("PASS c.lwsp: mem[4] = %h", WriteData);
          end
        end

        32'd8: begin
          if (WriteData !== 32'h00000001) begin
            $display("FAIL c.beqz: expected 00000001, got %h", WriteData);
            $stop;
          end else begin
            $display("PASS c.beqz: mem[8] = %h", WriteData);
          end
        end

        32'd12: begin
          if (WriteData !== 32'h00000002) begin
            $display("FAIL c.bnez: expected 00000002, got %h", WriteData);
            $stop;
          end else begin
            $display("PASS c.bnez: mem[12] = %h", WriteData);
          end
        end

        32'd16: begin
          if (WriteData !== 32'h00000003) begin
            $display("FAIL c.j: expected 00000003, got %h", WriteData);
            $stop;
          end else begin
            $display("PASS c.j: mem[16] = %h", WriteData);
          end
        end

        32'd20: begin
          if (WriteData !== 32'h00000060) begin
            $display("FAIL c.jal return address: expected 00000060, got %h", WriteData);
            $stop;
          end else begin
            $display("PASS c.jal return address: mem[20] = %h", WriteData);
          end
        end

        32'd24: begin
          if (WriteData !== 32'h00000004) begin
            $display("FAIL c.jal target: expected 00000004, got %h", WriteData);
            $stop;
          end else begin
            $display("PASS c.jal target: mem[24] = %h", WriteData);
          end
        end

        32'd28: begin
          if (WriteData !== 32'h00000005) begin
            $display("FAIL c.jr: expected 00000005, got %h", WriteData);
            $stop;
          end else begin
            $display("PASS c.jr: mem[28] = %h", WriteData);
          end
        end

        32'd32: begin
          if (WriteData !== 32'h00000090) begin
            $display("FAIL c.jalr return address: expected 00000090, got %h", WriteData);
            $stop;
          end else begin
            $display("PASS c.jalr return address: mem[32] = %h", WriteData);
          end
        end

        32'd36: begin
          if (WriteData !== 32'h00000006) begin
            $display("FAIL c.jalr target: expected 00000006, got %h", WriteData);
            $stop;
          end else begin
            $display("PASS c.jalr target: mem[36] = %h", WriteData);
            $display("E2 Parte 2 test PASSED");
            $stop;
          end
        end

        default: begin
          $display("FAIL unexpected store: DataAdr=%h WriteData=%h", DataAdr, WriteData);
          $stop;
        end

      endcase
    end
  end

  initial begin
    #2000;
    $display("E2 Parte 2 test TIMEOUT");
    $stop;
  end

endmodule
