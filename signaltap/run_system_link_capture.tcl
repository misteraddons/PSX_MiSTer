set stp_file "system_link_debug.stp"
set instance "auto_signaltap_0"
set signal_set "signal_set_1"
set trigger "trigger_1"
set log_name "system_link_log"
set output_vcd "signaltap/system_link_capture.vcd"
set output_csv "signaltap/system_link_capture.csv"

open_session -name $stp_file
run -instance $instance -signal_set $signal_set -trigger $trigger -data_log $log_name -timeout 30
export_data_log -instance $instance -signal_set $signal_set -trigger $trigger -data_log $log_name -filename $output_vcd -format vcd
export_data_log -instance $instance -signal_set $signal_set -trigger $trigger -data_log $log_name -filename $output_csv -format csv
close_session
