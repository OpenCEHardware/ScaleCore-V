from mk import *

tb_hsv_core_alu              = CocotbTestPackage('tb_hsv_core_alu')
tb_hsv_core_issue_hazardmask = SystemVerilogTestPackage('tb_hsv_core_issue_hazardmask')
tb_hsv_core_issue_regfile    = SystemVerilogTestPackage('tb_hsv_core_issue_regfile')

hsv_core = find_package('hsv_core')

tb_hsv_core_alu.requires       (hsv_core)
tb_hsv_core_alu.top            ('hsv_core_alu_tb_top')
tb_hsv_core_alu.cocotb_paths   (['./alu'])
tb_hsv_core_alu.cocotb_modules (['tb_hsv_core_alu'])

tb_hsv_core_issue_hazardmask.requires (hsv_core)
tb_hsv_core_issue_hazardmask.top      ()
tb_hsv_core_issue_hazardmask.main     ('issue/tb_hsv_core_issue_hazardmask.sv')

tb_hsv_core_issue_regfile.requires (hsv_core)
tb_hsv_core_issue_regfile.top      ()
tb_hsv_core_issue_regfile.main     ('issue/tb_hsv_core_issue_regfile.sv')
