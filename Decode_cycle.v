`include "control_unit_top.v"
`include "Register_files.v"
`include "sign_extend.v"

module Decode_cycle(clk,rst,PCD,pc_plus4D,InstrD,RegwriteW,ResultW,RdW,StallD,RegwriteE,MemwriteE,ResultSrcE,JumpE,branchE,ALUControlE,ALUSrcE,RD1E,RD2E,Rs1E,Rs2E,immExtE,PCE,RdE,pc_plus4E);

input clk,rst,RegwriteW;
input StallD;  // Added: Stall signal from hazard detection unit
//input FlushD;  // Added: Flush signal (for future use - branch mispredictions)
input [31:0] PCD,InstrD,pc_plus4D,ResultW;
input [4:0] RdW;
output RegwriteE,MemwriteE,JumpE,branchE,ALUSrcE;   
output [1:0] ResultSrcE ;
output [3:0] ALUControlE;
output [31:0] RD1E,RD2E,PCE,immExtE,pc_plus4E;
output [4:0] RdE,Rs1E,Rs2E;



wire RegwriteD,MemwriteD,JumpD,branchD,ALUSrcD;
wire [1:0] ImmSrcD,ResultSrcD;
wire [3:0] ALUControlD;
wire [31:0] RD1D ,RD2D,immExtD;
wire [4:0] RdD,Rs1D,Rs2D;

assign RdD = InstrD[11:7] ;

assign Rs1D = InstrD[19:15] ; 
assign Rs2D = InstrD[24:20] ;

reg RegwriteD_E,MemwriteD_E,JumpD_E,branchD_E,ALUSrcD_E;
reg [1:0] ResultSrcD_E;
reg[2:0] ALUControlD_E;
reg [31:0] RD1D_E,RD2D_E,PCD_E,immExtD_E,pc_plus4D_E;
reg [4:0] RdD_E,Rs1D_E,Rs2D_E;

control_unit_top control_unit_top
(
    .op(InstrD[6:0]),
    .Zero(),
    .RegWrite(RegwriteD),
    .Memwrite(MemwriteD),
    .ResultSrc(ResultSrcD),
    .ALUSrc(ALUSrcD),
    .PCSrc(),
    .ImmSrc(ImmSrcD),
    .branch(branchD),
    .Jump(JumpD),
    .funct3(InstrD[14:12]),
    .funct7(InstrD[31:25]),
    .ALUControl(ALUControlD)
);

Reg_file Register_file
(
    .clk(clk),
    .A1(InstrD[19:15]),
    .A2(InstrD[24:20]),
    .A3(RdW),
    .WE3(RegwriteW),
    .WD3(ResultW),
    .rst(rst),
    .RD1(RD1D),
    .RD2(RD2D)
);

Sign_Extend Sign_Extend
(
    .in(InstrD),
    .imm_ext(immExtD),
    .ImmSrc(ImmSrcD)
);

// Modified: Pipeline register update with stall and flush control
always @(posedge clk , negedge rst)
begin
    if(!rst)
    begin
        RegwriteD_E<=1'b0;
        ALUControlD_E<=3'b000;
        MemwriteD_E<=1'b0;
        ResultSrcD_E<=2'b00;
        JumpD_E<=1'b0;
        branchD_E<=1'b0;
        ALUSrcD_E<=1'b0;
        RD1D_E<=32'h00000000;
        RD2D_E<=32'h00000000;
        PCD_E<=32'h00000000;
        immExtD_E<=32'h00000000;
        pc_plus4D_E<=32'h00000000;
        RdD_E<=5'b00000;
        Rs1D_E<=5'b00000;
        Rs2D_E<=5'b00000;
    end
    // else if(FlushD)  // Flush takes priority over stall
    // begin
    //     // Insert NOP (bubble) - all control signals become 0
    //     RegwriteD_E<=1'b0;
    //     ALUControlD_E<=3'b000;
    //     MemwriteD_E<=1'b0;
    //     ResultSrcD_E<=2'b00;
    //     JumpD_E<=1'b0;
    //     branchD_E<=1'b0;
    //     ALUSrcD_E<=1'b0;
    //     RD1D_E<=32'h00000000;
    //     RD2D_E<=32'h00000000;
    //     PCD_E<=32'h00000000;
    //     immExtD_E<=32'h00000000;
    //     pc_plus4D_E<=32'h00000000;
    //     RdD_E<=5'b00000;
    //     Rs1D_E<=5'b00000;
    //     Rs2D_E<=5'b00000;
    // end
    else if(!StallD)  // Only update when not stalled
    begin
        RegwriteD_E<=RegwriteD;
        ALUControlD_E<=ALUControlD;
        MemwriteD_E<=MemwriteD;
        ResultSrcD_E<=ResultSrcD;
        JumpD_E<=JumpD;
        branchD_E<=branchD;
        ALUSrcD_E<=ALUSrcD;
        RD1D_E<=RD1D;
        RD2D_E<=RD2D;
        PCD_E<=PCD;
        immExtD_E<=immExtD;
        pc_plus4D_E<=pc_plus4D;
        RdD_E<=RdD;
        Rs1D_E<=Rs1D;
        Rs2D_E<=Rs2D;
    end
    // If StallD is high, pipeline registers hold their current values
end

assign RegwriteE = (!rst) ? 1'b0 : RegwriteD_E ;
assign MemwriteE = (!rst) ? 1'b0 : MemwriteD_E ;
assign ALUControlE =(!rst) ? 3'b000 : ALUControlD_E ;
assign ResultSrcE = (!rst) ? 2'b00 :ResultSrcD_E ;
assign JumpE = (!rst) ? 1'b0 :JumpD_E ;
assign branchE =(!rst) ? 1'b0 : branchD_E ;
assign ALUSrcE = (!rst) ? 1'b0 : ALUSrcD_E ;
assign RD1E = (!rst) ? 32'h00000000 :RD1D_E ;
assign RD2E = (!rst) ? 32'h00000000 :RD2D_E ;
assign PCE = (!rst) ? 32'h00000000 :PCD_E ;
assign immExtE = (!rst) ? 32'h00000000 :immExtD_E ;
assign pc_plus4E = (!rst) ? 32'h00000000 :pc_plus4D_E ;
assign RdE = (!rst) ? 5'b00000 : RdD_E ;  
assign Rs1E = (!rst) ? 5'b00000 : Rs1D_E ; 
assign Rs2E = (!rst) ? 5'b00000 : Rs2D_E ; 

endmodule