LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;        --Esta libreria sera necesaria si usais conversiones TO_INTEGER
USE ieee.std_logic_unsigned.all; --Esta libreria sera necesaria si usais conversiones CONV_INTEGER

ENTITY regfile IS
    PORT (
			 -- INPUTS
			 clk    : IN  STD_LOGIC;
			 boot   : IN  STD_LOGIC; -- Boot
          wrd    : IN  STD_LOGIC;
          d      : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
          addr_a : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
			 addr_b : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
          addr_d : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
			 -- Interrupcion regfile pins
			 is_inter : IN  STD_LOGIC; -- Is interrupcion
			 sys_inst : IN STD_LOGIC_VECTOR(1 DOWNTO 0); -- 00(NON), 01(EI), 10(DI), 11(RETI)
			 d_sys  : IN  STD_LOGIC;
			 a_sys  : IN  STD_LOGIC;
			 -- Exceptions
			 excep : IN STD_LOGIC;
			 excepID : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
			 excepMemAddr : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
			 -- OUTPUTS
          a      : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			 b      : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			 PSW : OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
END regfile;


ARCHITECTURE Structure OF regfile IS
	 type BLOQUE_REG is array (7 downto 0) of std_logic_vector(15 downto 0);
    signal regs : BLOQUE_REG; -- Reg del banc
	 signal system_regs : BLOQUE_REG; -- Reg del banc
BEGIN

	-- Logica de Escritura
	process (clk, boot) begin
		if boot = '1'then
			regs <= (others => (others => '0')); -- Clean regs
			system_regs <= (others => (others => '0')); -- Initialize system reg (coming interrupcion)
			system_regs(7)(0) <= '1'; -- Se inicia en modo sistema
		elsif rising_edge(clk) then -- solo escritura si tenemos permiso y en flanco ascendente
			if excep = '1' then
				system_regs(0) <= system_regs(7); -- S0 <- S7
				system_regs(7)(1) <= '0'; -- s7<1> <- 0 No interrupcion
				if system_regs(7)(0) = '0' then 
					system_regs(7)(0) <= '1'; -- Modo sistema
				end if;
				system_regs(1) <= d; -- S1 <- Pcup
				system_regs(2) <= x"000" & excepID; -- s2 <- excepcion code
				if (excepID = "0100") then -- If excepID == 1 (mem bad alignment) => save mem @
					system_regs(3) <= excepMemAddr;
				elsif (excepID = "1110") then
					system_regs(3) <= regs(conv_integer(addr_a)); --Guardamos Ra en s3
				end if;
			elsif is_inter = '1' and system_regs(7)(1) = '1' then
				system_regs(0) <= system_regs(7); -- S0 <- S7
				system_regs(7)(1) <= '0'; -- s7<1> <- 0 No interrupcion
				if system_regs(7)(0) = '0' then 
					system_regs(7)(0) <= '1'; -- Modo sistema
				end if;
				system_regs(1) <= d; -- S1 <- Pcup
				system_regs(2) <= x"000F"; -- S2 <- 0x000F (Interrupcion)
			elsif wrd = '1' then
				if d_sys = '1' then
					case sys_inst is
						when "00" => -- WRS
							system_regs(conv_integer(addr_d)) <= d; -- write into system regfile
						when "01" => -- EI
							system_regs(7)(1) <= '1';
						when "10" => -- DI
							system_regs(7)(1) <= '0';
						when "11" => -- RETI
							system_regs(7) <= system_regs(0); -- S7 <- S0
							system_regs(7)(0) <= '0'; -- Mode usuari
						when others =>
							-- Nothing
					end case;
				else  
					regs(conv_integer(addr_d)) <= d; -- Write into normal regfile
				end if;
			end if;
		end if;
	end process;
	
	-- Logica de Lectura
	-- IF is_inter = 1 and  system_regs(7)(1) => @interrupcion routine ELSE IF a_sys = 0 => get normal regfile A reg value ELSE get system regfile A reg value
	a <= system_regs(5) when excep = '1' or (is_inter = '1' and  system_regs(7)(1) = '1') else regs(conv_integer(addr_a)) when a_sys = '0' else system_regs(conv_integer(addr_a)); -- Puerto A
	b <= regs(conv_integer(addr_b)); -- Puerto B
	
	PSW <= system_regs(7);
END Structure;