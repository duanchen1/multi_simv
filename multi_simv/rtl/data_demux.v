module Data_Demux #(
    parameter DATA_WIDTH = 1024,
    parameter FIFO_DEPTH = 8  // 新增FIFO深度参数
) (
    input wire clk,
    input wire rst_n,

    // 输入接口
    input wire [DATA_WIDTH-1:0] data_in,
    input wire valid_in,
    output wire ready_in,

    // 输出接口 0 (偶数)
    output wire [DATA_WIDTH-1:0] data_out0,
    output wire valid_out0,
    input wire ready_out0,

    // 输出接口 1 (奇数)
    output wire [DATA_WIDTH-1:0] data_out1,
    output wire valid_out1,
    input wire ready_out1
);
    // 1位计数器
    reg count;
    // 内部信号
    reg [DATA_WIDTH-1:0] data_reg;
    reg valid_reg0, valid_reg1;

    // FIFO 信号
    reg [DATA_WIDTH-1:0] fifo [FIFO_DEPTH-1:0];
    reg [$clog2(FIFO_DEPTH):0] wr_ptr, rd_ptr;
    wire fifo_empty = (wr_ptr == rd_ptr);
    wire fifo_full = (wr_ptr[2:0] == rd_ptr[2:0]) && (wr_ptr[$clog2(FIFO_DEPTH)] != rd_ptr[$clog2(FIFO_DEPTH)]);

    // FIFO写入逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (valid_in && ready_in) begin
            fifo[wr_ptr[2:0]] <= data_in;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // FIFO读出逻辑
    wire fifo_read = !fifo_empty && ((!valid_reg0 && !valid_reg1) || (valid_reg0 && ready_out0) || (valid_reg1 && ready_out1));
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
        end else if (fifo_read) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // 计数器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 1'b0;
        end else if (fifo_read) begin
            count <= ~count;
        end
    end

    // 数据和有效信号寄存逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= {DATA_WIDTH{1'b0}};
            valid_reg0 <= 1'b0;
            valid_reg1 <= 1'b0;
        end else if (fifo_read) begin
            data_reg <= fifo[rd_ptr[2:0]];
            if (count) begin
                valid_reg1 <= 1'b1;
                valid_reg0 <= 1'b0;
            end else begin
                valid_reg0 <= 1'b1;
                valid_reg1 <= 1'b0;
            end
        end else begin
            if (valid_reg0 && ready_out0) valid_reg0 <= 1'b0;
            if (valid_reg1 && ready_out1) valid_reg1 <= 1'b0;
        end
    end

    // 使用generate添加可控的无用逻辑
    genvar gen_i;
    generate
        for (gen_i = 0; gen_i < 25000; gen_i = gen_i + 1) begin : dummy_logic_block
            reg [DATA_WIDTH-1:0] dummy_reg[10];
            reg [31:0] dummy_counter;
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    for(int i=0;i<10;i++)
                        dummy_reg[i] <= {DATA_WIDTH{1'b0}};
                    dummy_counter <= 32'd0;
                end else begin
                    for(int i=1;i<9;i++)
                        dummy_reg[i+1] <= dummy_reg[i] * dummy_counter;
                    if (dummy_counter < 10000) begin
                        dummy_counter <= dummy_counter + 1;
                        case(gen_i % 4)
                            0: dummy_reg[0] <= dummy_reg[0] + dummy_counter;
                            1: dummy_reg[0] <= dummy_reg[0] * dummy_counter;
                            2: dummy_reg[0] <= dummy_reg[0] * {DATA_WIDTH{dummy_counter[0]}};
                            3: dummy_reg[0] <= {dummy_reg[0][0], dummy_reg[0][DATA_WIDTH-1:1]};
                        endcase
                    end else begin
                        dummy_counter <= 32'd0;
                    end
                end
            end
        end
    endgenerate

    // 输出赋值
    assign data_out0 = data_reg;
    assign data_out1 = data_reg;
    assign valid_out0 = valid_reg0;
    assign valid_out1 = valid_reg1;

    // 输入就绪信号
    assign ready_in = !fifo_full;

endmodule