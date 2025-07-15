`include "mux.v"
`include "program_counter.v"
`include "Instruction_Memory.v"
`include "pc_adder.v"


module Fetch_cycle(clk,rst,StallF,PCSrcE,PC_TargetE,PCD,InstrD,pc_plus4D);

input PCSrcE,clk,rst;
input StallF; // Stall signal 
input [31:0] PC_TargetE;
output [31:0] InstrD,PCD,pc_plus4D;

wire [31:0] PC_F,PCF, pc_plus4F,InstrF;

reg [31:0] InstrF_D,PCF_D,pc_plus4F_D;

mux PC_Mux
(

    .a(pc_plus4F),
    .b(PC_TargetE),
    .c(PC_F),
    .sel(PCSrcE)

);


P_C program_counter
(
    .clk(clk),
    .rst(rst),
    .PC(PCF),
    .PCNext(PC_F),
    .en(~StallF)

);

instr_Mem INSTR_MEM
(
    .A(PCF),
    .Instr(InstrF),
    .rst(rst)

);

PC_Adder pc_adderF
(
    .a(PCF),
    .b(32'h00000004),
    .c(pc_plus4F)

);

always @(posedge clk , negedge rst)
begin
    if(!rst) 
    begin
        InstrF_D<=32'h00000000;
        PCF_D<=32'h00000000;
        pc_plus4F_D<=32'h00000000;
    end
    else if(!StallF)  // only update when not stalled
    begin
        InstrF_D<=InstrF;
        pc_plus4F_D<=pc_plus4F;
        PCF_D<=PCF;
    end
end

assign InstrD = (!rst) ? 32'h00000000 : InstrF_D;
assign PCD = (!rst) ? 32'h00000000 : PCF_D ;
assign pc_plus4D = (!rst) ? 32'h00000000 : pc_plus4F_D ;


endmodule