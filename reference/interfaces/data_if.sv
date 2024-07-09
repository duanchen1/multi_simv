interface data_if (input clk, input rst_n);
  logic [1023:0] data;
  logic valid;
  logic ready;

  modport dut (
      input clk,
      input rst_n,
      input data,
      input valid,
      output ready
  );

  modport tb (
      input clk,
      input rst_n,
      output data,
      output valid,
      input ready
  );
endinterface