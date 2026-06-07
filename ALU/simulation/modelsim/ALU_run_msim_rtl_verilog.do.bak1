transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/ALU {C:/altera/13.0sp1/ALU/macros.v}
vlog -vlog01compat -work work +incdir+F:/Downloads/files\ (2) {F:/Downloads/files (2)/pipeline.v}
vlog -vlog01compat -work work +incdir+F:/Downloads/files\ (2) {F:/Downloads/files (2)/mul.v}
vlog -vlog01compat -work work +incdir+F:/Downloads/files\ (2) {F:/Downloads/files (2)/memory.v}
vlog -vlog01compat -work work +incdir+F:/Downloads/files\ (2) {F:/Downloads/files (2)/inst_fetch.v}
vlog -vlog01compat -work work +incdir+F:/Downloads/files\ (2) {F:/Downloads/files (2)/alu.v}
vlog -vlog01compat -work work +incdir+F:/Downloads/files\ (2) {F:/Downloads/files (2)/addsub.v}

vlog -vlog01compat -work work +incdir+C:/altera/13.0sp1/ALU {C:/altera/13.0sp1/ALU/alu_TB.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneii_ver -L rtl_work -L work -voptargs="+acc"  alu_TB

add wave *
view structure
view signals
run -all
