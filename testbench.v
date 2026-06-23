module testbench();

  reg clk;
  reg reset;

  wire [31:0] WriteData;
  wire [31:0] DataAdr;
  wire MemWrite;

  integer phase;
  integer done;
  integer i;

  localparam TEST_NONE          = 0;
  localparam TEST_COVERAGE      = 1;
  localparam TEST_MATMUL_RV32I  = 2;
  localparam TEST_MATMUL_RVC    = 3;

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
    phase = TEST_NONE;
    done = 0;
    reset = 1;

    run_coverage();
    run_matmul_rv32i();
    run_matmul_rvc();

    $display("ALL E2 TESTS PASSED");
    $stop;
  end

  task clear_state;
    begin
      for (i = 0; i < 512; i = i + 1)
        dut.imem.RAM[i] = 16'h0001;   // c.nop / c.addi x0, 0

      for (i = 0; i < 64; i = i + 1)
        dut.dmem.RAM[i] = 32'b0;

      for (i = 0; i < 32; i = i + 1)
        dut.rvpipe.dp.rf.rf[i] = 32'b0;
    end
  endtask

  task reset_cpu;
    begin
      reset = 1;
      repeat (3) @(negedge clk);
      reset = 0;
    end
  endtask

  task wait_done;
    input [31:0] max_cycles;
    integer cycles;
    begin
      cycles = 0;
      while ((done == 0) && (cycles < max_cycles)) begin
        @(negedge clk);
        cycles = cycles + 1;
      end

      if (done == 0) begin
        $display("FAIL timeout in phase %0d after %0d cycles", phase, max_cycles);
        $stop;
      end
    end
  endtask

  task run_coverage;
    begin
      $display("========================================");
      $display("Running rvc_coverage.mem");
      $display("========================================");

      phase = TEST_COVERAGE;
      done = 0;
      clear_state();
      $readmemh("rvc_coverage.mem", dut.imem.RAM);
      reset_cpu();
      wait_done(2000);

      $display("RVC coverage test PASSED");
    end
  endtask

  task run_matmul_rv32i;
    begin
      $display("========================================");
      $display("Running matmul2x2_rv32i.mem");
      $display("========================================");

      phase = TEST_MATMUL_RV32I;
      done = 0;
      clear_state();
      $readmemh("matmul2x2_rv32i.mem", dut.imem.RAM);
      reset_cpu();
      wait_done(5000);

      $display("Matrix multiplication RV32I test PASSED");
    end
  endtask

  task run_matmul_rvc;
    begin
      $display("========================================");
      $display("Running matmul2x2_rvc.mem");
      $display("========================================");

      phase = TEST_MATMUL_RVC;
      done = 0;
      clear_state();
      $readmemh("matmul2x2_rvc.mem", dut.imem.RAM);
      reset_cpu();
      wait_done(5000);

      $display("Matrix multiplication RVC test PASSED");
    end
  endtask

  task check_store;
    input [31:0] expected_addr;
    input [31:0] expected_data;
    input [255:0] name;
    begin
      if (WriteData !== expected_data) begin
        $display("FAIL %0s: DataAdr=%h expected=%h got=%h",
                 name, DataAdr, expected_data, WriteData);
        $stop;
      end else begin
        $display("PASS %0s: mem[%0d] = %h",
                 name, expected_addr, WriteData);
      end
    end
  endtask

  always @(negedge clk) begin
    if (!reset && MemWrite) begin
      case (phase)
        TEST_COVERAGE: begin
          case (DataAdr)
            32'd0:   check_store(32'd0,   32'h0000000c, "coverage c.addi / c.add");
            32'd4:   check_store(32'd4,   32'h0000000e, "coverage c.sub");
            32'd8:   check_store(32'd8,   32'h00000008, "coverage c.and");
            32'd12:  check_store(32'd12,  32'h0000000e, "coverage c.or");
            32'd16:  check_store(32'd16,  32'h00000006, "coverage c.xor");
            32'd20:  check_store(32'd20,  32'h0000000c, "coverage c.slli");
            32'd24:  check_store(32'd24,  32'h00000008, "coverage c.srli");
            32'd28:  check_store(32'd28,  32'hfffffffc, "coverage c.srai");
            32'd32:  check_store(32'd32,  32'h00001000, "coverage c.lui");
            32'd36:  check_store(32'd36,  32'h00000008, "coverage c.andi");

            32'd40:  check_store(32'd40,  32'h0000007b, "coverage c.sw");
            32'd44:  check_store(32'd44,  32'h0000007b, "coverage c.lw");
            32'd64:  check_store(32'd64,  32'h0000004d, "coverage c.swsp");
            32'd48:  check_store(32'd48,  32'h0000004d, "coverage c.lwsp");

            32'd52:  check_store(32'd52,  32'h00000001, "coverage c.beqz");
            32'd56:  check_store(32'd56,  32'h00000002, "coverage c.bnez");
            32'd60:  check_store(32'd60,  32'h00000003, "coverage c.j");

            32'd68:  check_store(32'd68,  32'h000000d6, "coverage c.jal link");
            32'd72:  check_store(32'd72,  32'h00000004, "coverage c.jal target");
            32'd76:  check_store(32'd76,  32'h00000005, "coverage c.jr");
            32'd80:  check_store(32'd80,  32'h00000112, "coverage c.jalr link");

            32'd84: begin
              check_store(32'd84, 32'h00000006, "coverage c.jalr target");
              done = 1;
            end

            default: begin
              $display("FAIL unexpected coverage store: DataAdr=%h WriteData=%h",
                       DataAdr, WriteData);
              $stop;
            end
          endcase
        end

        TEST_MATMUL_RV32I,
        TEST_MATMUL_RVC: begin
          case (DataAdr)
            // Inicialización de A
            32'd0:  check_store(32'd0,  32'h00000001, "matmul A[0][0]");
            32'd4:  check_store(32'd4,  32'h00000002, "matmul A[0][1]");
            32'd8:  check_store(32'd8,  32'h00000003, "matmul A[1][0]");
            32'd12: check_store(32'd12, 32'h00000004, "matmul A[1][1]");

            // Inicialización de B
            32'd16: check_store(32'd16, 32'h00000005, "matmul B[0][0]");
            32'd20: check_store(32'd20, 32'h00000006, "matmul B[0][1]");
            32'd24: check_store(32'd24, 32'h00000007, "matmul B[1][0]");
            32'd28: check_store(32'd28, 32'h00000008, "matmul B[1][1]");

            // Resultado C = A * B
            32'd32: check_store(32'd32, 32'h00000013, "matmul C[0][0]");
            32'd36: check_store(32'd36, 32'h00000016, "matmul C[0][1]");
            32'd40: check_store(32'd40, 32'h0000002b, "matmul C[1][0]");

            32'd44: begin
              check_store(32'd44, 32'h00000032, "matmul C[1][1]");
              done = 1;
            end

            default: begin
              $display("FAIL unexpected matmul store: phase=%0d DataAdr=%h WriteData=%h",
                       phase, DataAdr, WriteData);
              $stop;
            end
          endcase
        end

        default: begin
          $display("FAIL store outside active test: DataAdr=%h WriteData=%h",
                   DataAdr, WriteData);
          $stop;
        end
      endcase
    end
  end

endmodule