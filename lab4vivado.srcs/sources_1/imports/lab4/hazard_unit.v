module hazard_unit(
    input wire RESET, RegWriteM, RegWriteW, RegWriteE, CondExE, BranchTakenE, MemToRegE, PCSrcD, PCSrcE, PCSrcM,
    input wire [3:0] RA1E, WA3M, WA3W, RA2E, RA1D, WA3E, RA2D,
    output wire StallF, StallD, FlushD, FlushE,
    output wire [1:0] ForwardAE, ForwardBE
);

wire Match_1E_M, Match_1E_W, Match_2E_M, Match_2E_W, Match_12D_E, LDRStall, PCWrPendingF;

assign Match_1E_M = (RA1E == WA3M);
assign Match_1E_W = (RA1E == WA3W);
assign ForwardAE =  (Match_1E_M & RegWriteM) ? 2'b10 :
                    (Match_1E_W & RegWriteW) ? 2'b01 :
                    2'b00;

assign Match_2E_M = (RA2E == WA3M);
assign Match_2E_W = (RA2E == WA3W);
assign ForwardBE =  (Match_2E_M & RegWriteM) ? 2'b10 :
                    (Match_2E_W & RegWriteW) ? 2'b01 :
                    2'b00;

assign Match_12D_E = (RA1D == WA3E) | (RA2D == WA3E);
assign LDRStall = Match_12D_E & MemToRegE & CondExE;
assign PCWrPendingF = (PCSrcD) | (PCSrcE) | PCSrcM;
assign StallF = ~(LDRStall | PCWrPendingF);
assign StallD = ~LDRStall;
assign FlushD = PCWrPendingF | PCWrPendingF | BranchTakenE | RESET;
assign FlushE = ~StallD | BranchTakenE | RESET;
    
endmodule

//iverilog -o hazard_unit.out hazard_unit.v








