module testbench;
  reg          clk;
  reg          reset;
  wire [31:0]  WriteData;
  wire [31:0]  DataAdr;
  wire         MemWrite;

  integer i;
  integer errors;
  integer total_errors;

  top dut(
    .clk(clk),
    .reset(reset),
    .WriteData(WriteData),
    .DataAdr(DataAdr),
    .MemWrite(MemWrite)
  );

  always begin
    clk = 1;
    #5;
    clk = 0;
    #5;
  end

  task clear_dmem;
    begin
      for (i = 0; i < 64; i = i + 1)
        dut.dmem.RAM[i] = 32'b0;
    end
  endtask

  task load_program;
    input [1023:0] memfile;
    begin
      for (i = 0; i < 64; i = i + 1)
        dut.imem.RAM[i] = 32'h00000013;
      $readmemh(memfile, dut.imem.RAM);
    end
  endtask

  task run_program;
    input [1023:0] name;
    input [1023:0] memfile;
    input integer cycles;
    begin
      $display("");
      $display("Running %0s", name);

      load_program(memfile);
      clear_dmem();

      reset = 1;
      repeat (3) @(negedge clk);
      reset = 0;
      repeat (cycles) @(negedge clk);
    end
  endtask

  task check_mem;
    input [31:0] byte_addr;
    input [31:0] expected;
    input [1023:0] label;
    reg [31:0] actual;
    begin
      actual = dut.dmem.RAM[byte_addr[31:2]];
      if (actual !== expected) begin
        $display("  FAIL %0s: mem[%0d] expected %h, got %h",
                 label, byte_addr, expected, actual);
        errors = errors + 1;
        total_errors = total_errors + 1;
      end else begin
        $display("  PASS %0s: mem[%0d] = %h", label, byte_addr, actual);
      end
    end
  endtask

  initial begin
    reset = 1;
    errors = 0;
    total_errors = 0;

    #1;

    run_program("prog1_nodep", "prog1_nodep.mem", 80);
    check_mem(0,  32'd20,         "add");
    check_mem(4,  32'd12,         "sub");
    check_mem(8,  32'd64,         "sll");
    check_mem(12, 32'd20,         "xor");
    check_mem(16, 32'd1,          "srl");
    check_mem(20, 32'd1,          "sra");
    check_mem(24, 32'd20,         "or");
    check_mem(28, 32'd0,          "and");
    check_mem(32, 32'h12345000,   "lui");
    check_mem(36, 32'd20,         "lw");

    run_program("prog2_forward", "prog2_forward.mem", 50);
    check_mem(4, 32'd20, "forwarding result");

    run_program("prog3_stall", "prog3_stall.mem", 60);
    check_mem(8,  32'd100, "load source");
    check_mem(12, 32'd200, "load-use result");

    run_program("prog4_flush", "prog4_flush.mem", 100);
    check_mem(16, 32'd10,  "branch target result");
    check_mem(20, 32'd0,   "flushed branch wrong path");
    check_mem(24, 32'd7,   "jal target result");
    check_mem(28, 32'd64,  "jal return address");
    check_mem(32, 32'd8,   "jalr target result");
    check_mem(36, 32'd112, "jalr return address");

    if (total_errors == 0)
      $display("All pipeline tests passed");
    else
      $display("Pipeline tests failed with %0d errors", total_errors);

    $stop;
  end
endmodule
