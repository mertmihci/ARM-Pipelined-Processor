module controller(
    input wire clk, RESET, FlushE,
    input wire [3:0] Flags_in,
    input wire [31:0] IROut,
    output wire PCSrcW, PCSrcD, linkW, BX, BranchTakenE, MemWriteM, RegWriteW, MemToRegW, PCSrcM, RegWriteM, PCSrcE, RegWriteE, MemToRegE, CondExE, ALUSrcE,
    output wire [1:0] ImmSrcD, RegSrcD, shcontrol,
    output wire [3:0] ALUControlE,
    output wire [4:0] shamt
);



wire [1:0] Op;
wire [3:0] cond, Rd, cmd;
wire [5:0] Func;


assign Op = IROut[27:26];
assign cond = IROut[31:28];
assign Rd = IROut[15:12];
assign cmd = IROut[24:21];
assign Func = IROut[25:20];


wire ADD, SUB, AND, ORR, MOV, CMP, STR, LDR, B;

assign ADD = (Op == 2'b00) & (cmd == 4'b0100);
assign SUB = (Op == 2'b00) & (cmd == 4'b0010);
assign AND = (Op == 2'b00) & (cmd == 4'b0000);
assign ORR = (Op == 2'b00) & (cmd == 4'b1100);
assign MOV = (Op == 2'b00) & (cmd == 4'b1101);
assign CMP = (Op == 2'b00) & (cmd == 4'b1010);
assign STR = (Op == 2'b01) & (~Func[0]);
assign LDR = (Op == 2'b01) & (Func[0]);
assign B   = (Op == 2'b10) & (~IROut[24]);
assign BL  = (Op == 2'b10) & (IROut[24]);
assign BX  = (IROut[27:4] == 24'b0001_0010_1111_1111_1111_0001);  


//----------DECODE----------
wire RegWriteD, MemToRegD, FlagWriteD, ALUSrcD;
wire [1:0] shcontrolD;
wire [3:0] ALUControlD, FlagsOut;
wire [4:0] shamtD;

assign PCSrcD = (Op == 2'b00 & Rd == 4'hF & ~BX);
assign RegWriteD = (Op == 2'b00 & ~CMP & ~BX) | (LDR) | BL;
assign ALUControlD = (Op == 2'b00 & ~CMP & ~BX) ? cmd :
                     (CMP) ? 4'b0010 :
                     (BX) ? 4'b1101 :
                     4'b0100;
assign BranchD = (B | BX | BL);
assign FlagWriteD = (Func[0] & (Op == 2'b00) | CMP);
assign ImmSrcD = Op;
assign ALUSrcD = ((Op == 2'b00) & Func[5] & ~BX) | (STR | LDR | B | BL);
assign shcontrolD = ((Op == 2'b00) & Func[5]) ? 2'b11 : IROut[6:5];
assign shamtD = ((Op == 2'b00) & Func[5] & ~BX) ? {IROut[11:8], 1'b0} :
               ((Op == 2'b00) & ~Func[5] & ~BX) ? IROut[11:7] :
               5'b0;
assign RegSrcD[0] = B | BL;
assign RegSrcD[1] = STR;

//----------EXECUTE---------
wire FlagWriteE, MemWriteE, BranchE, linkE;
wire [3:0] condE;

Register_reset #(1) PCSrcRegE(.clk(clk), .reset(RESET | FlushE), .DATA(PCSrcD), .OUT(PCSrcE));
Register_reset #(1) RegWriteRegE(.clk(clk), .reset(RESET | FlushE), .DATA(RegWriteD), .OUT(RegWriteE));
Register_reset #(1) MemToRegRegE(.clk(clk), .reset(RESET | FlushE), .DATA(LDR), .OUT(MemToRegE));
Register_reset #(1) MemWriteRegE(.clk(clk), .reset(RESET | FlushE), .DATA(STR), .OUT(MemWriteE));
Register_reset #(1) BranchEReg(.clk(clk), .reset(RESET | FlushE), .DATA(BranchD), .OUT(BranchE));
Register_reset #(4) ALUControlRegE(.clk(clk), .reset(RESET | FlushE), .DATA(ALUControlD), .OUT(ALUControlE));
Register_reset #(4) condRegE(.clk(clk), .reset(RESET | FlushE), .DATA(cond), .OUT(condE));
Register_reset #(1) ALUSrcRegE(.clk(clk), .reset(RESET | FlushE), .DATA(ALUSrcD), .OUT(ALUSrcE));
Register_reset #(1) FlagWriteRegE(.clk(clk), .reset(RESET | FlushE), .DATA(FlagWriteD), .OUT(FlagWriteE));
Register_reset #(2) shcontrolRegE(.clk(clk), .reset(RESET | FlushE), .DATA(shcontrolD), .OUT(shcontrol));
Register_reset #(5) shamtRegE(.clk(clk), .reset(RESET | FlushE), .DATA(shamtD), .OUT(shamt));
Register_reset #(1) linkRegE(.clk(clk), .reset(RESET | FlushE), .DATA(BL), .OUT(linkE));

Register_rsten #(4) FlagsRegE(.clk(clk), .reset(RESET | FlushE), .we(FlagWriteE), .DATA(Flags_in), .OUT(FlagsOut));

assign CondExE = (condE == 4'b1110 | (condE == 4'b0001 & ~FlagsOut[2]) | (condE === 4'b0 & FlagsOut[2]));
assign BranchTakenE = CondExE & BranchE;
//----------MEMORY----------
wire MemToRegM, linkM;

Register_reset #(1) PCSrcRegM(.clk(clk), .reset(RESET), .DATA(PCSrcE & CondExE), .OUT(PCSrcM));
Register_reset #(1) RegWriteRegM(.clk(clk), .reset(RESET), .DATA(RegWriteE & CondExE), .OUT(RegWriteM));
Register_reset #(1) MemToRegRegM(.clk(clk), .reset(RESET), .DATA(MemToRegE & CondExE), .OUT(MemToRegM));
Register_reset #(1) MemWriteRegM(.clk(clk), .reset(RESET), .DATA(MemWriteE & CondExE), .OUT(MemWriteM));
Register_reset #(1) linkRegM(.clk(clk), .reset(RESET), .DATA(linkE), .OUT(linkM));

//----------WRITE-----------

Register_reset #(1) PCSrcRegW(.clk(clk), .reset(RESET), .DATA(PCSrcM), .OUT(PCSrcW));
Register_reset #(1) RegWriteRegW(.clk(clk), .reset(RESET), .DATA(RegWriteM), .OUT(RegWriteW));
Register_reset #(1) MemToRegRegW(.clk(clk), .reset(RESET), .DATA(MemToRegM), .OUT(MemToRegW));
Register_reset #(1) linkRegW(.clk(clk), .reset(RESET), .DATA(linkM), .OUT(linkW));

endmodule

//iverilog -o controller.out controller.v Register_reset.v Register_rsten.v Mux_2to1.v