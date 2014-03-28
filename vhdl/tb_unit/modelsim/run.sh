#!/bin/sh

# Settings...
export MODULE=mem_ctrl
export SIGNALS="\
	intClk \
	extClk \
	reset \
	--- \
	uut/mcAutoMode_in \
	uut/mcReady_out \
	uut/mcCmd_in \
	uut/mcAddr_in \
	uut/mcData_in \
	uut/mcData_out \
	uut/mcRDV_out \
	--- \
	uut/ramCmd_sym \
	uut/ramBank_out \
	uut/ramAddr_out \
	uut/ramData_io \
	uut/ramLDQM_out \
	uut/ramUDQM_out \
	--- \
	uut/state \
	uut/count \
	uut/rowAddr \
	uut/wrData \
"

# Compile HDLs
rm -rf work stimulus.sim results.sim results.vcd startup.do virtuals.do transcript vsim.wlf
vlib work
vlog +define+v +define+S75 +define+M128 +define+X16 +define+NBANK4 -work work ../mt48lc8m16a2.v
vcom -work work \
	../../mem_ctrl_pkg.vhdl \
	../../mem_ctrl.vhdl \
	../../mem_ctrl_rtl.vhdl \
	../../../../sim-utils/vhdl/hex_util.vhdl \
	../sdram_model.vhdl \
	../sdram_model_accurate.vhdl \
	../mem_ctrl_tb.vhdl

# Create startup files and vsim command-line
echo 'virtual type {lmr ref pre act write read xxx nop} RamCmdType' >> startup.do
echo 'virtual function {(RamCmdType)uut/ramcmd_out} ramCmd_sym' >> startup.do
for i in ${SIGNALS}; do
	if [ "${i}" = "---" ]; then
		echo 'add wave -divider' >> startup.do
	else
		echo "add wave $i" >> startup.do
	fi
done
echo 'radix -hexadecimal' >> startup.do
echo 'run 2500ns' >> startup.do
echo 'bookmark add wave default {{1260ns} {1780ns}}' >> startup.do
echo 'bookmark goto wave default' >> startup.do

# Run simulation
cp ../stimulus.sim .
vsim -novopt ${MODULE}_tb -t ps -do startup.do

diff ../expected.sim results.sim
