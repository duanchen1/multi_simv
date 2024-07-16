program socket_pgm(
    data_if intf_in,
    data_if intf_out
);
    import "DPI-C" function int socket_init(input int is_server, input string address, input int port, input string base_path, input int socket_index, input int max_clients=1);
    import "DPI-C" function string socket_send(input int socket_index, input string data);
    import "DPI-C" function string socket_recv(input int socket_index, input int non_blocking=0);

    DataPacket tx_packet1, tx_packet2;
    DataPacket rx_packet1, rx_packet2;

    string debug = "0";

    initial begin
        int init_result;
        string testname;
        string socket_path_pre;

        tx_packet1 = new();
        tx_packet2 = new();
        rx_packet1 = new();
        rx_packet2 = new();
        
        if (!$value$plusargs("UVM_TESTNAME=%s", testname)) begin
            $display("Failed to get testname");
            $finish;
        end

        void'($sformat(socket_path_pre, "/tmp/%s_socket_", testname));
        
        // 初始化 socket
        init_result = socket_init(0, "", 0, socket_path_pre, 1);  // socket1 作为客户端
        if (init_result == -1) begin
            $display("Failed to connect server socket1");
            $finish;
        end

        init_result = socket_init(1, "", 0, socket_path_pre, 3);  // socket3 作为服务器
        if (init_result == -1) begin
            $display("Failed to initialize socket3 to server");
            $finish;
        end

        init_result = socket_init(0, "", 0, socket_path_pre, 5);  // socket5 作为客户端
        if (init_result == -1) begin
            $display("Failed to initialize socket2 to server");
            $finish;
        end
    end

    
    initial begin
        if (!$value$plusargs("debug=%s", debug)) begin
            $display("Failed to get debug default tp %d", debug);
        end
        
        fork
            // Socket1: 接收数据，发送ready信号
            forever begin
                string send_status;
                string recv_data;
                #1;
                
                // 发送ready信号
                tx_packet1.ready = intf_in.ready;
                send_status = socket_send(1, tx_packet1.serialize());
                if (debug == "1") begin
                    $display("Socket1 send ready at %t: %s\n", $time, tx_packet1.serialize());
                end
                if (send_status.substr(0, 1) != "OK") begin
                    $display("Socket1 send ready failed: %s", send_status);
                end

                // 接收数据
                recv_data = socket_recv(1);
                if (debug == "1") begin
                    $display("Socket1 receive data at %t: %s\n", $time, recv_data);
                end
                if (recv_data.substr(0, 4) != "ERROR") begin
                    rx_packet1.deserialize(recv_data);
                    intf_in.data = rx_packet1.data;
                    intf_in.valid = rx_packet1.valid;
                end else begin
                    $display("Socket1 receive failed: %s", recv_data);
                end
            end

            // Socket3: 发送数据，接收ready信号 (对应intf_out)
            forever begin
                string send_status;
                string recv_data;
                #1;

                // 准备发送数据
                tx_packet2.data = intf_out.data;
                tx_packet2.valid = intf_out.valid;

                // 发送数据
                send_status = socket_send(3, tx_packet2.serialize());
                if (debug == "1") begin
                    $display("Socket3 Send data at %t: %s\n", $time, tx_packet2.serialize());
                end
                if (send_status.substr(0, 1) != "OK") begin
                    $display("Socket3 Send failed: %s", send_status);
                end

                // 接收ready信号
                recv_data = socket_recv(3);
                if (debug == "1") begin
                    $display("Socket3 Receive ready at %t: %s\n", $time, recv_data);
                end
                if (recv_data.substr(0, 4) != "ERROR") begin
                    rx_packet2.deserialize(recv_data);
                    intf_out.ready = rx_packet2.ready;
                end else begin
                    $display("Socket3 Receive failed: %s", recv_data);
                end
            end
        join
    end

    initial begin
        string recv_data;
        forever begin
            #1;
            recv_data = socket_recv(5, 1);
            if (recv_data == "simulation end")
                $finish;
        end
    end
endprogram

module tb_sub_3;
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
    data_if intf_out(clk, rst_n); // 输出接口

    // 实例化 program 块
    socket_pgm test_prog(.intf_in(intf_in), .intf_out(intf_out));

    // DUT实例化
    Data_Forward #(.DATA_WIDTH(1024), .FIFO_DEPTH(8)) dut(
        .clk(clk),
        .rst_n(rst_n),
        // 输入接口
        .data_in(intf_in.data),
        .valid_in(intf_in.valid),
        .ready_in(intf_in.ready),
        // 输出接口
        .data_out(intf_out.data),
        .valid_out(intf_out.valid),
        .ready_out(intf_out.ready)
    );

    // 添加一个参数来控制是否生成 FSDB
    bit dump_fsdb;

    // FSDB dump 控制
    initial begin
        if ($test$plusargs("dump_fsdb")) begin
            dump_fsdb = 1;
            $fsdbDumpfile("tb_sub_3.fsdb");
            $fsdbDumpvars(0, tb_sub_3);
            $fsdbDumpMDA(); // dump 数组和记忆单元
            $display("FSDB dump enabled");
        end else begin
            dump_fsdb = 0;
        end
    end

endmodule