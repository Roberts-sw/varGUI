# varGUI
Owner: Roberts-sw.

Tcl application with function keys for sending serial port messages.  
Function key messages ending at \n will be sent at (Modifier-)Fn key press,  
while messages without will be directed to the message entry for editing before send.

#### configuration

The configuration is divided between two arrays:

1. **app** has information regarding Fn-key rows and cols as well as the cfg file location
2. **cfg** has the Fn-configuration as well as Log\_* and Ser\_* config-settings.

#### changes:

- 31-03-2022 v0.8
  - Hwserial_connect now can open COM10 and higher on Windows
- 03-03-2022 v0.8
  - re-opening .cfg closes serial port before re-opening it.
  - added piggy-back for commands by including "\n" before new command
  - changed bindings to include "break"
  - added crc and line_end to "config_serial" and "_cfg_serial_ok"
  - included crc-possibility with an example in "crc.8003.B"
  - moved source of "Hwserial_rcv" to before "Hwserial_transmit"
  - put some explanation into "Hwserial_rcv" and "Hwserial_transmit"
  - included "corp" for introspection in console
- 06-08-2021 v0.7
  - corrected log timestamp
- 20-04-2021 v 0.7
  - removed "package require registry" line
  - added link to github-repo in help file
  - changed default function key label width to 15
  - made it possible to use less than 12 Fn keys. As an example restrict to 10  
    by deleting cols 11 and 12 from file "varGUI.ini".
- 14-12-2020 v 0.6
  - corrected parity setting to take only first letter from one of `none even odd`.
- 11-12-2020 v0.5
  - added accelerator keys to most menu items
  - mouse right-click to change individual Fn key settings: call _Fn_key_edit
  - added cfg_fn_def to populate individual default Fn key settings
- 2-12-2020 v0.4
  - Arduino boards likely have a capacitor in series with the RTSn-pin of the  
    TTL-232R interface (pin 6, green wire), connected to the pull-up resistor  
    of the ucon reset pin.  
    Connecting to this interface with RTS on will reset the board because the  
    combination of both components will generate a pulse from the resulting  
    low level at interface pin 6.  
    A board without the series capacitor will stay in reset with RTS on,  
    unless RTS is set to off (high level at the interface).
  - added ::cfg(Ser_rts) to accomodate on-off setting of RTS.
  - Hwserial_connect sets RTS-pin and clears it after 250 ms if ::cfg(Ser_rts)  
    is known and has a boolean false value
  - _cfg_ser_ok creates the variable with value 1 if it doesn't exist, so for  
    a toggle its checkbutton needs to be cleared.
- 29-11-2020 v0.3
  - renamed menu_implement_functions to menu_implement
  - section LOG removed, routines moved to section DATA
  - data_init defines Log_app and Log_ena in array cfg to enable log_-routines
  - renamed xmit to Hwserial_transmit for consistency
  - direct set of array app in stead of through LISTapp_defs
  - left mouse click on Fn-key in row has command as in the Fn-key binding
  - _Fn_send now doesn't erase the message entry on empty Fn-key message
  - made _Fn_edit for popup menu on right-click at Fn-key
  - popup menu shows "default settings" as choice and can reset the values of  
    the specific Fn-key to default
  - data_rd now has array name as first parameter to accomodate future expansion  
    into more fragmented data sets and eleminate the need for lower-/upper case  
    to distinguish between the arrays app and cfg
  - File > Open now tries to start logging and enable serial port, if configured
  - prevented changing Alt-F1 and Alt-F4 by mouse-click
- 28-11-2020 v0.2
  - use of "chan subcommand" for stream i/o except for console output
  - array app completed by reading ini file varGUI.ini
  - ini file varGUI.ini used for remembering config file name
  - config file defaults to default.cfg in application folder
  - File submenus "New" or "Save" or "Save as" all use _file_save_app_and_cfg  
    to update varGUI.ini as well as the chosen config file
  - removed filetypes from array app
  - dedicated filetypes in file selectors, override by typing filename
  - added filedo for file manipulation
  - added --- to empty plain Fn row to remove need for brackets in ini file
  - string map in data_rd and data_wr removes need for brackets in cfg file
  - added comment in data_rd
  - changed _file_dir_name to be used for more than just cfg file
  - Config submenu "Logging" and _config_log_btn use _file_dir_name
  - incorporated todo_list in Help > About
  - assembled initialisation into procedures
  - gui_init sets default menu functions with alert boxes
  - menu_implement_functions redefines these for real actions
  - added serial port functions
  - data_wr now skips serial port file handle, default Fn key text and  
    empty Fn key messages in generating data to save as config file
  - added function program_exit to close serial port before exiting
  - menu functions use fully qualified names for cfg and app arrays to  
    prevent needing the keyword global
  - Help > About only resizable in y-direction
  - Edit > Fn keys not resizable
  - Config > Serial not resizable
  - Config > Logging not resizable
  - text entry deleted and focus set to entry after pressing <Return>
  - Added bindings to Fn keys to send if message ends with \n and to  
    edit before sending otherwise
  - added labels at frames around submenu windows
  - quite some minor bug fixes upon testing with devices that have minor  
    differences in serial port signalling
- 26-11-2020 v0.1
  - initial setup of menus and some functionality
