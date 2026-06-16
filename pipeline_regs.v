module if_id_reg(input  clk, reset,
                 input  enable, clear,
                 input  [31:0] PCF,
                 input  [31:0] InstrF,
                 input  [31:0] PCPlus4F,
                 output reg [31:0] PCD,
                 output reg [31:0] InstrD,
                 output reg [31:0] PCPlus4D);

  always @(posedge clk) begin
    if (reset || clear) begin
      PCD <= 32'b0;
      InstrD <= 32'b0;
      PCPlus4D <= 32'b0;
    end else if (enable) begin
      PCD <= PCF;
      InstrD <= InstrF;
      PCPlus4D <= PCPlus4F;
    end
  end
endmodule

module id_ex_reg(input  clk, reset,
                 input  clear,
                 input  [31:0] InstrD,
                 input  RegWriteD,
                 input  [1:0] ResultSrcD,
                 input  MemWriteD,
                 input  JumpD,
                 input  JalrD,
                 input  BranchD,
                 input  [3:0] ALUControlD,
                 input  ALUSrcD,
                 input  [31:0] RD1D,
                 input  [31:0] RD2D,
                 input  [31:0] PCD,
                 input  [4:0]  Rs1D,
                 input  [4:0]  Rs2D,
                 input  [4:0]  RdD,
                 input  [31:0] ImmExtD,
                 input  [31:0] PCPlus4D,
                 input  [2:0]  Funct3D,
                 output reg [31:0] InstrE,
                 output reg RegWriteE,
                 output reg [1:0] ResultSrcE,
                 output reg MemWriteE,
                 output reg JumpE,
                 output reg JalrE,
                 output reg BranchE,
                 output reg [3:0] ALUControlE,
                 output reg ALUSrcE,
                 output reg [31:0] RD1E,
                 output reg [31:0] RD2E,
                 output reg [31:0] PCE,
                 output reg [4:0]  Rs1E,
                 output reg [4:0]  Rs2E,
                 output reg [4:0]  RdE,
                 output reg [31:0] ImmExtE,
                 output reg [31:0] PCPlus4E,
                 output reg [2:0]  Funct3E);

  always @(posedge clk) begin
    if (reset || clear) begin
      InstrE <= 32'b0;
      RegWriteE <= 1'b0;
      ResultSrcE <= 2'b00;
      MemWriteE <= 1'b0;
      JumpE <= 1'b0;
      JalrE <= 1'b0;
      BranchE <= 1'b0;
      ALUControlE <= 4'b0000;
      ALUSrcE <= 1'b0;
      RD1E <= 32'b0;
      RD2E <= 32'b0;
      PCE <= 32'b0;
      Rs1E <= 5'b0;
      Rs2E <= 5'b0;
      RdE <= 5'b0;
      ImmExtE <= 32'b0;
      PCPlus4E <= 32'b0;
      Funct3E <= 3'b000;
    end else begin
      InstrE <= InstrD;
      RegWriteE <= RegWriteD;
      ResultSrcE <= ResultSrcD;
      MemWriteE <= MemWriteD;
      JumpE <= JumpD;
      JalrE <= JalrD;
      BranchE <= BranchD;
      ALUControlE <= ALUControlD;
      ALUSrcE <= ALUSrcD;
      RD1E <= RD1D;
      RD2E <= RD2D;
      PCE <= PCD;
      Rs1E <= Rs1D;
      Rs2E <= Rs2D;
      RdE <= RdD;
      ImmExtE <= ImmExtD;
      PCPlus4E <= PCPlus4D;
      Funct3E <= Funct3D;
    end
  end
endmodule

module ex_mem_reg(input  clk, reset,
                  input  [31:0] InstrE,
                  input  RegWriteE,
                  input  [1:0] ResultSrcE,
                  input  MemWriteE,
                  input  [31:0] ALUResultE,
                  input  [31:0] WriteDataE,
                  input  [4:0]  RdE,
                  input  [31:0] PCPlus4E,
                  output reg [31:0] InstrM,
                  output reg RegWriteM,
                  output reg [1:0] ResultSrcM,
                  output reg MemWriteM,
                  output reg [31:0] ALUResultM,
                  output reg [31:0] WriteDataM,
                  output reg [4:0]  RdM,
                  output reg [31:0] PCPlus4M);

  always @(posedge clk) begin
    if (reset) begin
      InstrM <= 32'b0;
      RegWriteM <= 1'b0;
      ResultSrcM <= 2'b00;
      MemWriteM <= 1'b0;
      ALUResultM <= 32'b0;
      WriteDataM <= 32'b0;
      RdM <= 5'b0;
      PCPlus4M <= 32'b0;
    end else begin
      InstrM <= InstrE;
      RegWriteM <= RegWriteE;
      ResultSrcM <= ResultSrcE;
      MemWriteM <= MemWriteE;
      ALUResultM <= ALUResultE;
      WriteDataM <= WriteDataE;
      RdM <= RdE;
      PCPlus4M <= PCPlus4E;
    end
  end
endmodule

module mem_wb_reg(input  clk, reset,
                  input  [31:0] InstrM,
                  input  RegWriteM,
                  input  [1:0] ResultSrcM,
                  input  [31:0] ReadDataM,
                  input  [31:0] ALUResultM,
                  input  [31:0] PCPlus4M,
                  input  [4:0]  RdM,
                  output reg [31:0] InstrW,
                  output reg RegWriteW,
                  output reg [1:0] ResultSrcW,
                  output reg [31:0] ReadDataW,
                  output reg [31:0] ALUResultW,
                  output reg [31:0] PCPlus4W,
                  output reg [4:0]  RdW);

  always @(posedge clk) begin
    if (reset) begin
      InstrW <= 32'b0;
      RegWriteW <= 1'b0;
      ResultSrcW <= 2'b00;
      ReadDataW <= 32'b0;
      ALUResultW <= 32'b0;
      PCPlus4W <= 32'b0;
      RdW <= 5'b0;
    end else begin
      InstrW <= InstrM;
      RegWriteW <= RegWriteM;
      ResultSrcW <= ResultSrcM;
      ReadDataW <= ReadDataM;
      ALUResultW <= ALUResultM;
      PCPlus4W <= PCPlus4M;
      RdW <= RdM;
    end
  end
endmodule