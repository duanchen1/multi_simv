`include "uvm_macros.svh"
import uvm_pkg::*;

class data_seq_item extends uvm_sequence_item;
    rand bit [1023:0] data;
    
    `uvm_object_utils_begin(data_seq_item)
        `uvm_field_int(data, UVM_ALL_ON)
    `uvm_object_utils_end
    
    function new(string name = "data_seq_item");
        super.new(name);
    endfunction
endclass