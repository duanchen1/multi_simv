class DataPacket;
    rand bit [1023:0] data;
    bit valid;
    bit ready;

    function new(bit [1023:0] d = 0, bit v = 0, bit r = 0);
        data = d;
        valid = v;
        ready = r;
    endfunction

    function string serialize();
        return $sformatf("%h,%b,%b", data, valid, ready);
    endfunction

    task deserialize(string s);
        string parts[$];
        split(s, ",", parts);
        void'($sscanf(parts[0], "%h", data));
        void'($sscanf(parts[1], "%b", valid));
        void'($sscanf(parts[2], "%b", ready));
    endtask

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