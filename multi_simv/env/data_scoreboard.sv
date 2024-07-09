`uvm_analysis_imp_decl(_input)
`uvm_analysis_imp_decl(_output0)
`uvm_analysis_imp_decl(_output1)

class data_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(data_scoreboard)
    
    uvm_analysis_imp_input#(data_seq_item, data_scoreboard) input_export;
    uvm_analysis_imp_output0#(data_seq_item, data_scoreboard) output0_export;
    uvm_analysis_imp_output1#(data_seq_item, data_scoreboard) output1_export;
    
    data_seq_item output0_expect_queue[$];
    data_seq_item output1_expect_queue[$];
    int item_count;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        input_export = new("input_export", this);
        output0_export = new("output0_export", this);
        output1_export = new("output1_export", this);
        item_count = 0;
    endfunction
    
    function void write_input(data_seq_item item);
        data_seq_item cloned_item = data_seq_item::type_id::create("cloned_item");
        $cast(cloned_item, item.clone());
        
        if (item_count % 2 == 0) begin
            output0_expect_queue.push_back(cloned_item);
            `uvm_info(get_type_name(), $sformatf("Input item %0d expected on output0", item_count), UVM_LOW)
        end else begin
            output1_expect_queue.push_back(cloned_item);
            `uvm_info(get_type_name(), $sformatf("Input item %0d expected on output1", item_count), UVM_LOW)
        end
        
        item_count++;
    endfunction
    
    function void write_output0(data_seq_item item);
        data_seq_item expect_item;

        if (output0_expect_queue.size() == 0) begin
            `uvm_error(get_type_name(), "Received unexpected item on output0")
            return;
        end
        
        expect_item = output0_expect_queue.pop_front();
        if (expect_item.data == item.data) begin
            `uvm_info(get_type_name(), $sformatf("PASS: Item correctly received on output0, data = %h", item.data), UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), $sformatf("FAIL: Data mismatch on output0. Expected: %h, Received: %h", expect_item.data, item.data))
        end
    endfunction
    
    function void write_output1(data_seq_item item);
        data_seq_item expect_item;

        if (output1_expect_queue.size() == 0) begin
            `uvm_error(get_type_name(), "Received unexpected item on output1")
            return;
        end
        
        expect_item = output1_expect_queue.pop_front();
        if (expect_item.data == item.data) begin
            `uvm_info(get_type_name(), $sformatf("PASS: Item correctly received on output1, data = %h", item.data), UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), $sformatf("FAIL: Data mismatch on output1. Expected: %h, Received: %h", expect_item.data, item.data))
        end
    endfunction
    
    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        
        if (output0_expect_queue.size() != 0) begin
            `uvm_error(get_type_name(), $sformatf("%0d expected items not received on output0", output0_expect_queue.size()))
        end
        
        if (output1_expect_queue.size() != 0) begin
            `uvm_error(get_type_name(), $sformatf("%0d expected items not received on output1", output1_expect_queue.size()))
        end
    endfunction
endclass