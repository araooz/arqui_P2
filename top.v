module top(input  clk, reset, 
           output [31:0] WriteData, DataAdr, 
           output MemWrite);
  
  wire [31:0] PC;
  wire [31:0] InstrRawF;
  wire [31:0] ReadData; 
  
  riscvpipeline rvpipe(
    .clk(clk), 
    .reset(reset), 
    .PC(PC), 
    .InstrRawF(InstrRawF), 
    .MemWrite(MemWrite), 
    .DataAdr(DataAdr), 
    .WriteData(WriteData), 
    .ReadData(ReadData)
  ); 

  imem imem(
    .a(PC), 
    .rd(InstrRawF)
  ); 

  dmem dmem(
    .clk(clk), 
    .we(MemWrite), 
    .a(DataAdr), 
    .wd(WriteData), 
    .rd(ReadData)
  ); 

endmodule