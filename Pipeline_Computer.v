module Pipeline_Computer (
    input wire clk, reset,
    input wire [3:0] Debug_Source_select,
    output wire [31:0] fetchPC, Debug_out
);

wire StallF, PCSrcW, BranchTakenE, FlushD, StallD, linkW, RegWriteW, FlushE, ALUSrcE, MemWriteM, MemToRegW;
wire PCSrcM, PCSrcD, RegWriteM, PCSrcE, RegWriteE, MemToRegE, CondExE;
wire [1:0] RegSrcD, ImmSrcD, ForwardAE, ForwardBE, shctrl;
wire [3:0] ALUCtrlE, RA1D, RA2D, RA1E, RA2E, WA3E, WA3M, WA3W, FlagsDP;
wire [4:0] shamt;
wire [31:0] InstrD;
//ALUSrcE, ALUCtrlE
datapath my_datapath(
    .clk(clk), .RESET(reset), .StallF(StallF), .PCSrcW(PCSrcW), .BranchTakenE(BranchTakenE), .FlushD(FlushD), .StallD(StallD), .linkW(linkW), 
    .RegWriteW(RegWriteW), .FlushE(FlushE), .ALUSrcE(ALUSrcE), .MemWriteM(MemWriteM), .MemToRegW(MemToRegW),
    .RegSrcD(RegSrcD), .ImmSrcD(ImmSrcD), .ForwardAE(ForwardAE), .ForwardBE(ForwardBE), .shctrl(shctrl),
    .Debug_Source_select(Debug_Source_select), .ALUCtrlE(ALUCtrlE), .Flags(FlagsDP), .shamt(shamt),
    .RA1D(RA1D), .RA2D(RA2D), .RA1E(RA1E), .RA2E(RA2E), .WA3E(WA3E), .WA3M(WA3M), .WA3W(WA3W),
    .PC(fetchPC), .InstrD(InstrD), .Debug_out(Debug_out)
);

controller my_controller(
    .clk(clk), .RESET(reset), .FlushE(FlushE), .Flags_in(FlagsDP),.IROut(InstrD),.PCSrcW(PCSrcW), 
    .PCSrcD(PCSrcD), .linkW(linkW), .BranchTakenE(BranchTakenE), .MemWriteM(MemWriteM), .RegWriteW(RegWriteW), .MemToRegW(MemToRegW), 
    .PCSrcM(PCSrcM), .RegWriteM(RegWriteM), .PCSrcE(PCSrcE), .RegWriteE(RegWriteE), .MemToRegE(MemToRegE), .CondExE(CondExE), .ALUSrcE(ALUSrcE),
    .ImmSrcD(ImmSrcD), .RegSrcD(RegSrcD), .shcontrol(shctrl), .ALUControlE(ALUCtrlE), .shamt(shamt)
);

hazard_unit my_hazard_unit(reset, RegWriteM, RegWriteW, RegWriteE, CondExE, BranchTakenE, MemToRegE, PCSrcD, PCSrcE, PCSrcM,RA1E, WA3M, WA3W,
            RA2E, RA1D, WA3E, RA2D, StallF, StallD, FlushD, FlushE, ForwardAE, ForwardBE
);

endmodule

//iverilog -o Pipeline_Computer.out Pipeline_Computer.v datapath.v controller.v hazard_unit.v Register_reset.v Mux_2to1.v Mux_4to1.v Memory.v Instruction_memory.v ALU.v shifter.v Adder.v Extender.v Register_file.v Register_rsten.v Register_rsten_neg.v Decoder_4to16.v Mux_16to1.v 