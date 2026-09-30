# Ejecutar con batalla_naval.xpr abierto. Genera evidencias del netlist y timing.
set project_path [get_property DIRECTORY [current_project]]
set reports [file join $project_path reports]
file mkdir $reports
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {error "Sintesis incompleta"}
open_run synth_1
report_utilization -file [file join $reports utilization_synth.rpt]
report_drc -file [file join $reports drc_synth.rpt]
set latches [get_cells -hier -filter {REF_NAME =~ LDCE* || REF_NAME =~ LDPE*}]
if {[llength $latches]>0} {error "Latches detectados: $latches"}
write_verilog -force -mode funcsim [file join $reports netlist_synth.v]
close_design
launch_runs impl_1 -to_step route_design -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {error "Implementacion incompleta"}
open_run impl_1
report_utilization -file [file join $reports utilization_impl.rpt]
report_timing_summary -report_unconstrained -file [file join $reports timing_impl.rpt]
report_drc -file [file join $reports drc_impl.rpt]
report_cdc -file [file join $reports cdc_impl.rpt]
report_clock_interaction -file [file join $reports clocks_impl.rpt]
set errors [get_drc_violations -filter {SEVERITY == Error}]
if {[llength $errors]>0} {error "DRC con errores: $errors"}
foreach delay {max min} {
 set paths [get_timing_paths -delay_type $delay -max_paths 1]
 if {[llength $paths]==0} {error "Sin paths para comprobar timing $delay"}
 if {[get_property SLACK [lindex $paths 0]]<0} {error "Timing $delay no cumple"}
}
write_verilog -force -mode timesim -sdf_anno true [file join $reports netlist_timesim.v]
write_sdf -force [file join $reports batalla_naval.sdf]
close_design
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
puts "Revisa reports/ y el estado de write_bitstream antes de programar la FPGA."
