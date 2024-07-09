class data_sequence extends uvm_sequence#(data_seq_item);
    `uvm_object_utils(data_sequence)

    function new(string name = "data_sequence");
        super.new(name);
    endfunction

    task body();
        repeat(100) begin  // 可以根据需要调整重复次数
            `uvm_do(req)
            // #10;  // 在每个项目之间添加一些延迟
        end
    endtask
endclass