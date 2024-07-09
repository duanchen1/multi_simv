class data_sequencer extends uvm_sequencer#(data_seq_item);
    `uvm_component_utils(data_sequencer)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass
