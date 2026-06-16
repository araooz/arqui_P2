module testbench;
  reg clk;
  reg reset;
  wire [31:0] WriteData;
  wire [31:0] DataAdr;
  wire MemWrite;

  integer errors;

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
    reset = 1;
    errors = 0;
    #22;
    reset = 0;
    #900;

    check_word(0, 32'd7);
    check_word(4, 32'd12);
    check_word(8, 32'd1);
    check_word(12, 32'd2);
    check_word(16, 32'd3);
    check_word(20, 32'd4);
    check_word(24, 32'h12345000);
    check_word(28, 32'd15);
    check_word(32, 32'd60);
    check_word(36, 32'd30);
    check_word(40, 32'd15);
    check_word(44, 32'd18);
    check_word(48, 32'd160);
    check_word(52, 32'd21);
    check_word(56, 32'd0);

    if (errors == 0)
      $display("Pipeline test passed");
    else
      $display("Pipeline test failed with %0d errors", errors);

    $stop;
  end

  task check_word;
    input [31:0] addr;
    input [31:0] expected;
    begin
      if (dut.dmem.RAM[addr[31:2]] !== expected) begin
        $display("Mismatch at address %0d: expected %h, got %h",
                 addr, expected, dut.dmem.RAM[addr[31:2]]);
        errors = errors + 1;
      end
    end
  endtask
endmodule