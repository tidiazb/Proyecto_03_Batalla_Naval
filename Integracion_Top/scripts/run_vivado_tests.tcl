# Proyecto integrado abierto. Verifica PASS en el log de cada simulacion.
set project_path [get_property DIRECTORY [current_project]]
set log_dir [file join $project_path [current_project].sim sim_1 behav xsim]
set evidence_dir [file join $project_path reports simulation]
file mkdir $evidence_dir
foreach test {tb_integration_memory tb_system_nominal_uart tb_batalla_naval_system} {
 catch {close_sim}
 set_property top $test [get_filesets sim_1]
 launch_simulation
 run all
 close_sim
 set passed 0
 foreach filename {simulate.log xsim.log} {
  set log_file [file join $log_dir $filename]
  if {[file exists $log_file]} {
   set fp [open $log_file r]
   set output [read $fp]
   close $fp
   if {[string first "PASS $test" $output]>=0 && [string first "Fatal:" $output]<0} {
    file copy -force $log_file [file join $evidence_dir $test.log]
    set passed 1
    break
   }
  }
 }
 if {!$passed} {error "No se encontro PASS $test; revisa $log_dir"}
 puts "PASS $test (log guardado en reports/simulation/)"
}
set_property top tb_batalla_naval_system [get_filesets sim_1]
