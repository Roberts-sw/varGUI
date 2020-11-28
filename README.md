# varGUI
Tcl application with function keys for sending serial port messages.
Function key messages ending at \n will be sent at (Modifier-)Fn key press,
while messages without will be directed to the message entry for editing
before send.

Article: -. 

Owner: Roberts-sw.

Changes:
- 28-11-2020 v0.2
  1. use of "chan subcommand" for stream i/o except for console output
  1. array app completed by reading ini file varGUI.ini
  1. ini file varGUI.ini used for remembering config file name
  1. config file defaults to default.cfg in application folder
  1. File submenus "New" or "Save" or "Save as" all use _file_save_app_and_cfg
     to update varGUI.ini as well as the chosen config file
  1. removed filetypes from array app
  1. dedicated filetypes in file selectors, override by typing filename
  1. added filedo for file manipulation
  1. added --- to empty plain Fn row to remove need for brackets in ini file
  1. string map in data_rd and data_wr removes need for brackets in cfg file
  1. added comment in data_rd
  1. changed _file_dir_name to be used for more than just cfg file
  1. Config submenu "Logging" and _config_log_btn use _file_dir_name
  1. incorporated todo_list in Help > About
  1. assembled initialisation into procedures
  1. gui_init sets default menu functions with alert boxes
  1. menu_implement_functions redefines these for real actions
  1. added serial port functions
  1. data_wr now skips serial port file handle, default Fn key text and
     empty Fn key messages in generating data to save as config file
  1. added function program_exit to close serial port before exiting
  1. menu functions use fully qualified names for cfg and app arrays to
     prevent needing the keyword global
  1. Help > About only resizable in y-direction
  1. Edit > Fn keys not resizable
  1. Config > Serial not resizable
  1. Config > Logging not resizable
  1. text entry deleted and focus set to entry after pressing <Return>
  1. Added bindings to Fn keys to send if message ends with \n and to
     edit before sending otherwise
  1. added labels at frames around submenu windows
  1. quite some minor bug fixes upon testing with devices that have minor
     differences in serial port signalling

- 26-11-2020 v0.1
  1. initial setup of menus and some functionality