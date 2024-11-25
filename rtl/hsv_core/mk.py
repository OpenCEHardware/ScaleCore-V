from mk import *

hsv_core                 = RtlPackage('hsv_core')
hsv_core_pkg             = RtlPackage('hsv_core_pkg')
hsv_core_decode_pkg      = RtlPackage('hsv_core_decode_pkg')
hsv_core_top_flat        = RtlPackage('hsv_core_top_flat')
hsv_core_ctrlstatus_regs = RdlPackage('hsv_core_ctrlstatus_regs')
hsv_core_altera_ip       = QuartusQsysLibraryPackage('hsv_core_altera_ip') # Platform Designer library

if_common = find_package('if_common')
rtl       = find_files('**/*.sv')

hsv_core.requires (hsv_core_pkg)
hsv_core.requires (hsv_core_decode_pkg)
hsv_core.requires (hsv_core_ctrlstatus_regs)
hsv_core.rtl      (rtl)
hsv_core.top      ()

hsv_core_pkg.requires (if_common)
hsv_core_pkg.rtl      (rtl.take('hsv_core_pkg.sv'))

hsv_core_top_flat.requires (hsv_core)
hsv_core_top_flat.rtl      (rtl.take('hsv_core_top_flat.sv'))
hsv_core_top_flat.top      ()

hsv_core_decode_pkg.requires (hsv_core_pkg)
hsv_core_decode_pkg.rtl      (rtl.take('decode/hsv_core_decode_pkg.sv'))

hsv_core_ctrlstatus_regs.rdl           ('ctrlstatus/hsv_core_ctrlstatus_regs.rdl')
hsv_core_ctrlstatus_regs.top           ()
hsv_core_ctrlstatus_regs.args          (['--default-reset', 'arst_n'])
hsv_core_ctrlstatus_regs.cpu_interface ('passthrough')

hsv_core_altera_ip.requires (hsv_core_top_flat)
hsv_core_altera_ip.hw_tcl   ('hsv_core_hw.tcl')
hsv_core_altera_ip.top      ('hsv_core_top_flat')
