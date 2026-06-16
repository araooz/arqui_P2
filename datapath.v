module datapath(input  clk, reset,
                input  [1:0]  ResultSrcD, 
                input  MemWriteD, Branch,
                input  ALUSrcD,
                input  RegWriteD,
                input  JumpD,
                input  JalrD,
                input  [2:0]  ImmSrcD, 
                input  [3:0]  ALUControlD,
                output [6:0]  op,
                output [2:0]  funct3,
                output        funct7b5,
                output [31:0] PC,
                input  [31:0] Instr,
                output MemWrite,
                output [31:0] ALUResult, WriteData, 
                input  [31:0] ReadData);
  
  localparam WIDTH = 32;

  wire        StallF, StallD, FlushD, FlushE;
  wire [1:0]  ForwardAE, ForwardBE;

  wire [31:0] PCF, PCNextF, PCPlus4F;

  wire [31:0] InstrD, PCD, PCPlus4D;
  wire [31:0] RD1D, RD2D, ImmExtD;
  wire [4:0]  Rs1D, Rs2D, RdD;

  wire        RegWriteE, MemWriteE, JumpE, JalrE, BranchE, ALUSrcE;
  wire [1:0]  ResultSrcE;
  wire [3:0]  ALUControlE;
  wire [31:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;
  wire [4:0]  Rs1E, Rs2E, RdE;
  wire [2:0]  Funct3E;
  wire [31:0] SrcAE, SrcBE, WriteDataE, ALUResultE;
  wire [31:0] PCTargetBaseE, PCTargetRawE, PCTargetE;
  wire        ZeroE, BranchTakenE, PCSrcE;

  wire        RegWriteM;
  wire [1:0]  ResultSrcM;
  wire [31:0] ALUResultM, WriteDataM, PCPlus4M;
  wire [4:0]  RdM;

  wire        RegWriteW;
  wire [1:0]  ResultSrcW;
  wire [31:0] ReadDataW, ALUResultW, PCPlus4W, ResultW;
  wire [4:0]  RdW;

  hazard_unit hu(
    .Rs1D(Rs1D),
    .Rs2D(Rs2D),
    .Rs1E(Rs1E),
    .Rs2E(Rs2E),
    .RdE(RdE),
    .RdM(RdM),
    .RdW(RdW),
    .RegWriteM(RegWriteM),
    .RegWriteW(RegWriteW),
    .ResultSrcE(ResultSrcE),
    .PCSrcE(PCSrcE),
    .StallF(StallF),
    .StallD(StallD),
    .FlushD(FlushD),
    .FlushE(FlushE),
    .ForwardAE(ForwardAE),
    .ForwardBE(ForwardBE)
  );

  assign PC = PCF;
  assign ALUResult = ALUResultM;
  assign WriteData = WriteDataM;
  assign MemWrite = MemWriteM;

  // IF stage
  mux2 #(WIDTH)  pcmux(
    .d0(PCPlus4F), 
    .d1(PCTargetE), 
    .s(PCSrcE), 
    .y(PCNextF)
  ); 

  pc_reg      pcreg(
    .clk(clk), 
    .reset(reset), 
    .enable(~StallF),
    .PCNext(PCNextF), 
    .PC(PCF)
  ); 

  adder       pcadd4(
    .a(PCF), 
    .b(32'd4),
    .y(PCPlus4F)
  ); 

  if_id_reg   ifidreg(
    .clk(clk),
    .reset(reset),
    .enable(~StallD),
    .clear(FlushD),
    .PCF(PCF),
    .InstrF(Instr),
    .PCPlus4F(PCPlus4F),
    .PCD(PCD),
    .InstrD(InstrD),
    .PCPlus4D(PCPlus4D)
  ); 

  // ID stage
  assign op = InstrD[6:0];
  assign funct3 = InstrD[14:12];
  assign funct7b5 = InstrD[30];
  assign Rs1D = InstrD[19:15];
  assign Rs2D = InstrD[24:20];
  assign RdD = InstrD[11:7];

  regfile     rf(
    .clk(clk), 
    .we3(RegWriteW), 
    .a1(Rs1D), 
    .a2(Rs2D), 
    .a3(RdW), 
    .wd3(ResultW), 
    .rd1(RD1D), 
    .rd2(RD2D)
  ); 

  extend      ext(
    .instr(InstrD[31:7]), 
    .immsrc(ImmSrcD), 
    .immext(ImmExtD)
  ); 

  id_ex_reg   idexreg(
    .clk(clk),
    .reset(reset),
    .clear(FlushE),
    .RegWriteD(RegWriteD),
    .ResultSrcD(ResultSrcD),
    .MemWriteD(MemWriteD),
    .JumpD(JumpD),
    .JalrD(JalrD),
    .BranchD(Branch),
    .ALUControlD(ALUControlD),
    .ALUSrcD(ALUSrcD),
    .RD1D(RD1D),
    .RD2D(RD2D),
    .PCD(PCD),
    .Rs1D(Rs1D),
    .Rs2D(Rs2D),
    .RdD(RdD),
    .ImmExtD(ImmExtD),
    .PCPlus4D(PCPlus4D),
    .Funct3D(funct3),
    .RegWriteE(RegWriteE),
    .ResultSrcE(ResultSrcE),
    .MemWriteE(MemWriteE),
    .JumpE(JumpE),
    .JalrE(JalrE),
    .BranchE(BranchE),
    .ALUControlE(ALUControlE),
    .ALUSrcE(ALUSrcE),
    .RD1E(RD1E),
    .RD2E(RD2E),
    .PCE(PCE),
    .Rs1E(Rs1E),
    .Rs2E(Rs2E),
    .RdE(RdE),
    .ImmExtE(ImmExtE),
    .PCPlus4E(PCPlus4E),
    .Funct3E(Funct3E)
  );

  // EX stage
  mux3 #(WIDTH)  forwardamux(
    .d0(RD1E),
    .d1(ResultW),
    .d2(ALUResultM),
    .s(ForwardAE),
    .y(SrcAE)
  );

  mux3 #(WIDTH)  forwardbmux(
    .d0(RD2E),
    .d1(ResultW),
    .d2(ALUResultM),
    .s(ForwardBE),
    .y(WriteDataE)
  );

  mux2 #(WIDTH)  srcbmux(
    .d0(WriteDataE), 
    .d1(ImmExtE), 
    .s(ALUSrcE), 
    .y(SrcBE)
  ); 

  alu         alu(
    .a(SrcAE), 
    .b(SrcBE), 
    .alucontrol(ALUControlE), 
    .result(ALUResultE), 
    .zero(ZeroE)
  ); 

  mux2 #(WIDTH)  pctargetbasemux(
    .d0(PCE),
    .d1(SrcAE),
    .s(JalrE),
    .y(PCTargetBaseE)
  );

  adder       pcaddtarget(
    .a(PCTargetBaseE), 
    .b(ImmExtE), 
    .y(PCTargetRawE)
  ); 

  assign PCTargetE = JalrE ? {PCTargetRawE[31:1], 1'b0} : PCTargetRawE;

  branch_unit branchunit(
    .a(SrcAE),
    .b(WriteDataE),
    .funct3(Funct3E),
    .taken(BranchTakenE)
  );

  assign PCSrcE = (BranchE & BranchTakenE) | JumpE;

  ex_mem_reg  exmemreg(
    .clk(clk),
    .reset(reset),
    .RegWriteE(RegWriteE),
    .ResultSrcE(ResultSrcE),
    .MemWriteE(MemWriteE),
    .ALUResultE(ALUResultE),
    .WriteDataE(WriteDataE),
    .RdE(RdE),
    .PCPlus4E(PCPlus4E),
    .RegWriteM(RegWriteM),
    .ResultSrcM(ResultSrcM),
    .MemWriteM(MemWriteM),
    .ALUResultM(ALUResultM),
    .WriteDataM(WriteDataM),
    .RdM(RdM),
    .PCPlus4M(PCPlus4M)
  );

  // MEM stage
  mem_wb_reg  memwbreg(
    .clk(clk),
    .reset(reset),
    .RegWriteM(RegWriteM),
    .ResultSrcM(ResultSrcM),
    .ReadDataM(ReadData),
    .ALUResultM(ALUResultM),
    .PCPlus4M(PCPlus4M),
    .RdM(RdM),
    .RegWriteW(RegWriteW),
    .ResultSrcW(ResultSrcW),
    .ReadDataW(ReadDataW),
    .ALUResultW(ALUResultW),
    .PCPlus4W(PCPlus4W),
    .RdW(RdW)
  ); 

  // WB stage
  mux3 #(WIDTH)  resultmux(
    .d0(ALUResultW), 
    .d1(ReadDataW), 
    .d2(PCPlus4W), 
    .s(ResultSrcW), 
    .y(ResultW)
  ); 
endmodule