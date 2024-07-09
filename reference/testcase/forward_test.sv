class forward_test extends uvm_test;
    `uvm_component_utils(forward_test)
    
    data_env env;
    data_env_cfg env_cfg;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = data_env::type_id::create("env", this);
        env_cfg = data_env_cfg::type_id::create("env_cfg");
        
        env_cfg.input_agent_cfg.is_active = 1;
        env_cfg.output0_agent_cfg.is_active = 0;
        env_cfg.output1_agent_cfg.is_active = 0;

        uvm_config_db#(data_env_cfg)::set(this, "env", "cfg", env_cfg);
    endfunction
    
    task run_phase(uvm_phase phase);
        data_sequence seq_in1, seq_in2;
        phase.raise_objection(this);
        
        seq_in1 = data_sequence::type_id::create("seq_in1");
        
        fork
            seq_in1.start(env.input_agent.sequencer);
        join
        
        // 等待一段时间，确保所有事务都已经通过DUT
        #6000;
        
        phase.drop_objection(this);
    endtask
endclass