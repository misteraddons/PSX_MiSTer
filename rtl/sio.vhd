library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sio is
   port
   (
      clk1x                : in  std_logic;
      ce                   : in  std_logic;
      reset                : in  std_logic;

      bus_addr             : in  unsigned(3 downto 0);
      bus_dataWrite        : in  std_logic_vector(31 downto 0);
      bus_read             : in  std_logic;
      bus_write            : in  std_logic;
      bus_reqsize          : in  unsigned(1 downto 0);
      bus_writeMask        : in  std_logic_vector(3 downto 0);
      bus_dataRead         : out std_logic_vector(31 downto 0);
      irq                  : out std_logic;

      loading_savestate    : in  std_logic;
      SS_reset             : in  std_logic;
      SS_DataWrite         : in  std_logic_vector(31 downto 0);
      SS_Adr               : in  unsigned(2 downto 0);
      SS_wren              : in  std_logic;
      SS_rden              : in  std_logic;
      SS_DataRead          : out std_logic_vector(31 downto 0);

      snac_txd             : out std_logic;
      snac_rxd             : in  std_logic;
      snac_rts             : out std_logic;
      snac_cts             : in  std_logic;
      snac_dtr             : out std_logic;
      snac_dsr             : in  std_logic;
      link_assist_mode     : in  std_logic_vector(1 downto 0);
      debug_bus            : out std_logic_vector(255 downto 0)
   );
end entity;

