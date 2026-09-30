# Crear o completar el proyecto integrado sin borrar fuentes existentes.
# Guardar este archivo en Integracion/scripts/create_project.tcl.
set root [file normalize [file join [file dirname [info script]] ../..]]
set project_dir [file join $root vivado_integrado]
set project_file [file join $project_dir batalla_naval.xpr]
set rtl_list [file join $root Integracion/scripts/rtl_files.f]

# Revisar TODO antes de crear el proyecto: un ZIP incompleto no deja un XPR vacio.
if {![file isfile $rtl_list]} {
 error "No existe $rtl_list. Guarda este script dentro de Integracion/scripts/."
}
set fp [open $rtl_list r]
set rtl_files {}
foreach line [split [read $fp] "\n"] {
 set line [string trim $line]
 if {$line ne "" && ![string match {#*} $line]} {
  lappend rtl_files [file normalize [file join $root $line]]
 }
}
close $fp
set rom_file [file join $root Integracion/firmware/batalla_naval.mem]
set xdc_file [file join $root Integracion/constraints/batalla_naval_basys3.xdc]
set hook_file [file join $root Integracion/scripts/stage_rom.tcl]
set tb_files {}
foreach tb {tb_batalla_naval_system tb_system_nominal_uart tb_integration_memory} {
 lappend tb_files [file join $root Integracion/tb/$tb.sv]
}
set missing_files {}
foreach path [concat $rtl_files $tb_files [list $rom_file $xdc_file $hook_file]] {
 if {![file isfile $path]} {lappend missing_files $path}
}
if {[llength $missing_files]>0} {
 error "Faltan archivos del paquete:\n[join $missing_files \n]\nExtrae el ZIP completo antes de continuar."
}

# Reutilizar el XPR de una creacion parcial. No usar create_project -force.
set active_project ""
catch {set active_project [current_project]}
if {$active_project ne ""} {
 set active_dir [file normalize [get_property DIRECTORY $active_project]]
 if {$active_dir ne [file normalize $project_dir] || [get_property NAME $active_project] ne "batalla_naval"} {
  error "Hay otro proyecto abierto. Cierra ese proyecto (File > Close Project) y vuelve a ejecutar este script."
 }
 puts "Completando el proyecto abierto: $project_file"
} elseif {[file isfile $project_file]} {
 open_project $project_file
 puts "Completando el proyecto existente: $project_file"
} else {
 create_project batalla_naval $project_dir -part xc7a35tcpg236-1
 puts "Creado el proyecto: $project_file"
}
set_property target_language Verilog [current_project]

# add_files solo para archivos ausentes en el fileset correspondiente.
proc bn_add_missing {fileset paths} {
 set existing_files {}
 foreach item [get_files -quiet -of_objects [get_filesets $fileset]] {
  lappend existing_files [file normalize [get_property NAME $item]]
 }
 foreach path $paths {
  set path [file normalize $path]
  if {[lsearch -exact $existing_files $path]<0} {
   add_files -fileset $fileset -norecurse $path
   lappend existing_files $path
  }
 }
}
bn_add_missing sources_1 $rtl_files
bn_add_missing sources_1 [list $rom_file]
set_property file_type {Memory Initialization Files} [get_files $rom_file]
bn_add_missing constrs_1 [list $xdc_file]
bn_add_missing sim_1 $tb_files
set_property top batalla_naval_top [get_filesets sources_1]
set_property top tb_batalla_naval_system [get_filesets sim_1]
set_property xsim.simulate.runtime {0ns} [get_filesets sim_1]
set_property xsim.simulate.log_all_signals false [get_filesets sim_1]
set_property xsim.elaborate.debug_level typical [get_filesets sim_1]
set_property xsim.compile.tcl.pre $hook_file [get_filesets sim_1]
set_property STEPS.SYNTH_DESIGN.TCL.PRE $hook_file [get_runs synth_1]
puts "Agregadas [llength $rtl_files] fuentes RTL y [llength $tb_files] testbenches."

# El modelo vga_clock_sim.sv es exclusivo de Verilator: NO agregarlo a Vivado.
if {[llength [get_ips -quiet vga_clock]]==0} {
 create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name vga_clock
}
set_property -dict [list CONFIG.PRIM_IN_FREQ {100.000} \
 CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {25.000} CONFIG.CLK_OUT1_PORT {pixel_clk} \
 CONFIG.USE_LOCKED {true} CONFIG.USE_RESET {true} CONFIG.RESET_TYPE {ACTIVE_HIGH} \
 CONFIG.PRIMITIVE {PLL}] [get_ips vga_clock]
generate_target all [get_ips vga_clock]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "LISTO: batalla_naval_top en Design Sources; tb_batalla_naval_system en Simulation Sources."
puts "Simulacion: launch_simulation; run all"
