# System Link SignalTap Setup

Quartus 17 can run and export an existing SignalTap file from Tcl, but it does
not provide a reliable command-line path to author a new `.stp` from node names.
Create `system_link_debug.stp` once in the SignalTap GUI, then use the Tcl script
in this folder for repeat captures.

## Setup

1. Open `PSX.qpf` in Quartus.
2. Open `Tools -> SignalTap II Logic Analyzer`.
3. Save the file as `system_link_debug.stp` in the repo root.
4. Set the acquisition clock to the PSX/SIO core clock domain.
5. Add `dbg_syslink_bus[*]`, then use the bit map in
   `signaltap/system_link_debug_nodes.txt`.
6. Set the trigger to `dbg_syslink_bus[32]` rising edge. If that never
   triggers, use `dbg_syslink_bus[39] == 1`.
7. Enable SignalTap and rebuild the single SDRAM `PSX` revision.

## CLI Capture

After JTAG is visible and the SignalTap-enabled SOF/RBF is loaded:

```powershell
quartus_stp -t signaltap\run_system_link_capture.tcl
```

The script exports:

- `signaltap/system_link_capture.vcd`
- `signaltap/system_link_capture.csv`
