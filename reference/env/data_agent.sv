class data_agent extends uvm_agent;
    `uvm_component_utils(data_agent)

    data_driver driver;
    data_sequencer sequencer;
    data_monitor monitor;
    data_agent_cfg cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(data_agent_cfg)::get(this, "", "cfg", cfg))
            `uvm_fatal("CFG_ERROR", "Failed to get agent configuration")

        monitor = data_monitor::type_id::create("monitor", this);

        if (cfg.is_active) begin
            driver = data_driver::type_id::create("driver", this);
            sequencer = data_sequencer::type_id::create("sequencer", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        if (cfg.is_active) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction

endclass