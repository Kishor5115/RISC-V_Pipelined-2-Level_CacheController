`timescale 1ns/1ps
`include "Pipeline_Top.v"

module Pipeline_Top_tb();

reg clk=1,clk_cc=1,rst;

Pipeline_Top Pipeline_Top(.clk(clk),.clk_cc(clk_cc),.rst(rst));


always
begin
    #10 clk=~clk;
     
end

always
begin
    #3 clk_cc=~clk_cc;
    
end


initial 
begin
   rst<=1'b0;
   #90;
   rst<=1'b1;
   #200000;
   $finish ; 
end

initial 
begin
    $dumpfile("Pipeline.vcd");
    $dumpvars(0,Pipeline_Top_tb);
end
    

endmodule