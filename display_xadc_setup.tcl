###############################################################################################
# $Revision$
# $Date$
# $Author$
#
###############################################################################################

proc display_xadc_create_project {} {

create_project display_xadc  -force display_xadc -part xc7a100tcsg324-1
add_files -norecurse {display_xadc_dpram.v ram_dual_port.v vga_sync.v display_mux.v nexys4_7segLED.v display_xadc.xdc}
import_ip -files {xadc_wiz_0.xci}
import_files -force -norecurse
import_files -fileset sim_1 -norecurse {design.txt display_xadc_tb.v}
update_compile_order -fileset sim_1
}

proc display_xadc_run_project {} {
if [string is alnum [current_project -quiet]] then {open_project ./display_xadc  /display_xadc.xpr} else {puts "project is [current_project]"}

reset_run -quiet synth_1
launch_runs synth_1
wait_on_run synth_1
launch_runs impl_1
wait_on_run impl_1
}

proc display_xadc_sim_project {} {
if [string is alnum [current_project -quiet]] then {open_project ./display_xadc/display_xadc.xpr} else {puts "project is [current_project]"}
if [string is alnum [current_sim -quiet]] then {} else {close_sim}
set_property xsim.view {display_xadc_tb.wcfg} [get_filesets sim_1]
launch_xsim -simset sim_1 -mode behavioral
run 150 us
}




namespace path {::tcl::mathop ::tcl::mathfunc}

proc hex2bin {hex} {
    return [string map -nocase {
        0 0000 1 0001 2 0010 3 0011 4 0100 5 0101 6 0110 7 0111 8 1000
        9 1001 a 1010 b 1011 c 1100 d 1101 e 1110 f 1111
        } $hex]

#        9 1001 a 1010 b 1011 c 1100 d 1101 e 1110 f 1111 A 1010 B 1011 C 1100 D 1101 E 1110 F 1111
}

proc hex2bin_ {hex} {
    return [string map -nocase {
        0 _0000 1 _0001 2 _0010 3 _0011 4 _0100 5 _0101 6 _0110 7 _0111 8 _1000
        9 _1001 a _1010 b _1011 c _1100 d _1101 e _1110 f _1111
        } $hex]

#        9 1001 a 1010 b 1011 c 1100 d 1101 e 1110 f 1111 A 1010 B 1011 C 1100 D 1101 E 1110 F 1111
}

proc ug480_hw_read_vccaux  {}  {
    set dut [lindex [get_hw_sysmons] 0]
    scan [set auxreg [get_hw_sysmon_reg $dut 0x2]] %x auxdec
    set auxhex 0x$auxreg
    set auxconv [format "%0.3f" [expr $auxdec * 3 / 65536.0]]
    puts "VCCAUX is $auxconv V\t<$auxreg> or expressed as 10 bits <[format %x [expr {$auxhex >>6 }]]>"
}

proc ug480_hw_read_vccint  {}  {
    set dut [lindex [get_hw_sysmons] 0]
    scan [set intreg [get_hw_sysmon_reg $dut 0x1]] %x intdec
    set inthex 0x$intreg
    set intconv [format "%0.3f" [expr $intdec * 3 / 65536.0]]
    puts "VCCINT is $intconv V\t<$intreg> or expressed as 10 bits <[format %x [expr {$inthex >>6 }]]>"
    
}

proc ug480_hw_read_vpvn  {}  {
    set dut [lindex [get_hw_sysmons] 0]
    scan [set vpvnreg [get_hw_sysmon_reg $dut 0x3]] %x vpvndec
    set vpvnhex 0x$vpvnreg
    set vpvnconv [format "%0.3f" [expr $vpvndec * 1 / 65536.0]]
    puts "Diff VP/VN is $vpvnconv V\t<$vpvnreg>  or expressed as 10 bits <[format %x [expr {$vpvnhex >>6 }]]>\n     Note: Vp/Vn is not a default channel"
}

proc ug480_hw_read_temp  {}  {
    set dut [lindex [get_hw_sysmons] 0]
    scan [set tempreg [get_hw_sysmon_reg $dut 0x0]] %x tempdec
    set temphex 0x$tempreg
    set tempconv [format "%0.1f" [expr ($tempdec * 503.975 / 65536) - 273.15]]
    puts "Temperature is $tempconv C\t<$tempreg>  or expressed as 10 bits <[format %x [expr {$temphex >>6 }]]>"
}


