
`include "Fetch_cycle.v"
`include "Decode_cycle.v"
`include "Execute_cycle.v"
`include "Memory_cycle.v"
`include "WriteBack_cycle.v"
`include "Hazard_unit.v"

module Pipeline_Top(clk,clk_cc,rst);

input clk,clk_cc,rst ;


wire PCSrcE,RegwriteW,RegwriteE,MemwriteE,JumpE,branchE,ALUSrcE,RegwriteM,MemwriteM;
wire [1:0] ResultSrcE,ResultSrcM,ResultSrcW,Forward_A_E,Forward_B_E;
wire [3:0] ALUControlE;
wire [4:0] RdW,RdE,RdM,Rs1E,Rs2E;
wire [31:0] PC_TargetE ,PCD,InstrD,ALUResultE,pc_plus4D,ResultW,RD1E,RD2E,immExtE,PCE,pc_plus4E,ALUResultM,WriteDataM,pc_plus4M;
wire [31:0] ALUResultW, ReadDataW,pc_plus4W;

// Cache controller interface wires
wire [31:0] cache_data_out;
wire cache_hit1, cache_hit2, cache_wait;
wire [31:0] stored_address, stored_data;

// Stall 

wire StallD,StallF,StallE;

    Fetch_cycle Fetch_cycle
        ( 
            .clk(clk),
            .rst(rst),
            .PCSrcE(PCSrcE),
            .PC_TargetE(PC_TargetE),
            .PCD(PCD),
            .InstrD(InstrD),
            .pc_plus4D(pc_plus4D),
            .StallF(StallF)
        
        );


    
    Decode_cycle Decode_cycle
        (
            .clk(clk),
            .rst(rst),
            .PCD(PCD),
            .pc_plus4D(pc_plus4D),
            .InstrD(InstrD),
            .RegwriteW(RegwriteW),
            .RdW(RdW),
            .ResultW(ResultW),
            .RegwriteE(RegwriteE),
            .MemwriteE(MemwriteE),
            .ResultSrcE(ResultSrcE),
            .JumpE(JumpE),
            .branchE(branchE),
            .ALUControlE(ALUControlE),
            .ALUSrcE(ALUSrcE),
            .RD1E(RD1E),
            .RD2E(RD2E),
            .immExtE(immExtE),
            .PCE(PCE),
            .RdE(RdE),
            .pc_plus4E(pc_plus4E),
            .Rs1E(Rs1E),
            .Rs2E(Rs2E),
            .StallD(StallD)      
        );
    

    Execute_cycle Execute_cycle
        (
            .clk(clk),
            .rst(rst),
            .RegwriteE(RegwriteE),
            .ResultSrcE(ResultSrcE),
            .ALUSrcE(ALUSrcE),
            .MemwriteE(MemwriteE),
            .JumpE(JumpE),
            .branchE(branchE),
            .ALUControlE(ALUControlE),
            .ALUResultW(ALUResultW),
            .RdE(RdE),
            .RD1E(RD1E),
            .RD2E(RD2E),
            .PCE(PCE),
            .immExtE(immExtE),
            .pc_plus4E(pc_plus4E),
            .PCSrcE(PCSrcE),
            .RegwriteM(RegwriteM),
            .ResultSrcM(ResultSrcM),
            .MemwriteM(MemwriteM),
            .ALUResultM(ALUResultM),
            .WriteDataM(WriteDataM),
            .RdM(RdM),
            .pc_plus4M(pc_plus4M),
            .PC_TargetE(PC_TargetE),
            .ForwardAE(Forward_A_E),
            .ForwardBE(Forward_B_E),
            .ResultW(ResultW),
            .StallE(StallE)
        );


    Memory_cycle Memory_cycle
        (
            .clk(clk),
            .clk_cc(clk_cc),
            .rst(rst),
            .RegwriteM(RegwriteM),
            .ResultSrcM(ResultSrcM),
            .MemwriteM(MemwriteM),
            .RdM(RdM),
            .ALUResultM(ALUResultM),
            .WriteDataM(WriteDataM),
            .pc_plus4M(pc_plus4M),
            .RegwriteW(RegwriteW),
            .ResultSrcW(ResultSrcW),
            .ALUResultW(ALUResultW),
            .RdW(RdW),
            .ReadDataW(ReadDataW),
            .pc_plus4W(pc_plus4W),
            .CacheWait(cache_wait)
        );


    WriteBack_cycle WriteBack_cycle
        (
            .clk(clk),
            .rst(rst),
            .RegwriteW(RegwriteW),
            .ResultSrcW(ResultSrcW),
            .ALUResultW(ALUResultW),
            .ReadDataW(ReadDataW),
            .RdW(RdW),
            .pc_plus4W(pc_plus4W),
            .ResultW(ResultW)

        );

    Hazard_unit  Hazard
        (
            .rst(rst),
            .RegwriteM(RegwriteM),
            .RegwriteW(RegwriteW),
            .RdM(RdM),
            .RdW(RdW),
            .Rs1E(Rs1E),
            .Rs2E(Rs2E),
            .CacheWait(cache_wait),
            .ForwardAE(Forward_A_E),
            .ForwardBE(Forward_B_E),
            .StallF(StallF),
            .StallD(StallD),
            .StallE(StallE)

        );


endmodule