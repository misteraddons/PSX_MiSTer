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
      bus_writeMask        : in  std_logic_vector(3 downto 0);
      bus_dataRead         : out std_logic_vector(31 downto 0);
      
      loading_savestate    : in  std_logic;
      SS_reset             : in  std_logic;
      SS_DataWrite         : in  std_logic_vector(31 downto 0);
      SS_Adr               : in  unsigned(2 downto 0);
      SS_wren              : in  std_logic;
      SS_rden              : in  std_logic;
      SS_DataRead          : out std_logic_vector(31 downto 0);
      
      -- SNAC interface (shared between SIO0 and SIO1)
      snac_txd             : out std_logic;
      snac_rxd             : in  std_logic;
      snac_rts             : out std_logic;
      snac_cts             : in  std_logic;
      snac_dtr             : out std_logic;
      snac_dsr             : in  std_logic
   );
end entity;

architecture arch of sio is

   -- SIO1 registers (system link) 
   signal SIO1_TX_DATA : std_logic_vector(31 downto 0);
   signal SIO1_RX_DATA : std_logic_vector(31 downto 0);
   signal SIO1_STAT    : std_logic_vector(31 downto 0);
   signal SIO1_MODE    : std_logic_vector(15 downto 0);
   signal SIO1_CTRL    : std_logic_vector(15 downto 0);
   signal SIO1_BAUD    : std_logic_vector(15 downto 0);
   
   -- savestates
   type t_ssarray is array(0 to 15) of std_logic_vector(31 downto 0); 
   signal ss_out : t_ssarray := (others => (others => '0')); 
  
begin 

   -- SIO1 savestate mappings 
   ss_out(0)              <= SIO1_TX_DATA;
   ss_out(1)              <= SIO1_RX_DATA;
   ss_out(2)              <= SIO1_STAT;
   ss_out(3)(15 downto 0) <= SIO1_MODE;
   ss_out(4)(15 downto 0) <= SIO1_CTRL;
   ss_out(5)(15 downto 0) <= SIO1_BAUD;
   
   -- SNAC interface assignments
   snac_txd <= '1'; -- Idle high when not transmitting
   snac_rts <= SIO1_CTRL(1); -- RTS control bit
   snac_dtr <= SIO1_CTRL(2); -- DTR control bit

   process (clk1x)
   begin
      if rising_edge(clk1x) then
      
         if (reset = '1' and loading_savestate = '0') then
         
            -- SIO1 reset (system link)
            SIO1_TX_DATA <= x"00000000";
            SIO1_RX_DATA <= x"00000000";
            SIO1_STAT    <= x"00000005";
            SIO1_MODE    <= x"0000";
            SIO1_CTRL    <= x"0000";
            SIO1_BAUD    <= x"00DC";
            
         elsif (SS_wren = '1') then
         
            -- SIO1 savestate restore
            if (to_integer(SS_Adr) = 0) then SIO1_TX_DATA <= SS_DataWrite;              end if;
            if (to_integer(SS_Adr) = 1) then SIO1_RX_DATA <= SS_DataWrite;              end if;
            if (to_integer(SS_Adr) = 2) then SIO1_STAT    <= SS_DataWrite;              end if;
            if (to_integer(SS_Adr) = 3) then SIO1_MODE    <= SS_DataWrite(15 downto 0); end if;
            if (to_integer(SS_Adr) = 4) then SIO1_CTRL    <= SS_DataWrite(15 downto 0); end if;
            if (to_integer(SS_Adr) = 5) then SIO1_BAUD    <= SS_DataWrite(15 downto 0); end if;
            
         elsif (ce = '1') then
         
            bus_dataRead <= (others => '0');
            
            -- Update SIO1_STAT with input pin states
            SIO1_STAT(5) <= snac_cts; -- CTS input
            SIO1_STAT(7) <= snac_dsr; -- DSR input

            -- SIO1 bus read (1F801050-1F80105F)
            if (bus_read = '1') then
               case (bus_addr) is
                  when x"0" => bus_dataRead <= SIO1_RX_DATA;  -- RX Data
                  when x"4" => bus_dataRead <= SIO1_STAT;     -- Status    
                  when x"8" => bus_dataRead <= SIO1_CTRL & SIO1_MODE; -- Mode/Control
                  when x"A" => bus_dataRead <= x"0000" & SIO1_CTRL;   -- Control                    
                  when x"E" => bus_dataRead <= x"0000" & SIO1_BAUD;   -- Baud
                  when others => bus_dataRead <= (others => '1');
               end case;
            end if;

            -- SIO1 bus write (1F801050-1F80105F)
            if (bus_write = '1') then
               case (bus_addr) is
                  when x"0" => -- TX Data
                     if (bus_writeMask(0) = '1') then
                        SIO1_TX_DATA <= bus_dataWrite;
                     end if;
                     
                  when x"8" => -- Mode/Control
                     if (bus_writeMask(1 downto 0) /= "00") then
                        SIO1_MODE <= bus_dataWrite(15 downto 0);
                     end if;
                     if (bus_writeMask(3 downto 2) /= "00") then
                        SIO1_CTRL <= bus_dataWrite(31 downto 16);
                        if (bus_dataWrite(22) = '1') then -- reset
                           SIO1_TX_DATA <= x"00000000";
                           SIO1_RX_DATA <= x"00000000";
                           SIO1_STAT    <= x"00000005";
                           SIO1_MODE    <= x"0000";
                           SIO1_CTRL    <= x"0000";
                           SIO1_BAUD    <= x"00DC";
                        end if; 
                     end if;
                     
                  when x"A" => -- Control
                     if (bus_writeMask(1 downto 0) /= "00") then
                        SIO1_CTRL <= bus_dataWrite(15 downto 0);
                     end if;
                     
                  when x"E" => -- Baud
                     if (bus_writeMask(1 downto 0) /= "00") then
                        SIO1_BAUD <= bus_dataWrite(15 downto 0);
                     end if;
                  
                  when others => null;
               end case;
            end if;

         end if;
      end if;
   end process;

--##############################################################
--############################### savestates
--##############################################################
   
   process (clk1x)
   begin
      if (rising_edge(clk1x)) then
         
         if (SS_rden = '1') then
            SS_DataRead <= ss_out(to_integer(SS_Adr));
         end if;
      
      end if;
   end process;

end architecture;