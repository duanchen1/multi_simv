program socket_pgm(
    data_if intf_in,
    data_if intf_internal,
    data_if intf_out0,
    data_if intf_out1
);
    import "DPI-C" function int socket_init(input int is_server, input string address, input int port, input string base_path, input int socket_index, input int max_clients=1);
    import "DPI-C" function string socket_send(input int socket_index, input string data);
    import "DPI-C" function string socket_recv(input int socket_index, input int non_blocking=0);

    DataPacket tx_packet1, tx_packet2, tx_packet3;
    DataPacket rx_packet1, rx_packet2, rx_packet3;

    string debug = "0";

    initial begin
        int init_result;
        string testname;
        string socket_patg_pre;

        tx_packet1 = new();
        tx_packet2 = new();
        tx_packet3 = new();
        rx_packet1 = new();
        rx_packet2 = new();
        rx_packet3 = new();

        if (!$value$plusargs("UVM_TESTNAME=%s", testname)) begin
            $display("Failed to get testname");
            $finish;
        end

        void'($sformat(socket_patg_pre, "/tmp/%s_socket_", testname));

        // 初始化 socket
        init_result = socket_init(1, "", 0, socket_patg_pre, 0);  // socket0 作为服务器
        if (init_result == -1) begin
            $display("Failed to initialize server socket");
            $finish;
        end

        init_result = socket_init(0, "", 0, socket_patg_pre, 3);  // socket3 作为客户端
        if (init_result == -1) begin
            $display("Failed to connect socket3 to server");
            $finish;
        end

        init_result = socket_init(0, "", 0, socket_patg_pre, 4);  // socket4 作为客户端
        if (init_result == -1) begin
            $display("Failed to connect socket4 to server");
            $finish;
        end

        init_result = socket_init(1, "", 0, socket_patg_pre, 5, 3);  // socket5 作为服务器,接收三个客户端的连接
        if (init_result == -1) begin
            $display("Failed to connect socket4 to server");
            $finish;
        end
    end

    initial begin
        if (!$value$plusargs("debug=%s", debug)) begin
            $display("Failed to get debug default tp %d", debug);
        end

        fork
            // Socket0: 发送输出数据，接收ready信号
            forever begin
                string send_status;
                string recv_data;
                @(posedge intf_internal.clk or negedge intf_internal.rst_n);
                if (intf_internal.rst_n) begin
                    string sub;

                    // 准备发送数据
                    tx_packet1.data = intf_internal.data;
                    tx_packet1.valid = intf_internal.valid;

                    // 发送数据
                    send_status = socket_send(0, tx_packet1.serialize());
                    if (debug == "1") begin
                        $display("Socket0 Send data at %t: %s\n", $time, tx_packet1.serialize());
                    end
                    if (send_status.substr(0, 1) != "OK") begin
                        $display("Socket0 Send failed: xxx%sxxx", send_status.substr(0, 1));
                    end

                    // 接收ready信号
                    recv_data = socket_recv(0);
                    if (debug == "1") begin
                        $display("Socket0 Receive ready at %t: %s\n", $time, recv_data);
                    end
                    if (recv_data.substr(0, 4) != "ERROR") begin
                        rx_packet1.deserialize(recv_data);
                        intf_internal.ready = rx_packet1.ready;
                    end else begin
                        $display("Socket0 Receive failed: %s", recv_data);
                    end
                end
            end

            // Socket3: 接收数据，发送ready信号 (对应intf_out0)
            forever begin
                string send_status;
                string recv_data;
                @(posedge intf_out0.clk or negedge intf_out0.rst_n);
                if (intf_out0.rst_n)begin
                    // 发送ready信号
                    tx_packet2.ready = intf_out0.ready;
                    send_status = socket_send(3, tx_packet2.serialize());
                    if (debug == "1") begin
                        $display("Socket3 Send ready at %t: %s\n", $time, tx_packet2.serialize());
                    end
                    if (send_status.substr(0, 1) != "OK") begin
                        $display("Socket3 send ready failed: %s", send_status);
                    end
    
                    // 接收数据
                    recv_data = socket_recv(3);
                    if (debug == "1") begin
                        $display("Socket3 receive data at %t: %s\n", $time, recv_data);
                    end
                    if (recv_data.substr(0, 4) != "ERROR") begin
                        rx_packet2.deserialize(recv_data);
                        intf_out0.data = rx_packet2.data;
                        intf_out0.valid = rx_packet2.valid;
                    end else begin
                        $display("Socket3 receive failed: %s", recv_data);
                    end
                end
            end

            // Socket4: 接收数据，发送ready信号 (对应intf_out1)
            forever begin
                string send_status;
                string recv_data;
                @(posedge intf_out1.clk or negedge intf_out1.rst_n);
                if (intf_out1.rst_n) begin
                    // 发送ready信号
                    tx_packet3.ready = intf_out1.ready;
                    send_status = socket_send(4, tx_packet3.serialize());
                    if (debug == "1") begin
                        $display("Socket4 Send ready at %t: %s\n", $time, tx_packet3.serialize());
                    end
                    if (send_status.substr(0, 1) != "OK") begin
                        $display("Socket4 send ready failed: %s", send_status);
                    end
    
                    // 接收数据
                    recv_data = socket_recv(4);
                    if (debug == "1") begin
                        $display("Socket4 receive data at %t: %s\n", $time, recv_data);
                    end
                    if (recv_data.substr(0, 4) != "ERROR") begin
                        rx_packet3.deserialize(recv_data);
                        intf_out1.data = rx_packet3.data;
                        intf_out1.valid = rx_packet3.valid;
                    end else begin
                        $display("Socket4 receive failed: %s", recv_data);
                    end
                end
            end
        join
    end

    final begin
        // 这里的代码将在仿真结束时执行
        $display("Simulation ending, performing final tasks...");
        socket_send(5, "simulation end");
        // 执行清理操作，打印最终统计信息等
    end
endprogram

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
    data_if intf_out0(clk, rst_n); // 输出接口0
    data_if intf_out1(clk, rst_n); // 输出接口1

    // 实例化 program 块
    socket_pgm test_prog(.intf_in(intf_in), .intf_internal(intf_internal), .intf_out0(intf_out0), .intf_out1(intf_out1));

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