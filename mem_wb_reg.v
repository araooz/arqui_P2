module mem_wb_reg (
	input clk,
	input reset,
	input clear,

	input RegWriteM,
	input [1:0] ResultSrcM,
	input [31:0] ReadDataM,
	input [31:0] ALUResultM,
	input [31:0] PCPlus4M,
	input [4:0] RdM,

	output reg RegWriteW,
	output reg [1:0] ResultSrcW,
	output reg [31:0] ReadDataW,
	output reg [31:0] ALUResultW,
	output reg [31:0] PCPlus4W,
	output reg [4:0] RdW
);

	always @(posedge clk) begin
		if (reset || clear) begin
			RegWriteW <= 1'b0;
			ResultSrcW <= 2'b00;
			ReadDataW <= 32'b0;
			ALUResultW <= 32'b0;
			PCPlus4W <= 32'b0;
			RdW <= 5'b0;
		end else begin
			RegWriteW <= RegWriteM;
			ResultSrcW <= ResultSrcM;
			ReadDataW <= ReadDataM;
			ALUResultW <= ALUResultM;
			PCPlus4W <= PCPlus4M;
			RdW <= RdM;
		end
	end
endmodule
