module Reg_file(A1, A2, A3, WD3, WE3, clk, rst, RD1, RD2);

input clk, rst;
input [4:0] A1, A2, A3;
input [31:0] WD3;
output  [31:0] RD1, RD2;
input WE3;

// Creating memory [register bank]
reg [31:0] Registers [0:31];   // 32 registers which are 32-bit in size

// Read logic (Combinational)

integer i;

// Write logic (Synchronous)
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        for (i = 0; i < 32; i = i + 1)
            Registers[i] <= 32'b0; // Reset all registers
    end 
    else if (WE3 && A3 != 5'b00000) begin
        // Prevent writing to x0
        Registers[A3] <= WD3;
    end
end

assign RD1 = (~rst)?32'd0:Registers[A1];
assign RD2 = (~rst)?32'd0:Registers[A2];




endmodule  
