comp:
	mkdir -p top_1
	mkdir -p sub_2
	mkdir -p sub_3
	mkdir -p sub_4
	g++ -g -std=c++11 -fPIC -shared -o ../multi_simv_communication/libsocket_comm.so ../multi_simv_communication/socket.cpp -I${VCS_HOME}/include
	time vcs -full64 -F ../tb/filelist_top_1.f -Mdir=top_1 -o top_1/simv -l ../out/top_1/compile.log -ntb_opts uvm-1.2 -sverilog +v2k -timescale=1ns/1ps -debug_access+all&
	time vcs -full64 -F ../tb/filelist_sub_2.f -Mdir=sub_2 -o sub_2/simv -l ../out/sub_2/compile.log -sverilog +v2k -timescale=1ns/1ps -debug_access+all&
	time vcs -full64 -F ../tb/filelist_sub_3.f -Mdir=sub_3 -o sub_3/simv -l ../out/sub_3/compile.log -sverilog +v2k -timescale=1ns/1ps -debug_access+all&
	time vcs -full64 -F ../tb/filelist_sub_4.f -Mdir=sub_4 -o sub_4/simv -l ../out/sub_4/compile.log -sverilog +v2k -timescale=1ns/1ps -debug_access+all&

run:
	time top_1/simv -l top1.log +fsdb+region +dump_fsdb -sv_root ../multi_simv_communication/ -sv_lib libsocket_comm +ntb_random_seed_automatic +UVM_TESTNAME=forward_test&
	time sub_2/simv -l sub2.log +fsdb+region +dump_fsdb -sv_root ../multi_simv_communication/ -sv_lib libsocket_comm +ntb_random_seed_automatic +UVM_TESTNAME=forward_test&
	time sub_3/simv -l sub3.log +fsdb+region +dump_fsdb -sv_root ../multi_simv_communication/ -sv_lib libsocket_comm +ntb_random_seed_automatic +UVM_TESTNAME=forward_test&
	time sub_4/simv -l sub4.log +fsdb+region +dump_fsdb -sv_root ../multi_simv_communication/ -sv_lib libsocket_comm +ntb_random_seed_automatic +UVM_TESTNAME=forward_test&

verdi:
	verdi -F ../tb/filelist_top_1.f -ssf tb_top_1.fsdb&
	verdi -F ../tb/filelist_sub_2.f -ssf tb_sub_2.fsdb&
	verdi -F ../tb/filelist_sub_3.f -ssf tb_sub_3.fsdb&
	verdi -F ../tb/filelist_sub_4.f -ssf tb_sub_4.fsdb&

verdi1:
	verdi -F ../tb/filelist_top_1.f -ssf tb_top_1.fsdb&

verdi2:
	verdi -F ../tb/filelist_sub_2.f -ssf tb_sub_2.fsdb&

verdi3:
	verdi -F ../tb/filelist_sub_3.f -ssf tb_sub_3.fsdb&

verdi4:
	verdi -F ../tb/filelist_sub_4.f -ssf tb_sub_4.fsdb&

.PHONY: clean
clean:
	find . -mindepth 1 -not -name 'Makefile' -exec rm -rf {} +