architecture arch of sio is

   constant SIO_STAT_RESET : std_logic_vector(31 downto 0) := x"00000185";
   constant SIO_BAUD_RESET : unsigned(15 downto 0) := x"0000";

   subtype t_baud_counter is unsigned(23 downto 0);
   type t_rx_fifo is array(0 to 7) of std_logic_vector(7 downto 0);

   signal SIO_DATA         : std_logic_vector(7 downto 0) := (others => '0');
   signal SIO_STAT         : std_logic_vector(31 downto 0) := SIO_STAT_RESET;
   signal SIO_MODE         : std_logic_vector(15 downto 0) := (others => '0');
   signal SIO_CTRL         : std_logic_vector(15 downto 0) := (others => '0');
   signal SIO_MISC         : std_logic_vector(15 downto 0) := (others => '0');
   signal SIO_BAUD         : unsigned(15 downto 0) := SIO_BAUD_RESET;
   signal SIO_STAT_READ    : std_logic_vector(31 downto 0);

   signal tx_shift         : std_logic_vector(9 downto 0) := (others => '1');
   signal tx_busy          : std_logic := '0';
   signal tx_pending       : std_logic := '0';
   signal tx_start_seen    : std_logic := '0';
   signal tx_pending_data  : std_logic_vector(7 downto 0) := (others => '0');
   signal tx_pending_txen  : std_logic := '0';
   signal tx_bit_cnt       : unsigned(3 downto 0) := (others => '0');
   signal tx_div           : t_baud_counter := (others => '0');
   signal tx_line          : std_logic := '1';

   signal rx_shift         : std_logic_vector(7 downto 0) := (others => '0');
   signal rx_busy          : std_logic := '0';
   signal rx_bit_cnt       : unsigned(3 downto 0) := (others => '0');
   signal rx_div           : t_baud_counter := (others => '0');
   signal rx_data          : std_logic_vector(7 downto 0) := (others => '0');
   signal rx_fifo          : t_rx_fifo := (others => (others => '0'));
   signal rx_rd_ptr        : unsigned(2 downto 0) := (others => '0');
   signal rx_wr_ptr        : unsigned(2 downto 0) := (others => '0');
   signal rx_count         : unsigned(3 downto 0) := (others => '0');
   signal rx_sync          : std_logic_vector(2 downto 0) := (others => '1');
   signal rx_idle_count    : t_baud_counter := (others => '0');
   signal rx_idle_qualified : std_logic := '0';

   signal irq_pending      : std_logic := '0';
   signal tx_ready         : std_logic;
   signal tx_idle          : std_logic;
   signal link_ready       : std_logic;
   signal rx_ready         : std_logic;
   signal debug_read_value : std_logic_vector(31 downto 0);
   signal debug_stat_raw   : std_logic_vector(31 downto 0);
   signal rx_edge_count    : unsigned(7 downto 0) := (others => '0');
   signal rx_start_count   : unsigned(7 downto 0) := (others => '0');
   signal rx_done_count    : unsigned(7 downto 0) := (others => '0');
   signal rx_frame_count   : unsigned(7 downto 0) := (others => '0');
   signal debug_data_write : std_logic := '0';
   signal debug_tx_latched : std_logic := '0';
   signal effective_cts    : std_logic;
   signal effective_dsr    : std_logic;
   signal status_link_ready : std_logic;
   signal assist_configured : std_logic;
   signal assist_edge_active : std_logic;
   signal assist_state     : unsigned(1 downto 0) := (others => '0');
   signal assist_count     : unsigned(15 downto 0) := (others => '0');
   signal assist_prev_mode : std_logic_vector(1 downto 0) := (others => '0');
   signal bus_read_seen    : std_logic := '0';
   signal bus_write_seen   : std_logic := '0';
   signal bus_addr_seen    : unsigned(3 downto 0) := (others => '0');
   signal bus_reqsize_seen : unsigned(1 downto 0) := (others => '0');
   signal bus_data_seen    : std_logic_vector(31 downto 0) := (others => '0');
   signal bus_mask_seen    : std_logic_vector(3 downto 0) := (others => '0');

   constant ASSIST_DELAY_RELOAD : unsigned(15 downto 0) := x"7FFF";
   constant ASSIST_EDGE_RELOAD  : unsigned(15 downto 0) := x"07FF";

   type t_ssarray is array(0 to 7) of std_logic_vector(31 downto 0);
   signal ss_out           : t_ssarray := (others => (others => '0'));

   function baud_reload(baud : unsigned(15 downto 0); mode : std_logic_vector(1 downto 0)) return t_baud_counter is
      variable factor : t_baud_counter;
      variable cycles : t_baud_counter;
   begin
      case mode is
         when "00" =>
            return (others => '0');
         when "01" =>
            factor := to_unsigned(1, 24);
            cycles := resize(baud, 24);
         when "10" =>
            factor := to_unsigned(16, 24);
            cycles := shift_left(resize(baud, 24), 4);
         when "11" =>
            factor := to_unsigned(64, 24);
            cycles := shift_left(resize(baud, 24), 6);
         when others =>
            return (others => '0');
      end case;

      cycles(0) := '0';
      if cycles < factor then
         return factor;
      end if;

      return cycles;
   end function;

   function sio1_baud_running(mode : std_logic_vector(1 downto 0)) return std_logic is
   begin
      if mode = "00" then
         return '0';
      end if;
      return '1';
   end function;

   function sio_low16_write_value(current : std_logic_vector(15 downto 0);
                                  data    : std_logic_vector(31 downto 0);
                                  mask    : std_logic_vector(3 downto 0)) return std_logic_vector is
   begin
      if mask(1 downto 0) = "11" then
         return data(15 downto 0);
      elsif mask(0) = '1' then
         return x"00" & data(7 downto 0);
      elsif mask(1) = '1' then
         return data(15 downto 8) & x"00";
      end if;

      return current;
   end function;

   function sio_high16_write_value(current : std_logic_vector(15 downto 0);
                                   data    : std_logic_vector(31 downto 0);
                                   mask    : std_logic_vector(3 downto 0)) return std_logic_vector is
   begin
      if mask(3 downto 2) = "11" then
         return data(31 downto 16);
      elsif mask(2) = '1' then
         return x"00" & data(23 downto 16);
      elsif mask(3) = '1' then
         return data(31 downto 24) & x"00";
      end if;

      return current;
   end function;

   function half_baud_reload(baud : unsigned(15 downto 0); mode : std_logic_vector(1 downto 0)) return t_baud_counter is
      variable full : t_baud_counter;
   begin
      full := baud_reload(baud, mode);
      if full < 2 then
         return to_unsigned(1, 24);
      end if;
      return '0' & full(23 downto 1);
   end function;

   function first_rx_sample_reload(baud : unsigned(15 downto 0); mode : std_logic_vector(1 downto 0)) return t_baud_counter is
      variable sum : unsigned(24 downto 0);
   begin
      sum := resize(baud_reload(baud, mode), 25) + resize(half_baud_reload(baud, mode), 25);
      if sum(24) = '1' then
         return (others => '1');
      end if;
      return sum(23 downto 0);
   end function;

   function tx_bit_count(mode : std_logic_vector(15 downto 0)) return unsigned is
   begin
      if mode(7 downto 6) = "11" then
         return to_unsigned(11, 4); -- 8 data bits + 2 stop bits, plus completion slot after the explicit start bit.
      end if;
      return to_unsigned(10, 4); -- 8 data bits + 1 stop bit, plus completion slot after the explicit start bit.
   end function;

   function rx_irq_threshold(ctrl : std_logic_vector(15 downto 0)) return unsigned is
   begin
      case ctrl(9 downto 8) is
         when "00" => return to_unsigned(1, 4);
         when "01" => return to_unsigned(2, 4);
         when "10" => return to_unsigned(4, 4);
         when others => return to_unsigned(8, 4);
      end case;
   end function;

   function rx_irq_active(count : unsigned(3 downto 0); ctrl : std_logic_vector(15 downto 0)) return std_logic is
   begin
      if ctrl(11) = '1' and count >= rx_irq_threshold(ctrl) then
         return '1';
      end if;
      return '0';
   end function;

   function rx_read_word(fifo : t_rx_fifo; rd_ptr : unsigned(2 downto 0); count : unsigned(3 downto 0); last_data : std_logic_vector(7 downto 0)) return std_logic_vector is
      variable result : std_logic_vector(31 downto 0);
      variable ptr1   : unsigned(2 downto 0);
      variable ptr2   : unsigned(2 downto 0);
      variable ptr3   : unsigned(2 downto 0);
   begin
      result := (others => '0');
      ptr1 := rd_ptr + 1;
      ptr2 := rd_ptr + 2;
      ptr3 := rd_ptr + 3;

      if count = 0 then
         result(7 downto 0) := last_data;
      else
         result(7 downto 0) := fifo(to_integer(rd_ptr));
         if count > 1 then
            result(15 downto 8) := fifo(to_integer(ptr1));
         end if;
         if count > 2 then
            result(23 downto 16) := fifo(to_integer(ptr2));
         end if;
         if count > 3 then
            result(31 downto 24) := fifo(to_integer(ptr3));
         end if;
      end if;

      return result;
   end function;

   function rx_pop_count(reqsize : unsigned(1 downto 0); count : unsigned(3 downto 0)) return unsigned is
      variable wanted : unsigned(3 downto 0);
   begin
      case reqsize is
         when "10" =>
            wanted := to_unsigned(4, 4);
         when others =>
            wanted := to_unsigned(1, 4);
      end case;

      if count < wanted then
         return count;
      end if;
      return wanted;
   end function;

