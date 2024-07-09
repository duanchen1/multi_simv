module tb_top_1;
    reg clk;
    reg rst_n;

    // 时钟生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 复位生成
    initial begin
        rst_n = 0;
        repeat(20) @(posedge clk);
        rst_n = 1;
    end

    // 接口实例化
    data_if intf_in(clk, rst_n);   // 输入接口
    data_if intf_internal(clk, rst_n);   // 内部接口
    data_if intf_internal0(clk, rst_n); // 输出接口0
    data_if intf_internal1(clk, rst_n); // 输出接口1
    data_if intf_out0(clk, rst_n); // 输出接口0
    data_if intf_out1(clk, rst_n); // 输出接口1

    // DUT实例化
    Data_Forward #(.DATA_WIDTH(1024), .FIFO_DEPTH(8)) dut(
        .clk(clk),
        .rst_n(rst_n),
        // 输入接口
        .data_in(intf_in.data),
        .valid_in(intf_in.valid),
        .ready_in(intf_in.ready),
        // 输出接口
        .data_out(intf_internal.data),
        .valid_out(intf_internal.valid),
        .ready_out(intf_internal.ready)
    );

    // DUT实例化
    Data_Demux #(.DATA_WIDTH(1024)) dut1(
        .clk(clk),
        .rst_n(rst_n),
        // 输入接口
        .data_in(intf_internal.data),
        .valid_in(intf_internal.valid),
        .ready_in(intf_internal.ready),
        // 输出接口 0
        .data_out0(intf_internal0.data),
        .valid_out0(intf_internal0.valid),
        .ready_out0(intf_internal0.ready),
        // 输出接口 1
        .data_out1(intf_internal1.data),
        .valid_out1(intf_internal1.valid),
        .ready_out1(intf_internal1.ready)
    );

    // DUT实例化
    Data_Forward #(.DATA_WIDTH(1024), .FIFO_DEPTH(8)) dut2(
        .clk(clk),
        .rst_n(rst_n),
        // 输入接口
        .data_in(intf_internal0.data),
        .valid_in(intf_internal0.valid),
        .ready_in(intf_internal0.ready),
        // 输出接口
        .data_out(intf_out0.data),
        .valid_out(intf_out0.valid),
        .ready_out(intf_out0.ready)
    );

    // DUT实例化
    Data_Forward #(.DATA_WIDTH(1024), .FIFO_DEPTH(8)) dut3(
        .clk(clk),
        .rst_n(rst_n),
        // 输入接口
        .data_in(intf_internal1.data),
        .valid_in(intf_internal1.valid),
        .ready_in(intf_internal1.ready),
        // 输出接口
        .data_out(intf_out1.data),
        .valid_out(intf_out1.valid),
        .ready_out(intf_out1.ready)
    );

    initial begin
        intf_out0.ready = 0;
        intf_out1.ready = 0;
        fork
            forever begin
                for (int i = 0; i < 32; i++) begin
                    @(posedge intf_internal.clk);
                end
                intf_out0.ready <= 1;
                @(posedge intf_internal.clk);
                intf_out0.ready <= 0;
            end

            forever begin
                for (int i = 0; i < 32; i++) begin
                    @(posedge intf_internal.clk);
                end
                intf_out1.ready <= 1;
                @(posedge intf_internal.clk);
                intf_out1.ready <= 0;
            end
        join
    end

    initial begin

        // 设置接口
        uvm_config_db#(virtual data_if)::set(null, "uvm_test_top.env.input_agent*", "vif", intf_in);
        uvm_config_db#(virtual data_if)::set(null, "uvm_test_top.env.output0_agent*", "vif", intf_out0);
        uvm_config_db#(virtual data_if)::set(null, "uvm_test_top.env.output1_agent*", "vif", intf_out1);

        // 运行测试
        run_test("");
    end

    // 添加一个参数来控制是否生成 FSDB
    bit dump_fsdb;

    // FSDB dump 控制
    initial begin
        if ($test$plusargs("dump_fsdb")) begin
            dump_fsdb = 1;
            $fsdbDumpfile("tb_top_1.fsdb");
            $fsdbDumpvars(0, tb_top_1);
            $fsdbDumpMDA(); // dump 数组和记忆单元
            $display("FSDB dump enabled");
        end else begin
            dump_fsdb = 0;
        end
    end

endmodule