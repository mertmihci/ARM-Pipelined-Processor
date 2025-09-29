def ToHex(obj): # Convert to hex only if signal is longer than 16 bits
    binary_str = str(obj)
    binary_str = binary_str.strip()
    if(len(binary_str)>=16  and  binary_str.replace("1","").replace("0","") == ""): # Convert to hex only if value is longer than 16 bits, and doesn't contain 'x' or 'z' bits.
        value = int(binary_str,2)
        hex_len = (len(binary_str)+3)//4
        hex_str = format(value, '0{}x'.format(hex_len))
        return "0x"+hex_str
    else:
        return binary_str

def Log_Everything(dut, instance, log_submodules=False):
    # This functions scans a module instance, and prints values of every signal it finds
    instance_name = instance.name
    wires = []
    submodules = []
    for attribute_name in dir(instance):
        attribute = getattr(instance, attribute_name)
        if attribute.__class__.__module__.startswith('cocotb.handle'):
            if(attribute.__class__.__name__ == 'ModifiableObject'):        # wire / reg
                wires.append((attribute_name, ToHex(attribute.value)) )
            elif(attribute.__class__.__name__ == 'NonHierarchyIndexableObject'):  # wire / reg array
                wires.append((attribute_name, [ToHex(v) for v in attribute.value] ) )
            elif(attribute.__class__.__name__ == 'HierarchyObject'):       # submodule
                submodules.append((attribute_name, attribute.get_definition_name()) )
            elif(attribute.__class__.__name__ == 'HierarchyArrayObject'):  # submodule array
                submodules.append((attribute_name, f"[{len(attribute)}]") )
    
    if(log_submodules):
        for sub in submodules:
            dut._log.debug(f"{instance_name}.{sub[0]:<20} is {sub[1]}")
    for wire in wires:
        dut._log.debug(f"{instance_name}.{wire[0]:<20} = {wire[1]}")


#Populate the below functions as in the example lines of code to print your values for debugging
def Log_Datapath(dut,logger):
    #Log whatever signal you want from the datapath, called before positive clock edge
    logger.debug("************ DUT DATAPATH Signals ***************")
    dut._log.info("InstrD: %s", ToHex(dut.my_datapath.InstrD))
    dut._log.info("ResultW: %s", ToHex(dut.my_datapath.ResultW)) 
    dut._log.info("linkW: %s", ToHex(dut.my_datapath.linkW)) 
    #dut._log.info("ALUResultE: %s", ToHex(dut.my_datapath.ALUResultE))
    #dut._log.info("ALUResultM: %s", ToHex(dut.my_datapath.ALUResultM))
    #dut._log.info("ALUResultW: %s", ToHex(dut.my_datapath.ALUResultW))
    #dut._log.info("ExtImmE: %s", ToHex(dut.my_datapath.ExtImmE))
    #dut._log.info("ALU DATA B: %s", ToHex(dut.my_datapath.alu.DATA_B))
    #dut._log.info("ALU OUT: %s", ToHex(dut.my_datapath.alu.OUT))
    #dut._log.info("PC IN: %s", ToHex(dut.my_datapath.PCReg.DATA))
    #dut._log.info("PC_WE: %s" , ToHex(dut.my_datapath.PCReg.we))
    #dut._log.info("PC_RESET: %s" , ToHex(dut.my_datapath.PCReg.reset))


    #Log_Everything(dut, dut.my_datapath)


def Log_Controller(dut,logger):
    #Log whatever signal you want from the controller, called before positive clock edge
    logger.debug("************ DUT Controller Signals ***************")
    #dut._log.info("CondExE: %s", ToHex(dut.my_controller.CondExE))
    #dut._log.info("PCSrcW: %s", ToHex(dut.my_controller.PCSrcW))
    #dut._log.info("PCSrcD: %s", ToHex(dut.my_controller.PCSrcD))
    #dut._log.info("BL: %s", ToHex(dut.my_controller.BL))
    #dut._log.info("BX: %s", ToHex(dut.my_controller.BX))
    #dut._log.info("BranchTakenE: %s", ToHex(dut.my_controller.BranchTakenE))
    #dut._log.info("Flags: %s", ToHex(dut.my_controller.FlagsOut))
    #dut._log.info("MemWriteM: %s", ToHex(dut.my_controller.MemWriteM))
    #dut._log.info("RegWriteW: %s", ToHex(dut.my_controller.RegWriteW))
    #dut._log.info("MemToRegW: %s", ToHex(dut.my_controller.MemToRegW))
    #dut._log.info("CondExE: %s", ToHex(dut.my_controller.CondExE))
    #dut._log.info("condE: %s", ToHex(dut.my_controller.condE))
    dut._log.info("linkD: %s", ToHex(dut.my_controller.BL))
    dut._log.info("linkE: %s", ToHex(dut.my_controller.linkE))
    dut._log.info("linkM: %s", ToHex(dut.my_controller.linkM))
    #dut._log.info("PCSrcM: %s", ToHex(dut.my_controller.PCSrcM))
    #dut._log.info("RegWriteM: %s", ToHex(dut.my_controller.RegWriteM))
    #dut._log.info("PCSrcE: %s", ToHex(dut.my_controller.PCSrcE))
    #dut._log.info("RegWriteE: %s", ToHex(dut.my_controller.RegWriteE))
    #dut._log.info("MemToRegE: %s", ToHex(dut.my_controller.MemToRegE))
    #dut._log.info("CondExE: %s", ToHex(dut.my_controller.CondExE))
    #dut._log.info("ImmSrcD: %s", ToHex(dut.my_controller.ImmSrcD))
    #dut._log.info("RegSrcD: %s", ToHex(dut.my_controller.RegSrcD))
    #dut._log.info("shcontrol: %s", ToHex(dut.my_controller.shcontrol))
    #dut._log.info("shamt: %s", ToHex(dut.my_controller.shamt))
    #dut._log.info("ALUSrcE: %s", ToHex(dut.my_controller.ALUSrcE))
    #dut._log.info("ALUControlE: %s", ToHex(dut.my_controller.ALUControlE))
    #Log_Everything(dut, dut.my_controller)

def Log_Hazard_Unit(dut,logger):
    #Log whatever signal you want from the controller, called before positive clock edge
    logger.debug("************ DUT Hazard Unit Signals ***************")
    dut._log.info("StallF: %s", ToHex(dut.my_hazard_unit.StallF))
    dut._log.info("StallD: %s", ToHex(dut.my_hazard_unit.StallD))
    dut._log.info("FlushD: %s", ToHex(dut.my_hazard_unit.FlushD))
    dut._log.info("FlushE: %s", ToHex(dut.my_hazard_unit.FlushE))
    dut._log.info("ForwardAE: %s", ToHex(dut.my_hazard_unit.ForwardAE))
    dut._log.info("ForwardBE: %s", ToHex(dut.my_hazard_unit.ForwardBE))


