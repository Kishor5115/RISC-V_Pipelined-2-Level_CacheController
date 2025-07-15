module Data_Memory(
    input [31:0] A,      // Address
    input [31:0] WD,     // Write Data
    input rst,           // Reset
    input clk,           // Clock
    input WE,            // Write Enable
    input [2:0] funct3,  // Function type for different load/store sizes
    output reg [31:0] RD // Read Data
);

reg [31:0] Data_MEM [0:1023];  // 1024 entries of 32-bit memory

// Memory Initialization
integer i;
initial begin
    for (i = 0; i < 1024; i = i + 1)
        Data_MEM[i] = 32'h00000000;
end


// Read Operation with different load types
always @(*) begin
    if (!rst)
        RD = 32'h00000000;
    else begin
        case(funct3)
            3'b000: // LB (Load Byte, signed)
                RD = {{24{Data_MEM[A>>2][(A%4)*8 + 7]}}, Data_MEM[A>>2][(A%4)*8 +: 8]};
            3'b001: // LH (Load Halfword, signed)
                RD = {{16{Data_MEM[A>>2][(A%2)*16 + 15]}}, Data_MEM[A>>2][(A%2)*16 +: 16]};
            3'b010: // LW (Load Word)
                RD = Data_MEM[A>>2];
            3'b100: // LBU (Load Byte, unsigned)
                RD = {24'b0, Data_MEM[A>>2][(A%4)*8 +: 8]};
            3'b101: // LHU (Load Halfword, unsigned)
                RD = {16'b0, Data_MEM[A>>2][(A%2)*16 +: 16]};
            default:
                RD = 32'h00000000;
        endcase
    end
end

// Write Operation with different store types
always @(posedge clk) begin
    if (WE) begin
        case(funct3)
            3'b000: // SB (Store Byte)
                case(A%4)
                    2'b00: Data_MEM[A>>2][7:0] <= WD[7:0];
                    2'b01: Data_MEM[A>>2][15:8] <= WD[7:0];
                    2'b10: Data_MEM[A>>2][23:16] <= WD[7:0];
                    2'b11: Data_MEM[A>>2][31:24] <= WD[7:0];
                endcase
            3'b001: // SH (Store Halfword)
                case(A%2)
                    1'b0: Data_MEM[A>>2][15:0] <= WD[15:0];
                    1'b1: Data_MEM[A>>2][31:16] <= WD[15:0];
                endcase
            3'b010: // SW (Store Word)
                Data_MEM[A>>2] <= WD;
            default: ;
        endcase
    end
end


endmodule