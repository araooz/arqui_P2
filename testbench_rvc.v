`timescale 1ns/1ps

module testbench_rvc();

  reg clk;
  reg reset;

  wire [31:0] WriteData;
  wire [31:0] DataAdr;
  wire MemWrite;

  integer phase;
  integer done;
  integer i;
  integer store_count;
  integer expected_stores;
  time phase_start_time;
  reg [31:0] expected_mask;
  reg [31:0] seen_mask;

  localparam TEST_NONE          = 0;
  localparam TEST_COVERAGE      = 1;
  localparam TEST_MATMUL_RV32I  = 2;
  localparam TEST_MATMUL_RVC    = 3;

  // 22 stores in rvc_coverage.mem
  localparam [31:0] MASK_COVERAGE = 32'h003fffff;

  // 12 stores in each matmul program
  localparam [31:0] MASK_MATMUL   = 32'h00000fff;

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
    store_count = 0;
    expected_stores = 0;
    expected_mask = 32'b0;
    seen_mask = 32'b0;
    reset = 1;

    run_coverage();
    run_matmul_rv32i();
    run_matmul_rvc();

    $display("[%0t] ALL RVC FINAL TESTS PASSED", $time);
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

  task start_phase;
    input [31:0] new_phase;
    input [31:0] target_stores;
    input [31:0] target_mask;
    begin
      phase = new_phase;
      done = 0;
      store_count = 0;
      expected_stores = target_stores;
      expected_mask = target_mask;
      seen_mask = 32'b0;
      phase_start_time = $time;
    end
  endtask

  task wait_done;
    input [31:0] max_cycles;
    input [255:0] phase_name;
    integer cycles;
    begin
      cycles = 0;

      while ((done == 0) && (cycles < max_cycles)) begin
        @(negedge clk);
        cycles = cycles + 1;
      end

      if (done == 0) begin
        $display("[%0t] FAIL timeout in %0s after %0d cycles. Stores checked: %0d/%0d. seen_mask=%h expected_mask=%h",
                 $time, phase_name, max_cycles, store_count, expected_stores,
                 seen_mask, expected_mask);
        $stop;
      end
      else begin
        $display("[%0t] DONE %0s after %0d cycles. Stores checked: %0d/%0d. Elapsed time: %0t ns",
                 $time, phase_name, cycles, store_count, expected_stores,
                 $time - phase_start_time);
      end
    end
  endtask

  task run_coverage;
    begin
      $display("========================================");
      $display("Running rvc_coverage.mem");
      $display("========================================");

      start_phase(TEST_COVERAGE, 22, MASK_COVERAGE);
      clear_state();
      $readmemh("rvc_coverage.mem", dut.imem.RAM);
      reset_cpu();
      wait_done(2000, "rvc_coverage.mem");

      $display("[%0t] RVC coverage test PASSED", $time);
    end
  endtask

  task run_matmul_rv32i;
    begin
      $display("========================================");
      $display("Running matmul2x2_rv32i.mem");
      $display("========================================");

      start_phase(TEST_MATMUL_RV32I, 12, MASK_MATMUL);
      clear_state();
      $readmemh("matmul2x2_rv32i.mem", dut.imem.RAM);
      reset_cpu();
      wait_done(5000, "matmul2x2_rv32i.mem");

      $display("[%0t] Matrix multiplication RV32I test PASSED", $time);
    end
  endtask

  task run_matmul_rvc;
    begin
      $display("========================================");
      $display("Running matmul2x2_rvc.mem");
      $display("========================================");

      start_phase(TEST_MATMUL_RVC, 12, MASK_MATMUL);
      clear_state();
      $readmemh("matmul2x2_rvc.mem", dut.imem.RAM);
      reset_cpu();
      wait_done(5000, "matmul2x2_rvc.mem");

      $display("[%0t] Matrix multiplication RVC test PASSED", $time);
    end
  endtask

  task check_store;
    input [31:0] bit_index;
    input [31:0] expected_addr;
    input [31:0] expected_data;
    input [255:0] name;
    reg [31:0] bit_mask;
    reg [31:0] new_seen_mask;
    begin
      bit_mask = (32'h1 << bit_index);

      if (DataAdr !== expected_addr) begin
        $display("[%0t] FAIL %0s: expected address=%h got address=%h WriteData=%h",
                 $time, name, expected_addr, DataAdr, WriteData);
        $stop;
      end
      else if ((seen_mask & bit_mask) != 32'b0) begin
        $display("[%0t] FAIL duplicate store for %0s: DataAdr=%h WriteData=%h",
                 $time, name, DataAdr, WriteData);
        $stop;
      end
      else if (WriteData !== expected_data) begin
        $display("[%0t] FAIL %0s: DataAdr=%h expected=%h got=%h",
                 $time, name, DataAdr, expected_data, WriteData);
        $stop;
      end
      else begin
        new_seen_mask = seen_mask | bit_mask;
        seen_mask = new_seen_mask;
        store_count = store_count + 1;

        $display("[%0t] PASS phase=%0d %0s: mem[%0d] = %h (%0d/%0d)",
                 $time, phase, name, expected_addr, WriteData,
                 store_count, expected_stores);

        if (new_seen_mask == expected_mask)
          done = 1;
      end
    end
  endtask

  always @(negedge clk) begin
    if (!reset && MemWrite) begin
      case (phase)

        TEST_COVERAGE: begin
          case (DataAdr)
            32'd0:   check_store(0,  32'd0,   32'h0000000c, "coverage c.addi / c.add");
            32'd4:   check_store(1,  32'd4,   32'h0000000e, "coverage c.sub");
            32'd8:   check_store(2,  32'd8,   32'h00000008, "coverage c.and");
            32'd12:  check_store(3,  32'd12,  32'h0000000e, "coverage c.or");
            32'd16:  check_store(4,  32'd16,  32'h00000006, "coverage c.xor");
            32'd20:  check_store(5,  32'd20,  32'h0000000c, "coverage c.slli");
            32'd24:  check_store(6,  32'd24,  32'h00000008, "coverage c.srli");
            32'd28:  check_store(7,  32'd28,  32'hfffffffc, "coverage c.srai");
            32'd32:  check_store(8,  32'd32,  32'h00001000, "coverage c.lui");
            32'd36:  check_store(9,  32'd36,  32'h00000008, "coverage c.andi");

            32'd40:  check_store(10, 32'd40,  32'h0000007b, "coverage c.sw");
            32'd44:  check_store(11, 32'd44,  32'h0000007b, "coverage c.lw");
            32'd64:  check_store(12, 32'd64,  32'h0000004d, "coverage c.swsp");
            32'd48:  check_store(13, 32'd48,  32'h0000004d, "coverage c.lwsp");

            32'd52:  check_store(14, 32'd52,  32'h00000001, "coverage c.beqz");
            32'd56:  check_store(15, 32'd56,  32'h00000002, "coverage c.bnez");
            32'd60:  check_store(16, 32'd60,  32'h00000003, "coverage c.j");

            32'd68:  check_store(17, 32'd68,  32'h000000d6, "coverage c.jal link");
            32'd72:  check_store(18, 32'd72,  32'h00000004, "coverage c.jal target");
            32'd76:  check_store(19, 32'd76,  32'h00000005, "coverage c.jr");
            32'd80:  check_store(20, 32'd80,  32'h00000112, "coverage c.jalr link");
            32'd84:  check_store(21, 32'd84,  32'h00000006, "coverage c.jalr target");

            default: begin
              $display("[%0t] FAIL unexpected coverage store: DataAdr=%h WriteData=%h",
                       $time, DataAdr, WriteData);
              $stop;
            end
          endcase
        end

        TEST_MATMUL_RV32I,
        TEST_MATMUL_RVC: begin
          case (DataAdr)
            32'd0:  check_store(0,  32'd0,  32'h00000001, "matmul A[0][0]");
            32'd4:  check_store(1,  32'd4,  32'h00000002, "matmul A[0][1]");
            32'd8:  check_store(2,  32'd8,  32'h00000003, "matmul A[1][0]");
            32'd12: check_store(3,  32'd12, 32'h00000004, "matmul A[1][1]");

            32'd16: check_store(4,  32'd16, 32'h00000005, "matmul B[0][0]");
            32'd20: check_store(5,  32'd20, 32'h00000006, "matmul B[0][1]");
            32'd24: check_store(6,  32'd24, 32'h00000007, "matmul B[1][0]");
            32'd28: check_store(7,  32'd28, 32'h00000008, "matmul B[1][1]");

            32'd32: check_store(8,  32'd32, 32'h00000013, "matmul C[0][0]");
            32'd36: check_store(9,  32'd36, 32'h00000016, "matmul C[0][1]");
            32'd40: check_store(10, 32'd40, 32'h0000002b, "matmul C[1][0]");
            32'd44: check_store(11, 32'd44, 32'h00000032, "matmul C[1][1]");

            default: begin
              $display("[%0t] FAIL unexpected matmul store: phase=%0d DataAdr=%h WriteData=%h",
                       $time, phase, DataAdr, WriteData);
              $stop;
            end
          endcase
        end

        default: begin
          $display("[%0t] FAIL store outside active test: DataAdr=%h WriteData=%h",
                   $time, DataAdr, WriteData);
          $stop;
        end
      endcase
    end
  end

endmodule
