`timescale 1ns/1ps

module testbench_e1_final();

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

  localparam TEST_NONE     = 0;
  localparam TEST_NODEP    = 1;
  localparam TEST_FORWARD  = 2;
  localparam TEST_STALL    = 3;
  localparam TEST_FLUSH    = 4;

  // prog1_nodep.mem has 10 checked stores.
  localparam [31:0] MASK_NODEP   = 32'h000003ff;

  // The hazard programs use one final checked store each.
  localparam [31:0] MASK_SINGLE  = 32'h00000001;

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

    run_nodep();
    run_forward();
    run_stall();
    run_flush();

    $display("[%0t] ALL E1 FINAL TESTS PASSED", $time);
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

  task run_nodep;
    begin
      $display("========================================");
      $display("Running prog1_nodep.mem");
      $display("========================================");

      start_phase(TEST_NODEP, 10, MASK_NODEP);
      clear_state();
      $readmemh("prog1_nodep.mem", dut.imem.RAM);
      reset_cpu();
      wait_done(1000, "prog1_nodep.mem");

      $display("[%0t] Program without dependencies test PASSED", $time);
    end
  endtask

  task run_forward;
    begin
      $display("========================================");
      $display("Running prog2_forward.mem");
      $display("========================================");

      start_phase(TEST_FORWARD, 1, MASK_SINGLE);
      clear_state();
      $readmemh("prog2_forward.mem", dut.imem.RAM);
      reset_cpu();
      wait_done(1000, "prog2_forward.mem");

      $display("[%0t] Forwarding test PASSED", $time);
    end
  endtask

  task run_stall;
    begin
      $display("========================================");
      $display("Running prog3_stall.mem");
      $display("========================================");

      start_phase(TEST_STALL, 1, MASK_SINGLE);
      clear_state();

      // The load-use test loads from address 8.
      // This initialization makes the test independent from previous programs.
      dut.dmem.RAM[2] = 32'd100;

      $readmemh("prog3_stall.mem", dut.imem.RAM);
      reset_cpu();
      wait_done(1000, "prog3_stall.mem");

      $display("[%0t] Stalling test PASSED", $time);
    end
  endtask

  task run_flush;
    begin
      $display("========================================");
      $display("Running prog4_flush.mem");
      $display("========================================");

      start_phase(TEST_FLUSH, 6, 32'h0000003f);
      clear_state();
      $readmemh("prog4_flush.mem", dut.imem.RAM);
      reset_cpu();
      wait_done(1000, "prog4_flush.mem");

      $display("[%0t] Flushing test PASSED", $time);
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

  task log_optional_store;
    input [255:0] name;
    begin
      $display("[%0t] INFO optional store in phase=%0d %0s: mem[%0d] = %h",
               $time, phase, name, DataAdr, WriteData);
    end
  endtask

  always @(negedge clk) begin
    if (!reset && MemWrite) begin
      case (phase)

        TEST_NODEP: begin
          case (DataAdr)
            32'd0:  check_store(0, 32'd0,  32'h00000014, "nodep add");
            32'd4:  check_store(1, 32'd4,  32'h0000000c, "nodep sub");
            32'd8:  check_store(2, 32'd8,  32'h00000040, "nodep sll");
            32'd12: check_store(3, 32'd12, 32'h00000014, "nodep xor");
            32'd16: check_store(4, 32'd16, 32'h00000001, "nodep srl");
            32'd20: check_store(5, 32'd20, 32'h00000001, "nodep sra");
            32'd24: check_store(6, 32'd24, 32'h00000014, "nodep or");
            32'd28: check_store(7, 32'd28, 32'h00000000, "nodep and");
            32'd32: check_store(8, 32'd32, 32'h12345000, "nodep lui");
            32'd36: check_store(9, 32'd36, 32'h00000014, "nodep lw");
            default: begin
              $display("[%0t] FAIL unexpected nodep store: DataAdr=%h WriteData=%h",
                       $time, DataAdr, WriteData);
              $stop;
            end
          endcase
        end

        TEST_FORWARD: begin
          case (DataAdr)
            32'd4: check_store(0, 32'd4, 32'h00000014, "forwarding final sw");
            default: begin
              $display("[%0t] FAIL unexpected forwarding store: DataAdr=%h WriteData=%h",
                       $time, DataAdr, WriteData);
              $stop;
            end
          endcase
        end

        TEST_STALL: begin
          case (DataAdr)
            // Some versions of the stall program explicitly store the source value at mem[8].
            // This store is not the final assertion, so it is logged without marking the phase done.
            32'd8:  log_optional_store("stall setup value");
            32'd12: check_store(0, 32'd12, 32'h000000c8, "stall load-use result");
            default: begin
              $display("[%0t] FAIL unexpected stalling store: DataAdr=%h WriteData=%h",
                       $time, DataAdr, WriteData);
              $stop;
            end
          endcase
        end

        TEST_FLUSH: begin
          case (DataAdr)
            // Branch case:
            // beq x1, x2 jumps to the target. The wrong-path writes to x3 are flushed.
            32'd16: check_store(0, 32'd16, 32'h0000000a, "flush branch target result");
            32'd20: check_store(1, 32'd20, 32'h00000000, "flush branch wrong-path register");

            // JAL case:
            // jal skips the wrong-path addi x5, x0, 99 and writes PC+4 into x6.
            32'd24: check_store(2, 32'd24, 32'h00000007, "flush jal target result");
            32'd28: check_store(3, 32'd28, 32'h00000040, "flush jal link");

            // JALR case:
            // jalr jumps to the address in x7 and writes PC+4 into x8.
            32'd32: check_store(4, 32'd32, 32'h00000008, "flush jalr target result");
            32'd36: check_store(5, 32'd36, 32'h00000070, "flush jalr link");

            default: begin
              $display("[%0t] FAIL unexpected flushing store: DataAdr=%h WriteData=%h",
                       $time, DataAdr, WriteData);
              $stop;
            end
          endcase
        end

        default: begin
          $display("[%0t] FAIL store outside active E1 test: DataAdr=%h WriteData=%h",
                   $time, DataAdr, WriteData);
          $stop;
        end
      endcase
    end
  end

endmodule
