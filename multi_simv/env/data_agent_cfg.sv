class data_agent_cfg extends uvm_object;
    `uvm_object_utils(data_agent_cfg)

    bit is_active = 1;
    
    function new(string name = "data_agent_cfg");
        super.new(name);
    endfunction
endclass