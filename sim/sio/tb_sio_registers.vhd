library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_sio_registers is
end entity;

architecture test of tb_sio_registers is
   signal clk               : std_logic := '0';
   signal ce                : std_logic := '1';
   signal reset             : std_logic := '1';
   signal bus_addr          : unsigned(3 downto 0) := (others => '0');
   signal bus_dataWrite     : std_logic_vector(31 downto 0) := (others => '0');
   signal bus_read          : std_logic := '0';
   signal bus_write         : std_logic := '0';
   signal bus_reqsize       : unsigned(1 downto 0) := (others => '0');
   signal bus_writeMask     : std_logic_vector(3 downto 0) := (others => '0');
   signal bus_dataRead      : std_logic_vector(31 downto 0);
   signal irq               : std_logic;
   signal SS_DataRead       : std_logic_vector(31 downto 0);
   signal snac_txd          : std_logic;
   signal snac_rts          : std_logic;
   signal snac_dtr          : std_logic;
   signal debug_bus         : std_logic_vector(255 downto 0);

   procedure write_reg(
      signal addr  : out unsigned(3 downto 0);
      signal data  : out std_logic_vector(31 downto 0);
      signal mask  : out std_logic_vector(3 downto 0);
      signal wr    : out std_logic;
      constant a   : in  natural;
      constant d   : in  std_logic_vector(31 downto 0);
      constant m   : in  std_logic_vector(3 downto 0)) is
   begin
      addr <= to_unsigned(a, 4);
      data <= d;
      mask <= m;
      wr <= '1';
      wait until rising_edge(clk);
      wr <= '0';
      wait until rising_edge(clk);
   end procedure;

   procedure read_reg(
      signal addr  : out unsigned(3 downto 0);
      signal rd    : out std_logic;
      constant a   : in  natural) is
   begin
      addr <= to_unsigned(a, 4);
      rd <= '1';
      wait until rising_edge(clk);
      wait for 1 ns;
      rd <= '0';
   end procedure;
begin
   clk <= not clk after 5 ns;

   dut : entity work.sio
      port map (
         clk1x => clk, ce => ce, reset => reset,
         bus_addr => bus_addr, bus_dataWrite => bus_dataWrite,
         bus_read => bus_read, bus_write => bus_write,
         bus_reqsize => bus_reqsize, bus_writeMask => bus_writeMask,
         bus_dataRead => bus_dataRead, irq => irq,
         loading_savestate => '0', SS_reset => '0',
         SS_DataWrite => (others => '0'), SS_Adr => (others => '0'),
         SS_wren => '0', SS_rden => '0', SS_DataRead => SS_DataRead,
         snac_txd => snac_txd, snac_rxd => '1',
         snac_rts => snac_rts, snac_cts => '1',
         snac_dtr => snac_dtr, snac_dsr => '1',
         link_assist_mode => "00", debug_bus => debug_bus
      );

   stimulus : process
   begin
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      reset <= '0';
      wait until rising_edge(clk);

      write_reg(bus_addr, bus_dataWrite, bus_writeMask, bus_write, 10, x"00002103", "0011");
      write_reg(bus_addr, bus_dataWrite, bus_writeMask, bus_write, 10, x"00000005", "0001");
      read_reg(bus_addr, bus_read, 10);
      assert bus_dataRead(15 downto 0) = x"2105"
         report "low-byte CTRL write corrupted the untouched high byte" severity failure;
      wait until rising_edge(clk);

      write_reg(bus_addr, bus_dataWrite, bus_writeMask, bus_write, 10, x"00003100", "0010");
      read_reg(bus_addr, bus_read, 10);
      assert bus_dataRead(15 downto 0) = x"3105"
         report "high-byte CTRL write corrupted the untouched low byte" severity failure;
      wait until rising_edge(clk);

      write_reg(bus_addr, bus_dataWrite, bus_writeMask, bus_write, 10, x"00003115", "0011");
      read_reg(bus_addr, bus_read, 10);
      assert bus_dataRead(15 downto 0) = x"3105"
         report "CTRL.ACK did not self-clear" severity failure;

      report "tb_sio_registers PASS" severity note;
      wait;
   end process;
end architecture;
