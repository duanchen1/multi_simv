# File: filelist_top_1.f

# 接口定义
+incdir+../interfaces
../interfaces/data_if.sv

# 设计文件
+incdir+../rtl
../rtl/data_forward.v
../rtl/data_demux.v

# UVM组件
+incdir+../env
../env/data_seq_item.sv
../env/data_driver.sv
../env/data_monitor.sv
../env/data_sequencer.sv
../env/data_agent_cfg.sv
../env/data_agent.sv
../env/data_scoreboard.sv
../env/data_env_cfg.sv
../env/data_env.sv

# 环境和测试文件
+incdir+../testcase
../testcase/data_sequence.sv
../testcase/forward_test.sv

# 顶层测试平台
./tb_top_1.sv
