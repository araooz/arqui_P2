module riscvpipeline(input  clk, reset,
                     output [31:0] PC,
                     input  [31:0] InstrRawF,
                     output MemWrite,
                     output [31:0] DataAdr, 
                     output [31:0] WriteData,
                     input  [31:0] ReadData);
  
  wire [31:0] ALUResult; 
  
  wire       ALUSrc, RegWrite, Jump, Jalr, Branch, MemWriteD; 
  wire [1:0] ResultSrc; 
  wire [2:0] ImmSrc; 
  wire [3:0] ALUControl; 
  wire [6:0] op; 
  wire [2:0] funct3; 
  wire       funct7b5; 

  // DataAdr is connected to ALUResult
  assign DataAdr = ALUResult;

  controller c(
    .op(op), 
    .funct3(funct3), 
    .funct7b5(funct7b5), 
    .ResultSrc(ResultSrc), 
    .MemWrite(MemWriteD), 
    .Branch(Branch),
    .ALUSrc(ALUSrc), 
    .RegWrite(RegWrite), 
    .Jump(Jump),
    .Jalr(Jalr),
    .ImmSrc(ImmSrc), 
    .ALUControl(ALUControl)
  ); 
  
  datapath dp(
    .clk(clk), 
    .reset(reset), 
    .ResultSrcD(ResultSrc), 
    .MemWriteD(MemWriteD),
    .Branch(Branch),
    .ALUSrcD(ALUSrc), 
    .RegWriteD(RegWrite),
    .JumpD(Jump),
    .JalrD(Jalr),
    .ImmSrcD(ImmSrc), 
    .ALUControlD(ALUControl),
    .op(op),
    .funct3(funct3),
    .funct7b5(funct7b5),
    .PC(PC), 
    .InstrRawF(InstrRawF),
    .MemWrite(MemWrite),
    .ALUResult(ALUResult), 
    .WriteData(WriteData), 
    .ReadData(ReadData)
  ); 
endmodule