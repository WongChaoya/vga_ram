set_global_assignment -entity "pll_pixel" -library "lib_pll_pixel" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "pll_pixel" -library "lib_pll_pixel" -name IP_TOOL_VERSION "19.1"
set_global_assignment -entity "pll_pixel" -library "lib_pll_pixel" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_pll_pixel" -name SPD_FILE [file join $::quartus(sip_path) "pll_pixel.spd"]

set_global_assignment -library "lib_pll_pixel" -name MISC_FILE [file join $::quartus(sip_path) "pll_pixel_sim/pll_pixel.vo"]
