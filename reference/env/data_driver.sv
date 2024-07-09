class data_driver extends uvm_driver#(data_seq_item);
    `uvm_component_utils(data_driver)
    
    virtual data_if vif;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual data_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not found")
    endfunction
    
    task run_phase(uvm_phase phase);
        @(posedge vif.rst_n);
        @(posedge vif.clk);
        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask
    
    task drive_item(data_seq_item item);
        vif.data <= item.data;
        vif.valid <= 1'b1;
        @(posedge vif.clk);
        while (!vif.ready) @(posedge vif.clk);
        vif.valid <= 1'b0;
    endtask
endclass