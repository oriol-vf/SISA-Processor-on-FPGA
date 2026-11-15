library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity SRAMController is
    port (clk         : in    std_logic;
          -- seÃ±ales para la placa de desarrollo
          SRAM_ADDR   : out   std_logic_vector(17 downto 0);
          SRAM_DQ     : inout std_logic_vector(15 downto 0);
          SRAM_UB_N   : out   std_logic;
          SRAM_LB_N   : out   std_logic;
          SRAM_CE_N   : out   std_logic := '1';
          SRAM_OE_N   : out   std_logic := '1';
          SRAM_WE_N   : out   std_logic := '1';
          -- seÃ±ales internas del procesador
          address     : in    std_logic_vector(15 downto 0) := "0000000000000000";
          dataReaded  : out   std_logic_vector(15 downto 0);
          dataToWrite : in    std_logic_vector(15 downto 0);
          WR          : in    std_logic;
          byte_m      : in    std_logic := '0');
end SRAMController;

architecture comportament of SRAMController is
	
	-- STATE TYPE
	type t_state is (S0, S1, S2);
	
	-- SIGNALS
	signal state : t_state := S0; -- CONTROLLER STATE
	
	signal read_low_mem, read_high_mem, read_selected_byte : std_logic_vector(7 downto 0);
	signal write_selected_byte_extended : std_logic_vector(15 downto 0) := x"0000";
	
begin
	
	SRAM_CE_N <= '0'; -- Enable Chip
	SRAM_OE_N <= '0'; -- Output Enable
	
	-- NOTA: Ja que la mem treballa a nivell de 16 bits per linea, en cada linea tindrem 2 bytes (1 word)
	--			per accedir correctament, tindrem que discriminar entre si accedim al byteN o al byteN+1 i aixo es fa
	--			miran el byte menys significatiu de l'addreça
	SRAM_ADDR <= "000" & (address(15 downto 1)); -- Insert Addr, tenim dos addreçes de proc en cada addreça de mem
	
	-- Mem byte select
	-- Activar la Low (bits: 0..7) quan es un word o quan es s'accedeix un byte en posicio parella 
	SRAM_LB_N <= not ((not byte_m) or (byte_m and (not address(0)))); -- Lower byte
	-- Activar la High (bits: 8..15) quan es un word o quan es s'accedeix un byte en posicio imparella 
	SRAM_UB_N <= not ((not byte_m) or (byte_m and address(0))); -- Upper byte
	
	-- Si estem llegin aleshores posem en Z el bus per lleguir i si estem escribin aleshores posem la dada a escriure
	-- En el cas de la escritura, si accedim a nivrll de byte posem els bits corresponents, depenen del byte a escriure. Si accedim a nivell de word procedirem a 
	-- escriure els 16bits de dataToWrite en el bus.
	SRAM_DQ <= (others => 'Z') when WR = '0' else write_selected_byte_extended when byte_m = '1' else dataToWrite;
		

	-- READ ----------------------------------------------
	-- Byte de posicio parella
	read_low_mem <= SRAM_DQ(7 downto 0);
	-- Byte de posicio imparella
	read_high_mem <= SRAM_DQ(15 downto 8);
	
	-- Tindrem que discriminar segons quin byte estem accedin
	-- Si el bit menys significatiu esta a 0, estem accedin al byte N, mentres que si val 1, estem accedin al byte N+1 de la nostra memoria de 16bits de linea
	read_selected_byte <= read_low_mem when address(0) = '0' else read_high_mem; 
	
	-- Si estem accedin a nivell de byte fem extensio de signe del byte seleccionat o del contraro, si accedim a nivell de word, retornem el valor del bus de la memoria
	dataReaded <= (15 downto 8 => read_selected_byte(7)) & read_selected_byte when byte_m = '1' else SRAM_DQ;
	
	-- ----------------------------------------------------
	
	-- WRITE ----------------------------------------------
	
	-- Si estem accedin a nivell de byte tindrem que discriminar segons quin byte estem escribin
	-- Si estem escribin el byte N (posicio parella), aleshores posarem en el bus els 8 bits menys significatius.
	-- En el cas de escriure el byte N+1 (posicio imparella), escriurem 8 bits menys significatius pero desplacats 8 bits, ja que SRAM_DQ(15 ... 8) seran els
	-- unics on podrem escriure, on es trobara els bits del byte superior de la linea d ela nostra memoria.
	write_selected_byte_extended <= (15 downto 8 => dataToWrite(7)) & dataToWrite(7 downto 0) when address(0) = '0' else dataToWrite(7 downto 0) & x"00";
	
	process (clk) begin
		if rising_edge(clk) then
			if (WR = '1') then -- Nomes escriurem si tenim permis
				case state is 
					when S0 =>
						SRAM_WE_N <= '1'; -- Pujem WE
						state <= S1;
					when S1 =>
						SRAM_WE_N <= '0'; -- Baixem WE, notifiquem a la memoria que volem escriure
						state <= S2;	
					when S2 =>
						SRAM_WE_N <= '1'; -- Pujem WE
					when others =>
						state <= S0;
				end case;
			else 
				state <= S0;
			end if;
		end if;
	end process;
	
end comportament;
