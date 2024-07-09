class data_env_cfg extends uvm_object;
    `uvm_object_utils(data_env_cfg)

    data_agent_cfg input_agent_cfg;
    data_agent_cfg output0_agent_cfg;
    data_agent_cfg output1_agent_cfg;
    
    function new(string name = "data_env_cfg");
        super.new(name);
        input_agent_cfg = data_agent_cfg::type_id::create("input_agent_cfg");
        output0_agent_cfg = data_agent_cfg::type_id::create("output0_agent_cfg");
        output1_agent_cfg = data_agent_cfg::type_id::create("output1_agent_cfg");
    endfunction
endclass