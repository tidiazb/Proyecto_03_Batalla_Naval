# Hook de pre-compilacion XSim y pre-sintesis.
set root [file normalize [file join [file dirname [info script]] ../..]]
set from [file join $root Integracion/firmware/batalla_naval.mem]
if {![file exists $from]} {error "No existe $from"}
# El hook de simulacion puede ejecutarse antes de cambiar el directorio activo.
# Preparar tanto pwd como el directorio XSim del proyecto creado por el script.
set targets [list [pwd] [file join $root vivado_integrado batalla_naval.sim sim_1 behav xsim]]
foreach directory $targets {
 file mkdir $directory
 set to [file normalize [file join $directory batalla_naval.mem]]
 if {[file normalize $from] ne $to} {file copy -force $from $to}
 puts "ROM preparada en $to"
}
