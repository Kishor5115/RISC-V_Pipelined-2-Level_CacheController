module ALU(
    input [31:0] A, B,
    input [3:0] ALUControl,
    output reg [31:0] Result,
    output Zero
);
    wire signed [31:0] signed_a, signed_b;
    assign signed_a = A;
    assign signed_b = B;

    always @(*) begin
        case(ALUControl)
            4'b0000: Result = A + B;                      // ADD
            4'b0001: Result = A - B;                      // SUB
            4'b0010: Result = A & B;                      // AND
            4'b0011: Result = A | B;                      // OR
            4'b0100: Result = A ^ B;                      // XOR
            4'b0101: Result = {31'b0, signed_a < signed_b}; // SLT
            4'b0111: Result = {31'b0, A < B};             // SLTU
            4'b1000: Result = A << B[4:0];                // SLL
            4'b1001: Result = signed_a >>> B[4:0];        // SRA
            4'b1010: Result = A >> B[4:0];                // SRL
            4'b1011: Result = B;          
            4'b1110: begin  // TZCNT (Trailing Zero Count)
            Result = 0;
            while ((Result < 32) && !(A[Result]))
                Result = Result + 1;
        end                // LUI (pass immediate)
            default: Result = 32'b0;
        endcase
    end

    assign Zero = (Result == 32'b0);

    
endmodule