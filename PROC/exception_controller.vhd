LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;        --Esta libreria sera necesaria si usais conversiones TO_INTEGER
USE ieee.std_logic_unsigned.all; --Esta libreria sera necesaria si usais conversiones CONV_INTEGER
ENTITY exception_controller IS
	PORT (
			boot	:	IN	STD_LOGIC;
			clk	: 	IN STD_LOGIC;
			div_zero : IN STD_LOGIC;
			mem_access	 : IN STD_LOGIC;
			bad_alignment : IN STD_LOGIC;
			illegal_inst : IN STD_LOGIC;
			excep_ack	: IN STD_LOGIC;
			sys_mode : IN STD_LOGIC;
			is_fetch : IN STD_LOGIC;
			is_store : IN STD_LOGIC;
			protected_inst : IN STD_LOGIC;
			calls_inst : IN STD_LOGIC;
			addr_m : IN STD_LOGIC_VECTOR(15 downto 0);
			pc		 : IN STD_LOGIC_VECTOR(15 downto 0);
			-- TLB Excepcions
			i_tlb_excep : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
			i_tlb_v     : IN STD_LOGIC;
			i_tlb_r     : IN STD_LOGIC;
			
			d_tlb_excep : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
			d_tlb_v     : IN STD_LOGIC;
			d_tlb_r     : IN STD_LOGIC;
			excep	:	OUT STD_LOGIC;
			excepId : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
		);
END exception_controller 	;

ARCHITECTURE Struc OF exception_controller IS
	signal tmp_excepId : std_logic_vector(3 downto 0) := "0000";
	signal tmp_excep 	: std_logic := '0';
BEGIN

	process (clk, boot) begin
		if boot = '1' then
			tmp_excep <= '0';
			tmp_excepId <= "0000";
		elsif rising_edge(clk) then
				if excep_ack = '1' then
					tmp_excep <= '0';
					tmp_excepId <= "0000";
				elsif tmp_excep = '0' then
					if (illegal_inst = '1' or (calls_inst = '1' and sys_mode = '1')) then
						tmp_excep <= '1';
						tmp_excepId <= "0000"; -- Illegal Instruction Exception (0)
					elsif (mem_access = '1' and bad_alignment = '1') then
						tmp_excep <= '1';
						tmp_excepId <= "0001"; -- Bad @ Alignment Exception (1)
					elsif (div_zero = '1') then
						tmp_excep <= '1';
						tmp_excepId <= "0100"; -- Div Zero Exception (4)
					elsif (i_tlb_excep = "01" and (is_fetch = '1')) then
						tmp_excep <= '1';
						tmp_excepId <= "0110"; -- Miss Inst TLB (6)
					elsif (d_tlb_excep = "01" and (mem_access = '1')) then
						tmp_excep <= '1';
						tmp_excepId <= "0111"; -- Miss Data TLB (7)
					elsif (i_tlb_excep = "10" and (is_fetch = '1')) then
						tmp_excep <= '1';
						tmp_excepId <= "1000"; -- Invalid Inst TLB page (8)
					elsif (d_tlb_excep = "10" and (mem_access = '1')) then
						tmp_excep <= '1';
						tmp_excepId <= "1001"; -- Invalid Data TLB page (9)
					elsif ((is_fetch = '1') and (pc(15) = '1') and (sys_mode = '0')) then
						tmp_excep <= '1';
						tmp_excepId <= "1010"; -- Protected inst page (10)
					elsif ((mem_access = '1') and (pc(15) = '1') and (sys_mode = '0')) then
						tmp_excep <= '1';
						tmp_excepId <= "1011"; -- Protected data page (11)
					elsif (is_store = '1' and d_tlb_r = '1') then
						tmp_excep <= '1';
						tmp_excepId <= "1100"; -- Write into read only data page(12)
					elsif (sys_mode = '0' and addr_m(15) = '1' and not (addr_m >= x"A000" and addr_m < x"C000") and (mem_access = '1')) then -- addr_m(15) == 0x8000
						tmp_excep <= '1';
						tmp_excepId <= "1011"; -- Protected memory access excpetion (11)
					elsif (protected_inst = '1' and sys_mode = '0') then
						tmp_excep <= '1';
						tmp_excepId <= "1101"; -- Protected instruction exception (13)
					elsif (calls_inst = '1' and sys_mode = '0') then
						tmp_excep <= '1';
						tmp_excepId <= "1110"; -- CALLS (14)
					end if;
				end if;
		end if;
	end process;
	
	-- Output singlas
	excep <= tmp_excep;
	excepId <= tmp_excepId;

END Struc;