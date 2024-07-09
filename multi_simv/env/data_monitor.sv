class data_monitor extends uvm_monitor;
    `uvm_component_utils(data_monitor)
    
    virtual data_if vif;
    uvm_analysis_port#(data_seq_item) ap;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual data_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_full_name(), "Virtual interface not found")
    endfunction

    task run_phase(uvm_phase phase);
        data_seq_item item;
        @(posedge vif.rst_n);
        @(posedge vif.clk);
        forever begin
            item = data_seq_item::type_id::create("item");
            @(posedge vif.clk);
            if (vif.valid && vif.ready) begin
                item.data = vif.data;
                ap.write(item);
                `uvm_info(get_type_name(), $sformatf("Monitored: data = %h", item.data), UVM_LOW)
            end
        end
    endtask
endclass