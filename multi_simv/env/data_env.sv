class data_env extends uvm_env;
    `uvm_component_utils(data_env)
    
    data_agent input_agent;
    data_agent output0_agent;
    data_agent output1_agent;
    data_scoreboard scoreboard;
    data_env_cfg cfg;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if (!uvm_config_db#(data_env_cfg)::get(this, "", "cfg", cfg))
            `uvm_fatal("CFG_ERROR", "Failed to get environment configuration")
        
        uvm_config_db#(data_agent_cfg)::set(this, "input_agent", "cfg", cfg.input_agent_cfg);
        uvm_config_db#(data_agent_cfg)::set(this, "output0_agent", "cfg", cfg.output0_agent_cfg);
        uvm_config_db#(data_agent_cfg)::set(this, "output1_agent", "cfg", cfg.output1_agent_cfg);
        
        input_agent = data_agent::type_id::create("input_agent", this);
        output0_agent = data_agent::type_id::create("output0_agent", this);
        output1_agent = data_agent::type_id::create("output1_agent", this);
        scoreboard = data_scoreboard::type_id::create("scoreboard", this);
    endfunction
    
    function void connect_phase(uvm_phase phase);
        input_agent.monitor.ap.connect(scoreboard.input_export);
        output0_agent.monitor.ap.connect(scoreboard.output0_export);
        output1_agent.monitor.ap.connect(scoreboard.output1_export);
    endfunction
endclass