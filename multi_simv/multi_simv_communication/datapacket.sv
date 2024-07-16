class DataPacket;
    rand logic [1023:0] data;
    logic valid;
    logic ready;

    function new(logic [1023:0] d = 0, logic v = 0, logic r = 0);
        data = d;
        valid = v;
        ready = r;
    endfunction

    function string serialize();
        bit [2047:0] encoded_data;
        string data_str;
        
        // 编码每一位，使用2位来表示每个原始位
        for (int i = 0; i < 1024; i++) begin
            case (data[i])
                1'b0: encoded_data[2*i +: 2] = 2'b00;
                1'b1: encoded_data[2*i +: 2] = 2'b01;
                1'bx: encoded_data[2*i +: 2] = 2'b10;
                1'bz: encoded_data[2*i +: 2] = 2'b11;
            endcase
        end
        
        // 将编码后的数据转换为十六进制字符串
        data_str = $sformatf("%0512h", encoded_data);
        return $sformatf("%s,%b,%b", data_str, valid, ready);
    endfunction

    task deserialize(string s);
        string parts[$];
        bit [2047:0] encoded_data;
        split(s, ",", parts);
        
        // 将十六进制字符串转回2048位数据
        void'($sscanf(parts[0], "%h", encoded_data));
        
        // 解码每一对位
        for (int i = 0; i < 1024; i++) begin
            case (encoded_data[2*i +: 2])
                2'b00: data[i] = 1'b0;
                2'b01: data[i] = 1'b1;
                2'b10: data[i] = 1'bx;
                2'b11: data[i] = 1'bz;
            endcase
        end
        
        valid = (parts[1] == "1") ? 1'b1 :
                (parts[1] == "0") ? 1'b0 :
                (parts[1] == "x") ? 1'bx : 1'bz;

        ready = (parts[2] == "1") ? 1'b1 :
                (parts[2] == "0") ? 1'b0 :
                (parts[2] == "x") ? 1'bx : 1'bz;
    endtask

    // split 函数保持不变
    local function void split(string s, string delim, ref string result[$]);
        int pos = 0, start = 0;
        while (pos != -1) begin
            pos = str_index_of(s, delim, start);
            if (pos == -1) begin
                result.push_back(s.substr(start, s.len()-1));
            end else begin
                result.push_back(s.substr(start, pos-1));
                start = pos + delim.len();
            end
        end
    endfunction

    local function int str_index_of(string s, string sub, int start);
        for (int i = start; i < s.len() - sub.len() + 1; i++) begin
            if (s.substr(i, i + sub.len() - 1) == sub) return i;
        end
        return -1;
    endfunction
endclass