proc ug480_hw_read_auxilliary  {}  {
    set dut [lindex [get_hw_sysmons] 0]
    puts "\nReading AUX[15:0]"
    for {set i  0} { $i < 15} {incr i 1} {
        set daddr_ch [format %x [expr 16 + $i]]
        scan [set adreg [get_hw_sysmon_reg $dut 0x$daddr_ch]] %x addec
        set adhex 0x$adreg
        set ad [format "%0.3f" [expr $addec * 1 / 65536.0]]   
        puts "     Aux Channel $i: $ad V <$adreg>  or expressed as 10 bits <[format %x [expr {$adhex >>6 }]]>"
    }
    puts "\n     When reading auxilliary channels please make sure the Aux channel is enabled (0x48)\
    \n     and using a compatible sequencer mode (0x42). "
}


proc ug480_hw_settings  {}  {
    set dut [lindex [get_hw_sysmons] 0]
    
    puts "SYSMON is currently configured with the following:\n\
        \tConfiguration Registers:\n\
        \tCONFIG0   0x40: [get_hw_sysmon_reg $dut 0x40]\n\
        \tCONFIG1   0x41: [get_hw_sysmon_reg $dut 0x41]\n\
        \tCONFIG2   0x42: [get_hw_sysmon_reg $dut 0x42]\n\n\
        \tControl Registers when using Automatic Channel Sequencer:\n\
        \tSEQCHSEL0 0x46: [get_hw_sysmon_reg $dut 0x46]\n\
        \tSEQCHSEL1 0x48: [get_hw_sysmon_reg $dut 0x48]\n\
        \tSEQCHSEL2 0x49: [get_hw_sysmon_reg $dut 0x49]\n\n\
        \tSEQCHAVG0 0x47: [get_hw_sysmon_reg $dut 0x47]\n\
        \tSEQCHAVG1 0x4A: [get_hw_sysmon_reg $dut 0x4A]\n\
        \tSEQCHAVG2 0x4B: [get_hw_sysmon_reg $dut 0x4B]\n\n\
        \tSEQINMODE0 0x4C: [get_hw_sysmon_reg $dut 0x4C]\n\
        \tSEQINMODE1 0x4D: [get_hw_sysmon_reg $dut 0x4D]\n\
        \tSEQINMODE2 0x78: [get_hw_sysmon_reg $dut 0x78]\n\n\
        \tSEQACQ0 0x4E: [get_hw_sysmon_reg $dut 0x4E]\n\
        \tSEQACQ1 0x4F: [get_hw_sysmon_reg $dut 0x4F]\n\
        \tSEQACQ2 0x79: [get_hw_sysmon_reg $dut 0x79]\n"
    ug480_hw_read_temp
    ug480_hw_read_vccint
    ug480_hw_read_vccaux
    puts "\nSee UG480 for more information "
}

proc display_xadc_help {} {
    puts "The following are examples of SYSMON commands:\
\n            get_hw_sysmons\
\n            get_hw_sysmon_reg\
\n            set_hw_sysmon_reg\
\n            commit_hw_sysmon\
\n            refresh_hw_sysmon\
\n\ne.g."
puts {## Start of Example TCL for simple system with a single device that can be indexed as 0##}
puts {#Update and set rtemp to TEMPERATURE }
puts {refresh_hw_sysmon -properties [list TEMPERATURE] [lindex [get_hw_sysmons] 0]  } 
puts {set rtemp [get_property TEMPERATURE  [lindex [get_hw_sysmons] 0] ]            } 
puts {}
puts {#Setting the CAL2 bit to high.              }
puts {set_property CONFIG_REG.CAL2 1 [lindex [get_hw_sysmons] 0]                    }
puts {commit_hw_sysmon [lindex [get_hw_sysmons] 0]                                  }
puts {}
puts {# Read Config Register 0 0x48, overwrite with FFFF and read again}
puts {get_hw_sysmon_reg [lindex [get_hw_sysmons] 0] 0x48}
puts {set_hw_sysmon_reg [lindex [get_hw_sysmons] 0] 0x48 0xffff}
puts {get_hw_sysmon_reg [lindex [get_hw_sysmons] 0] 0x48}
puts {}
puts {scan [set intreg [get_hw_sysmon_reg [lindex [get_hw_sysmons] 0] 0x1]] %x intdec }
puts {set intconv [format "%0.3f" [expr $intdec * 3 / 65536.0]]}
puts {puts "VCCINT is $intconv V\t<$intreg>"}
puts {#set_hw_sysmon_reg [lindex [get_hw_sysmons] 0] 0x41 0x0000}
puts {## End of Example TCL ##}

puts "\n\n \
\n\nTCL script sets up the following commands:                                              \
\n     display_xadc_create_project - Creates/overwrites ./ug480_sysmone1/ug480_sysmone1.xpr project         \
\n                            NOTE <ug480_create_project> completely rebuilds the project. Previous work will be lost.   \
\n     display_xadc_run_project    - Opens and runs ./ug480_sysmone1/ug480_sysmone1.xpr project             \
\n     display_xadc_sim_project    - Performs behavioral simulation using the testbench and design.txt \
"
}

display_xadc_help