begin

   snac_txd <= tx_line;
   snac_rts <= SIO_CTRL(5);
   snac_dtr <= SIO_CTRL(1);
   irq <= irq_pending;

   rx_ready <= '1' when rx_count /= 0 else '0';
   assist_configured <= SIO_CTRL(1) and SIO_CTRL(2);
   assist_edge_active <= '1' when link_assist_mode = "11" and assist_state = "10" else '0';
   effective_cts <= snac_cts when link_assist_mode = "00" or assist_configured = '0' else
                    snac_cts when assist_state = "11" else
                    '1' when link_assist_mode = "11" and assist_state = "10" else
                    '0';
   effective_dsr <= snac_dsr when link_assist_mode = "00" or assist_configured = '0' else
                    snac_dsr when assist_state = "11" else
                    '1' when link_assist_mode = "11" and assist_state = "10" else
                    '0';
   status_link_ready <= effective_cts or effective_dsr;
   link_ready <= status_link_ready;
   tx_ready <= tx_start_seen and (not tx_pending) and effective_cts;
   tx_idle  <= (not tx_busy) and (not tx_pending) and effective_cts;

   SIO_STAT_READ <= SIO_STAT(31 downto 10) & irq_pending & status_link_ready & effective_dsr &
                    SIO_STAT(6 downto 3) & tx_idle & rx_ready & tx_ready;

   debug_read_value <= rx_read_word(rx_fifo, rx_rd_ptr, rx_count, rx_data) when (bus_addr(3 downto 1) & '0') = x"0" else
                       SIO_STAT_READ when (bus_addr(3 downto 1) & '0') = x"4" else
                       SIO_CTRL & SIO_MODE when (bus_addr(3 downto 1) & '0') = x"8" else
                       x"0000" & SIO_CTRL when (bus_addr(3 downto 1) & '0') = x"A" else
                       std_logic_vector(SIO_BAUD) & SIO_MISC when (bus_addr(3 downto 1) & '0') = x"C" else
                       x"0000" & std_logic_vector(SIO_BAUD) when (bus_addr(3 downto 1) & '0') = x"E" else
                       (others => '1');

   debug_stat_raw <= std_logic_vector(rx_frame_count) & std_logic_vector(rx_done_count) &
                     std_logic_vector(rx_start_count) & std_logic_vector(rx_edge_count);

   debug_bus <= x"00" & link_assist_mode & assist_configured & std_logic_vector(assist_state) &
                effective_cts & effective_dsr & assist_edge_active & x"00" &
                std_logic_vector(rx_count) & tx_start_seen & link_ready &
                debug_tx_latched & debug_data_write &
                x"00" & SIO_DATA & debug_stat_raw & debug_read_value &
                bus_writeMask & bus_dataWrite & std_logic_vector(SIO_BAUD) &
                SIO_MODE & SIO_CTRL & SIO_STAT_READ & rx_data &
                bus_dataWrite(7 downto 0) & std_logic_vector(bus_addr) &
                bus_write & bus_read & snac_rxd & tx_line & irq_pending &
                rx_ready & rx_busy & tx_busy;

   ss_out(0)(7 downto 0)   <= SIO_DATA;
   ss_out(1)               <= SIO_STAT_READ;
   ss_out(2)(15 downto 0)  <= SIO_MODE;
   ss_out(3)(15 downto 0)  <= SIO_CTRL;
   ss_out(4)(15 downto 0)  <= std_logic_vector(SIO_BAUD);
   ss_out(5)(7 downto 0)   <= rx_data;
   ss_out(5)(11 downto 8)  <= std_logic_vector(rx_count);
   ss_out(6)(0)            <= tx_busy;
   ss_out(6)(1)            <= rx_busy;
   ss_out(6)(2)            <= rx_ready;
   ss_out(6)(3)            <= irq_pending;
   ss_out(6)(4)            <= tx_pending;
   ss_out(6)(5)            <= tx_start_seen;

   process (clk1x)
   begin
      if rising_edge(clk1x) then
         if (reset = '1' and loading_savestate = '0') then
            assist_state <= (others => '0');
            assist_count <= (others => '0');
            assist_prev_mode <= (others => '0');
         elsif (ce = '1') then
            assist_prev_mode <= link_assist_mode;
            if link_assist_mode = "00" or assist_configured = '0' or link_assist_mode /= assist_prev_mode then
               assist_state <= (others => '0');
               assist_count <= (others => '0');
            elsif link_assist_mode = "01" then
               assist_state <= "11";
               assist_count <= (others => '0');
            else
               case assist_state is
                  when "00" =>
                     assist_state <= "01";
                     assist_count <= ASSIST_DELAY_RELOAD;
                  when "01" =>
                     if assist_count = 0 then
                        if link_assist_mode = "11" then
                           assist_state <= "10";
                           assist_count <= ASSIST_EDGE_RELOAD;
                        else
                           assist_state <= "11";
                           assist_count <= (others => '0');
                        end if;
                     else
                        assist_count <= assist_count - 1;
                     end if;
                  when "10" =>
                     if assist_count = 0 then
                        assist_state <= "11";
                     else
                        assist_count <= assist_count - 1;
                     end if;
                  when others =>
                     assist_state <= "11";
                     assist_count <= (others => '0');
               end case;
            end if;
         end if;
      end if;
   end process;

   process (clk1x)
      variable data_v              : std_logic_vector(7 downto 0);
      variable stat_v              : std_logic_vector(31 downto 0);
      variable mode_v              : std_logic_vector(15 downto 0);
      variable ctrl_v              : std_logic_vector(15 downto 0);
      variable misc_v              : std_logic_vector(15 downto 0);
      variable baud_v              : unsigned(15 downto 0);
      variable irq_v               : std_logic;
      variable tx_shift_v          : std_logic_vector(9 downto 0);
      variable tx_busy_v           : std_logic;
      variable tx_pending_v        : std_logic;
      variable tx_start_seen_v     : std_logic;
      variable tx_pending_data_v   : std_logic_vector(7 downto 0);
      variable tx_pending_txen_v   : std_logic;
      variable tx_bit_cnt_v        : unsigned(3 downto 0);
      variable tx_div_v            : t_baud_counter;
      variable tx_line_v           : std_logic;
      variable rx_shift_v          : std_logic_vector(7 downto 0);
      variable rx_busy_v           : std_logic;
      variable rx_bit_cnt_v        : unsigned(3 downto 0);
      variable rx_div_v            : t_baud_counter;
      variable rx_data_v           : std_logic_vector(7 downto 0);
      variable rx_fifo_v           : t_rx_fifo;
      variable rx_rd_ptr_v         : unsigned(2 downto 0);
      variable rx_wr_ptr_v         : unsigned(2 downto 0);
      variable rx_count_v          : unsigned(3 downto 0);
      variable rx_last_ptr_v       : unsigned(2 downto 0);
      variable rx_pop_v            : unsigned(3 downto 0);
      variable rx_idle_count_v     : t_baud_counter;
      variable rx_idle_qualified_v : std_logic;
      variable ctrl_write_v        : std_logic;
      variable tx_start_v          : std_logic;
      variable irq_rearm_block_v   : std_logic;
      variable read_word_v         : std_logic_vector(31 downto 0);
      variable status_read_v       : std_logic_vector(31 downto 0);
      variable rx_ready_v          : std_logic;
      variable bus_read_access_v   : std_logic;
      variable bus_write_access_v  : std_logic;
   begin
      if rising_edge(clk1x) then
         if (reset = '1' and loading_savestate = '0') then
            SIO_DATA       <= (others => '0');
            SIO_STAT       <= SIO_STAT_RESET;
            SIO_MODE       <= (others => '0');
            SIO_CTRL       <= (others => '0');
            SIO_MISC       <= (others => '0');
            SIO_BAUD       <= SIO_BAUD_RESET;
            tx_shift       <= (others => '1');
            tx_busy        <= '0';
            tx_pending     <= '0';
            tx_start_seen  <= '1';
            tx_pending_data <= (others => '0');
            tx_pending_txen <= '0';
            tx_bit_cnt     <= (others => '0');
            tx_div         <= (others => '0');
            tx_line        <= '1';
            rx_shift       <= (others => '0');
            rx_busy        <= '0';
            rx_bit_cnt     <= (others => '0');
            rx_div         <= (others => '0');
            rx_data        <= (others => '0');
            rx_fifo        <= (others => (others => '0'));
            rx_rd_ptr      <= (others => '0');
            rx_wr_ptr      <= (others => '0');
            rx_count       <= (others => '0');
            rx_sync        <= (others => '1');
            rx_idle_count  <= (others => '0');
            rx_idle_qualified <= '0';
            irq_pending    <= '0';
            rx_edge_count  <= (others => '0');
            rx_start_count <= (others => '0');
            rx_done_count  <= (others => '0');
            rx_frame_count <= (others => '0');
            debug_data_write <= '0';
            debug_tx_latched <= '0';
            bus_read_seen <= '0';
            bus_write_seen <= '0';
            bus_addr_seen <= (others => '0');
            bus_reqsize_seen <= (others => '0');
            bus_data_seen <= (others => '0');
            bus_mask_seen <= (others => '0');
         elsif (SS_wren = '1') then
            case to_integer(SS_Adr) is
               when 0 => SIO_DATA <= SS_DataWrite(7 downto 0);
               when 1 => SIO_STAT <= SS_DataWrite;
               when 2 => SIO_MODE <= SS_DataWrite(15 downto 0);
               when 3 => SIO_CTRL <= SS_DataWrite(15 downto 0);
               when 4 => SIO_BAUD <= unsigned(SS_DataWrite(15 downto 0));
               when 5 =>
                  rx_data <= SS_DataWrite(7 downto 0);
                  rx_fifo <= (others => (others => '0'));
                  rx_fifo(0) <= SS_DataWrite(7 downto 0);
                  rx_rd_ptr <= (others => '0');
                  if SS_DataWrite(11 downto 8) = x"0" then
                     rx_wr_ptr <= (others => '0');
                     rx_count <= (others => '0');
                  else
                     rx_wr_ptr <= to_unsigned(1, 3);
                     rx_count <= to_unsigned(1, 4);
                  end if;
               when 6 =>
                  tx_busy <= SS_DataWrite(0);
                  rx_busy <= SS_DataWrite(1);
                  irq_pending <= SS_DataWrite(3);
                  tx_pending <= SS_DataWrite(4);
                  tx_start_seen <= SS_DataWrite(5);
               when others => null;
            end case;
            bus_read_seen <= '0';
            bus_write_seen <= '0';
         elsif (ce = '1') then
            data_v := SIO_DATA;
            stat_v := SIO_STAT;
            mode_v := SIO_MODE;
            ctrl_v := SIO_CTRL;
            misc_v := SIO_MISC;
            baud_v := SIO_BAUD;
            irq_v := irq_pending;
            tx_shift_v := tx_shift;
            tx_busy_v := tx_busy;
            tx_pending_v := tx_pending;
            tx_start_seen_v := tx_start_seen;
            tx_pending_data_v := tx_pending_data;
            tx_pending_txen_v := tx_pending_txen;
            tx_bit_cnt_v := tx_bit_cnt;
            tx_div_v := tx_div;
            tx_line_v := tx_line;
            rx_shift_v := rx_shift;
            rx_busy_v := rx_busy;
            rx_bit_cnt_v := rx_bit_cnt;
            rx_div_v := rx_div;
            rx_data_v := rx_data;
            rx_fifo_v := rx_fifo;
            rx_rd_ptr_v := rx_rd_ptr;
            rx_wr_ptr_v := rx_wr_ptr;
            rx_count_v := rx_count;
            rx_idle_count_v := rx_idle_count;
            rx_idle_qualified_v := rx_idle_qualified;
            ctrl_write_v := '0';
            tx_start_v := '0';
            irq_rearm_block_v := '0';
            debug_data_write <= '0';
            bus_read_access_v := '0';
            bus_write_access_v := '0';

            if bus_read = '1' and
               (bus_read_seen = '0' or bus_addr /= bus_addr_seen or bus_reqsize /= bus_reqsize_seen) then
               bus_read_access_v := '1';
            end if;

            if bus_write = '1' and
               (bus_write_seen = '0' or bus_addr /= bus_addr_seen or bus_reqsize /= bus_reqsize_seen or
                bus_dataWrite /= bus_data_seen or bus_writeMask /= bus_mask_seen) then
               bus_write_access_v := '1';
            end if;

            bus_dataRead <= (others => '0');
            rx_sync <= rx_sync(1 downto 0) & snac_rxd;

            if (bus_read = '1') then
               case (bus_addr(3 downto 1) & '0') is
                   when x"0" =>
                      read_word_v := rx_read_word(rx_fifo_v, rx_rd_ptr_v, rx_count_v, rx_data_v);
                      bus_dataRead <= read_word_v;
                      if rx_count_v /= 0 and bus_read_access_v = '1' then
                         rx_data_v := rx_fifo_v(to_integer(rx_rd_ptr_v));
                         rx_pop_v := rx_pop_count(bus_reqsize, rx_count_v);
                         rx_rd_ptr_v := rx_rd_ptr_v + resize(rx_pop_v(2 downto 0), 3);
                        rx_count_v := rx_count_v - rx_pop_v;
                     end if;
                  when x"4" =>
                     if rx_count_v = 0 then
                        rx_ready_v := '0';
                     else
                        rx_ready_v := '1';
                     end if;
                     status_read_v := stat_v(31 downto 10) & irq_v & status_link_ready & effective_dsr &
                                      stat_v(6 downto 3) &
                                      ((not tx_busy_v) and (not tx_pending_v) and effective_cts) &
                                      rx_ready_v &
                                      (tx_start_seen_v and (not tx_pending_v) and effective_cts);
                     bus_dataRead <= status_read_v;
                  when x"8" =>
                     bus_dataRead <= ctrl_v & mode_v;
                  when x"A" =>
                     bus_dataRead <= x"0000" & ctrl_v;
                  when x"C" =>
                     bus_dataRead <= std_logic_vector(baud_v) & misc_v;
                  when x"E" =>
                     bus_dataRead <= x"0000" & std_logic_vector(baud_v);
                  when others =>
                     bus_dataRead <= (others => '1');
               end case;
            end if;

            if (bus_write_access_v = '1') then
               case (bus_addr(3 downto 0)) is
                  when x"0" =>
                     if (bus_writeMask(0) = '1') then
                        data_v := bus_dataWrite(7 downto 0);
                        tx_pending_data_v := bus_dataWrite(7 downto 0);
                        tx_pending_txen_v := ctrl_v(0);
                        tx_start_seen_v := '0';
                        debug_data_write <= '1';
                        debug_tx_latched <= ctrl_v(0);
                        if tx_busy_v = '0' and effective_cts = '1' and ctrl_v(0) = '1' and sio1_baud_running(mode_v(1 downto 0)) = '1' then
                           tx_shift_v := "11" & bus_dataWrite(7 downto 0);
                           tx_busy_v := '1';
                           tx_pending_v := '0';
                           tx_line_v := '0';
                           tx_bit_cnt_v := tx_bit_count(mode_v);
                           tx_div_v := baud_reload(baud_v, mode_v(1 downto 0));
                           tx_start_v := '1';
                        else
                           tx_pending_v := '1';
                        end if;
                     end if;
                  when x"8" =>
                     if (bus_writeMask(1 downto 0) /= "00") then
                        mode_v := sio_low16_write_value(mode_v, bus_dataWrite, bus_writeMask);
                     end if;
                     if (bus_writeMask(3 downto 2) /= "00") then
                        ctrl_v := sio_high16_write_value(ctrl_v, bus_dataWrite, bus_writeMask);
                        ctrl_write_v := '1';
                     end if;
                  when x"A" =>
                     if (bus_writeMask(3 downto 2) /= "00") then
                        ctrl_v := sio_high16_write_value(ctrl_v, bus_dataWrite, bus_writeMask);
                        ctrl_write_v := '1';
                     elsif (bus_writeMask(1 downto 0) /= "00") then
                        ctrl_v := sio_low16_write_value(ctrl_v, bus_dataWrite, bus_writeMask);
                        ctrl_write_v := '1';
                     end if;
                  when x"C" =>
                     if (bus_writeMask(1 downto 0) /= "00") then
                        misc_v := sio_low16_write_value(misc_v, bus_dataWrite, bus_writeMask);
                     end if;
                     if (bus_writeMask(3 downto 2) /= "00") then
                        baud_v := unsigned(sio_high16_write_value(std_logic_vector(baud_v), bus_dataWrite, bus_writeMask));
                     end if;
                  when x"E" =>
                     if (bus_writeMask(3 downto 2) /= "00") then
                        baud_v := unsigned(sio_high16_write_value(std_logic_vector(baud_v), bus_dataWrite, bus_writeMask));
                     elsif (bus_writeMask(1 downto 0) /= "00") then
                        baud_v := unsigned(sio_low16_write_value(std_logic_vector(baud_v), bus_dataWrite, bus_writeMask));
                     end if;
                  when others => null;
               end case;
            end if;

            if ctrl_write_v = '1' then
               if ctrl_v(4) = '1' then
                  stat_v(5 downto 3) := (others => '0');
                  irq_v := '0';
                  irq_rearm_block_v := '1';
               end if;

               if ctrl_v(6) = '1' then
                  data_v := (others => '0');
                  stat_v := SIO_STAT_RESET;
                  mode_v := (others => '0');
                  ctrl_v := (others => '0');
                  misc_v := (others => '0');
                  baud_v := SIO_BAUD_RESET;
                  tx_shift_v := (others => '1');
                  tx_busy_v := '0';
                  tx_start_seen_v := '1';
                  tx_pending_v := '0';
                  tx_pending_data_v := (others => '0');
                  tx_pending_txen_v := '0';
                  tx_bit_cnt_v := (others => '0');
                  tx_div_v := (others => '0');
                  tx_line_v := '1';
                  rx_shift_v := (others => '0');
                  rx_busy_v := '0';
                  rx_bit_cnt_v := (others => '0');
                  rx_div_v := (others => '0');
                  rx_data_v := (others => '0');
                  rx_fifo_v := (others => (others => '0'));
                  rx_rd_ptr_v := (others => '0');
                  rx_wr_ptr_v := (others => '0');
                  rx_count_v := (others => '0');
                  rx_idle_count_v := (others => '0');
                  rx_idle_qualified_v := '0';
                  irq_v := '0';
                  rx_edge_count <= (others => '0');
                  rx_start_count <= (others => '0');
                  rx_done_count <= (others => '0');
                  rx_frame_count <= (others => '0');
                  debug_tx_latched <= '0';
               else
                  if ctrl_v(2) = '0' then
                      rx_fifo_v := (others => (others => '0'));
                      rx_rd_ptr_v := (others => '0');
                      rx_wr_ptr_v := (others => '0');
                      rx_count_v := (others => '0');
                      rx_busy_v := '0';
                      rx_idle_count_v := (others => '0');
                      rx_idle_qualified_v := '0';
                  end if;
                  ctrl_v(4) := '0';
                  ctrl_v(6) := '0';
               end if;
            end if;

            if tx_busy_v = '0' and tx_pending_v = '1' and effective_cts = '1' and (ctrl_v(0) = '1' or tx_pending_txen_v = '1') and sio1_baud_running(mode_v(1 downto 0)) = '1' then
               data_v := tx_pending_data_v;
               tx_shift_v := "11" & tx_pending_data_v;
               tx_busy_v := '1';
               tx_pending_v := '0';
               tx_line_v := '0';
               tx_bit_cnt_v := tx_bit_count(mode_v);
               tx_div_v := baud_reload(baud_v, mode_v(1 downto 0));
               tx_start_v := '1';
            end if;

            if tx_busy_v = '1' and tx_start_v = '0' then
               if tx_div_v = 0 then
                  tx_start_seen_v := '1';
                  tx_line_v := tx_shift_v(0);
                  tx_shift_v := '1' & tx_shift_v(9 downto 1);
                  tx_div_v := baud_reload(baud_v, mode_v(1 downto 0));
                  if tx_bit_cnt_v = 1 then
                     if tx_pending_v = '1' and effective_cts = '1' and (ctrl_v(0) = '1' or tx_pending_txen_v = '1') and sio1_baud_running(mode_v(1 downto 0)) = '1' then
                        data_v := tx_pending_data_v;
                        tx_shift_v := "11" & tx_pending_data_v;
                        tx_busy_v := '1';
                        tx_pending_v := '0';
                        tx_line_v := '0';
                        tx_bit_cnt_v := tx_bit_count(mode_v);
                        tx_div_v := baud_reload(baud_v, mode_v(1 downto 0));
                     else
                        tx_busy_v := '0';
                        tx_bit_cnt_v := (others => '0');
                        tx_line_v := '1';
                     end if;

                     if irq_rearm_block_v = '0' and ctrl_v(10) = '1' and tx_pending_v = '0' and effective_cts = '1' then
                        irq_v := '1';
                     end if;
                  else
                     tx_bit_cnt_v := tx_bit_cnt_v - 1;
                  end if;
               else
                  tx_div_v := tx_div_v - 1;
               end if;
            elsif tx_start_v = '0' and tx_busy_v = '0' then
               tx_line_v := '1';
            end if;

            if ctrl_v(2) = '0' then
               rx_fifo_v := (others => (others => '0'));
               rx_rd_ptr_v := (others => '0');
               rx_wr_ptr_v := (others => '0');
               rx_count_v := (others => '0');
               rx_busy_v := '0';
               rx_idle_count_v := (others => '0');
               rx_idle_qualified_v := '0';
            elsif sio1_baud_running(mode_v(1 downto 0)) = '0' then
               rx_busy_v := '0';
               rx_idle_count_v := (others => '0');
               rx_idle_qualified_v := '0';
            elsif rx_busy_v = '0' then
               if rx_sync(2 downto 1) = "10" then
                  rx_edge_count <= rx_edge_count + 1;
                  if rx_idle_qualified_v = '1' then
                     rx_busy_v := '1';
                     rx_start_count <= rx_start_count + 1;
                     rx_bit_cnt_v := (others => '0');
                     rx_div_v := first_rx_sample_reload(baud_v, mode_v(1 downto 0));
                  end if;
                  rx_idle_count_v := (others => '0');
                  rx_idle_qualified_v := '0';
               elsif rx_sync(2) = '1' then
                  if rx_idle_count_v >= half_baud_reload(baud_v, mode_v(1 downto 0)) then
                     rx_idle_qualified_v := '1';
                  else
                     rx_idle_count_v := rx_idle_count_v + 1;
                  end if;
               else
                  rx_idle_count_v := (others => '0');
                  rx_idle_qualified_v := '0';
               end if;
            else
               if rx_div_v = 0 then
                  rx_div_v := baud_reload(baud_v, mode_v(1 downto 0));
                  if rx_bit_cnt_v < 8 then
                     rx_shift_v := rx_sync(2) & rx_shift_v(7 downto 1);
                     rx_bit_cnt_v := rx_bit_cnt_v + 1;
                  else
                     rx_busy_v := '0';
                     rx_data_v := rx_shift_v;
                     stat_v(6) := rx_sync(2);
                     if rx_sync(2) = '0' then
                        stat_v(5) := '1';
                        rx_frame_count <= rx_frame_count + 1;
                     elsif rx_count_v = 8 then
                        rx_idle_qualified_v := '1';
                        rx_last_ptr_v := rx_wr_ptr_v - 1;
                        rx_fifo_v(to_integer(rx_last_ptr_v)) := rx_shift_v;
                        stat_v(4) := '1';
                     else
                        rx_idle_qualified_v := '1';
                        rx_fifo_v(to_integer(rx_wr_ptr_v)) := rx_shift_v;
                        rx_wr_ptr_v := rx_wr_ptr_v + 1;
                        rx_count_v := rx_count_v + 1;
                        rx_done_count <= rx_done_count + 1;
                     end if;
                  end if;
               else
                  rx_div_v := rx_div_v - 1;
               end if;
            end if;

            if irq_rearm_block_v = '0' then
               if rx_irq_active(rx_count_v, ctrl_v) = '1' then
                  irq_v := '1';
               end if;

               if ctrl_v(10) = '1' and tx_start_seen_v = '1' and tx_pending_v = '0' and effective_cts = '1' then
                  irq_v := '1';
               end if;

               if ctrl_v(12) = '1' and effective_dsr = '1' then
                  irq_v := '1';
               end if;
            end if;

            SIO_DATA <= data_v;
            SIO_STAT <= stat_v;
            SIO_MODE <= mode_v;
            SIO_CTRL <= ctrl_v;
            SIO_MISC <= misc_v;
            SIO_BAUD <= baud_v;
            irq_pending <= irq_v;
            tx_shift <= tx_shift_v;
            tx_busy <= tx_busy_v;
            tx_pending <= tx_pending_v;
            tx_start_seen <= tx_start_seen_v;
            tx_pending_data <= tx_pending_data_v;
            tx_pending_txen <= tx_pending_txen_v;
            tx_bit_cnt <= tx_bit_cnt_v;
            tx_div <= tx_div_v;
            tx_line <= tx_line_v;
            rx_shift <= rx_shift_v;
            rx_busy <= rx_busy_v;
            rx_bit_cnt <= rx_bit_cnt_v;
            rx_div <= rx_div_v;
            rx_data <= rx_data_v;
            rx_fifo <= rx_fifo_v;
            rx_rd_ptr <= rx_rd_ptr_v;
            rx_wr_ptr <= rx_wr_ptr_v;
            rx_count <= rx_count_v;
            rx_idle_count <= rx_idle_count_v;
            rx_idle_qualified <= rx_idle_qualified_v;
            if bus_read = '1' then
               bus_read_seen <= '1';
               bus_addr_seen <= bus_addr;
               bus_reqsize_seen <= bus_reqsize;
            else
               bus_read_seen <= '0';
            end if;
            if bus_write = '1' then
               bus_write_seen <= '1';
               bus_addr_seen <= bus_addr;
               bus_reqsize_seen <= bus_reqsize;
               bus_data_seen <= bus_dataWrite;
               bus_mask_seen <= bus_writeMask;
            else
               bus_write_seen <= '0';
            end if;
          else
            if bus_read = '0' then
               bus_read_seen <= '0';
            end if;
            if bus_write = '0' then
               bus_write_seen <= '0';
            end if;
          end if;
       end if;
    end process;

   process (clk1x)
   begin
      if rising_edge(clk1x) then
         if (SS_rden = '1') then
            SS_DataRead <= ss_out(to_integer(SS_Adr));
         end if;
      end if;
   end process;

end architecture;
