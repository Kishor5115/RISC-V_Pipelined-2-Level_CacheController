`include "mux.v"
`include "pc_adder.v"
`include "alu.v"

module Execute_cycle(clk,rst,RegwriteE,ResultSrcE,ALUSrcE,MemwriteE,JumpE,branchE,ALUControlE,RdE,RD1E,RD2E,PCE,immExtE,pc_plus4E,StallE,ForwardAE,ForwardBE,ALUResultM,pc_plus4W,ResultW,PCSrcE,RegwriteM,ResultSrcM,MemwriteM,ALUResultW,WriteDataM,RdM,pc_plus4M,PC_TargetE);

input RegwriteE,ALUSrcE,MemwriteE,JumpE,branchE,clk,rst;
input StallE;  // Added: Stall signal from hazard detection unit
// input FlushE;  // Added: Flush signal from hazard detection unit
input [1:0] ResultSrcE;
input [1:0] ForwardAE, ForwardBE;  // Added: Forwarding control signals
input [3:0] ALUControlE ;
input [4:0] RdE ;
input [31:0] RD1E,RD2E,PCE,immExtE,pc_plus4E;
input [31:0] ALUResultW, pc_plus4W, ResultW;  // Added: Forwarding data inputs

output RegwriteM,MemwriteM,PCSrcE;
output [1:0] ResultSrcM ;
output [4:0] RdM ;
output [31:0] ALUResultM,WriteDataM,pc_plus4M,PC_TargetE;

wire [31:0] SrcBE,SrcAE,ALUResultE,WriteDataE;
wire ZeroE,Zero_BranchE;

// Forwarding multiplexers for SrcA
wire [31:0] SrcA_Forwarded;
assign SrcA_Forwarded = (ForwardAE == 2'b00) ? RD1E :           // No forwarding
                        (ForwardAE == 2'b01) ? ResultW :        // Forward from WB stage
                        (ForwardAE == 2'b10) ? ALUResultW :     // Forward from MEM stage
                        RD1E;                                    // Default

// Forwarding multiplexers for SrcB (before ALU source mux)
wire [31:0] RD2E_Forwarded;
assign RD2E_Forwarded = (ForwardBE == 2'b00) ? RD2E :          // No forwarding
                        (ForwardBE == 2'b01) ? ResultW :       // Forward from WB stage
                        (ForwardBE == 2'b10) ? ALUResultW :    // Forward from MEM stage
                        RD2E;                                   // Default

assign SrcAE = SrcA_Forwarded;
assign WriteDataE = RD2E_Forwarded;  // Use forwarded data for memory writes

reg RegwriteE_M,MemwriteE_M;
reg [1:0] ResultSrcE_M;
reg [4:0] RdE_M ;
reg [31:0] ALUResultE_M , WriteDataE_M,pc_plus4E_M;

mux muxaluE
(
    .a(RD2E_Forwarded),  // Use forwarded data
    .b(immExtE),
    .c(SrcBE),
    .sel(ALUSrcE)
);

PC_Adder target
(
    .a(PCE),
    .b(immExtE),
    .c(PC_TargetE)
);

ALU ALUE
(
    .A(SrcAE),
    .B(SrcBE),
    .Result(ALUResultE),
    .ALUControl(ALUControlE)
);

assign Zero_BranchE = ZeroE & branchE ;
assign PCSrcE = JumpE | Zero_BranchE ;

// Modified: Pipeline register update with stall and flush control
always @(posedge clk , negedge rst)
begin
    if(!rst)
    begin
        RegwriteE_M <=1'b0;
        ResultSrcE_M <=2'b00;
        MemwriteE_M <=1'b0;
        RdE_M <=5'b00000;
        ALUResultE_M <=32'h00000000; 
        WriteDataE_M <=32'h00000000;
        pc_plus4E_M <=32'h00000000;
    end
    // else if(FlushE)  // Flush takes priority over stall
    // begin
    //     // Insert NOP (bubble) - disable write operations
    //     RegwriteE_M <=1'b0;
    //     ResultSrcE_M <=2'b00;
    //     MemwriteE_M <=1'b0;
    //     RdE_M <=5'b00000;
    //     ALUResultE_M <=32'h00000000; 
    //     WriteDataE_M <=32'h00000000;
    //     pc_plus4E_M <=32'h00000000;
    // end
    else if(!StallE)  // Only update when not stalled
    begin
        RegwriteE_M <= RegwriteE ;
        ResultSrcE_M <= ResultSrcE;
        MemwriteE_M <=MemwriteE ;
        RdE_M <= RdE;
        ALUResultE_M <=ALUResultE ;
        WriteDataE_M <= WriteDataE;
        pc_plus4E_M <= pc_plus4E;
    end
    // If StallE is high, pipeline registers hold their current values
end

assign RegwriteM = (!rst) ? 1'b0 :  RegwriteE_M ; 
assign ResultSrcM = (!rst) ? 2'b00 : ResultSrcE_M ;
assign MemwriteM = (!rst) ? 1'b0 : MemwriteE_M ;
assign RdM = (!rst) ? 5'b00000 : RdE_M ;
assign ALUResultM = (!rst) ? 32'h00000000 : ALUResultE_M ;
assign WriteDataM = (!rst) ? 32'h00000000 : WriteDataE_M ;
assign pc_plus4M  = (!rst) ? 32'h00000000 : pc_plus4E_M ;

endmodule