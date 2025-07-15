`include "Cache.v"


module Memory_cycle(clk,clk_cc,rst,RegwriteM,ResultSrcM,MemwriteM,RdM,ALUResultM,WriteDataM,pc_plus4M,CacheWait,RegwriteW,ResultSrcW,ALUResultW,RdW,ReadDataW,pc_plus4W);

    input   RegwriteM,MemwriteM,clk,clk_cc,rst;
    input   [1:0] ResultSrcM ;
    input   [4:0] RdM ;
    input   [31:0] ALUResultM,WriteDataM,pc_plus4M ;
    output  CacheWait;  // Added: Cache wait signal for hazard unit
    output  RegwriteW;
    output  [1:0] ResultSrcW ;
    output  [4:0] RdW ;
    output  [31:0] ALUResultW,ReadDataW,pc_plus4W ;

    // Cache controller signals
    wire [31:0] ReadDataM;
    wire hit1, hit2, Wait;
    wire [31:0] stored_address, stored_data;

    reg RegwriteM_W;
    reg [1:0] ResultSrcM_W ;
    reg [4:0] RdM_W ;
    reg [31:0] ALUResultM_W,ReadDataM_W,pc_plus4M_W ;

    // Export cache wait signal to hazard unit
    assign CacheWait = Wait;

    // Cache Controller instantiation (replaces Data_Memory)
    CACHE_CONTROLLER Cache_Controller
    (
        .address(ALUResultM),
        .clk_cc(clk_cc),
        .data(WriteDataM),
        .mode(MemwriteM),
        .output_data(ReadDataM),
        .hit1(hit1),
        .hit2(hit2),
        .Wait(Wait),
        .stored_address(stored_address),
        .stored_data(stored_data)
    );

    // Modified: Pipeline register update - DON'T use Wait signal here
    // The stalling is handled by earlier pipeline stages
    always @(posedge clk , negedge rst)
    begin
        if(!rst)
            begin
                RegwriteM_W <=1'b0;
                ResultSrcM_W <=2'b00;
                RdM_W<=5'b00000;
                ALUResultM_W <=32'h00000000; 
                pc_plus4M_W <=32'h00000000;
                ReadDataM_W <=32'h00000000;
            end
        else if(!CacheWait)
            begin
                RegwriteM_W <=RegwriteM;
                ResultSrcM_W <=ResultSrcM;
                RdM_W<=RdM;
                ALUResultM_W <=ALUResultM; 
                pc_plus4M_W <=pc_plus4M;
                ReadDataM_W <=ReadDataM;    
            end
    end

    assign RegwriteW = (!rst) ? 1'b0 : RegwriteM_W ; 
    assign ResultSrcW = (!rst) ? 2'b00 : ResultSrcM_W ;
    assign RdW = (!rst) ? 5'b00000 : RdM_W ;
    assign ALUResultW = (!rst) ? 32'h00000000 : ALUResultM_W ;
    assign pc_plus4W  = (!rst) ? 32'h00000000 : pc_plus4M_W;
    assign ReadDataW  = (!rst) ? 32'h00000000 : ReadDataM_W ;

endmodule