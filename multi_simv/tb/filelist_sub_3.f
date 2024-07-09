# File: filelist_sub_3.f

# 接口定义
+incdir+../interfaces
../interfaces/data_if.sv

# 设计文件
+incdir+../rtl
../rtl/data_forward.v

../multi_simv_communication/datapacket.sv
# 顶层测试平台
./tb_sub_3.sv