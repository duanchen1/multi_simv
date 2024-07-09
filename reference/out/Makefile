comp:
	mkdir -p top_1
	time vcs -full64 -F ../tb/filelist_top_1.f -Mdir=top_1 -o top_1/simv -l ../out/top_1/compile.log -ntb_opts uvm-1.2 -sverilog +v2k -timescale=1ns/1ps +vcs+lic+wait -debug_access+all&

run:
	time top_1/simv -l top1.log +fsdb+region +dump_fsdb +ntb_random_seed_automatic +UVM_TESTNAME=forward_test&

verdi:
	verdi -F ../tb/filelist_top_1.f -ssf tb_top_1.fsdb&

comp_fgp:
	mkdir -p top_1_fgp
	time vcs -fgp -full64 -F ../tb/filelist_top_1.f -Mdir=top_1_fgp -o top_1_fgp/simv -l ../out/top_1_fgp/compile.log -ntb_opts uvm-1.2 -sverilog +v2k -timescale=1ns/1ps +vcs+lic+wait -debug_access+all&

run_fgp:
	time top_1_fgp/simv -fgp=num_threads:5 -l top1.log +fsdb+region +dump_fsdb +ntb_random_seed_automatic +UVM_TESTNAME=forward_test&

.PHONY: clean
clean:
	find . -mindepth 1 -not -name 'Makefile' -exec rm -rf {} +

# ./simv -fgp=num_threads:3 sync:busywait, auto_affinity -xdprof=diag:ruse, -Xdprof=timeline 

