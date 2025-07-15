


module Hazard_unit(rst,RegwriteM,RegwriteW,RdM,RdW,Rs1E,Rs2E,CacheWait,ForwardAE,ForwardBE,StallF,StallD,StallE,FlushE);

// Existing inputs
input RegwriteM,RegwriteW,rst;
input [4:0] RdM,RdW,Rs1E,Rs2E;

// New input for cache control
input CacheWait;  // Wait signal from cache controller in Memory stage

// Existing outputs  
output [1:0] ForwardAE,ForwardBE;

// New outputs for pipeline control
output StallF;    // Stall Fetch stage
output StallD;    // Stall Decode stage  
output StallE;    // Stall Execute stage
output FlushE;    // Flush Execute stage (for certain hazard conditions)

// Cache stall logic - when cache is waiting, stall all earlier stages
assign StallF = CacheWait;
assign StallD = CacheWait;  
assign StallE = CacheWait;

// Flush logic - typically used for branch mispredictions, not needed for cache stalls
assign FlushE = 1'b0;  // Can be expanded later for other hazard types

// Existing forwarding logic (unchanged)
assign ForwardAE = (!rst) ? 2'b00 : (RegwriteM==1) & (RdM!=5'b00000) & (RdM==Rs1E) ? 2'b10 :
                                    (RegwriteW==1) & (RdW!=5'b00000) & (RdW==Rs1E) ? 2'b01 : 2'b00 ;

assign ForwardBE = (!rst) ? 2'b00 : (RegwriteM==1) & (RdM!=5'b00000) & (RdM==Rs2E) ? 2'b10 :
                                    (RegwriteW==1) & (RdW!=5'b00000) & (RdW==Rs2E) ? 2'b01 : 2'b00 ;

endmodule