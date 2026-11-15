LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;

ENTITY tlb IS
    PORT(
        I_or_D          : IN  std_logic;
        clk             : IN  std_logic;
		  boot				: IN 	std_logic;
        flush           : IN  std_logic;
        vtag            : IN  std_logic_vector(3 downto 0);
        -- Config TLB
        conf_en         : IN  std_logic_vector(2 downto 0); -- ENABLE - I/D - V/P
        addr_line_conf  : IN  std_logic_vector(2 downto 0);
        new_line_conf   : IN  std_logic_vector(5 downto 0); -- v(1bit) - r(1bit) - tag(4bits)
        -- Outputs
        tlb_excep       : OUT std_logic_vector(1 downto 0);
        ptag            : OUT std_logic_vector(3 downto 0);
        v               : OUT std_logic;
        r               : OUT std_logic
    );
END tlb;

ARCHITECTURE Struc OF tlb IS

    type V_TLB_LINE_TYPE is array (7 downto 0) of std_logic_vector(3 downto 0); 
    type P_TLB_LINE_TYPE is array (7 downto 0) of std_logic_vector(5 downto 0); 
    
    signal v_lines : V_TLB_LINE_TYPE;
    signal p_lines : P_TLB_LINE_TYPE;
    signal is_equal : std_logic_vector(7 downto 0) := (others => '0');
    signal ph_selected_line : std_logic_vector(2 downto 0);
    signal tmp_v, tmp_r : std_logic;
    signal hit : std_logic;

BEGIN
    -- TLB config
    process (flush, clk, boot) 
    begin
        if boot = '1' then
            -- P_TLB format: Bit 5 (v), Bit 4 (r), Bits 3..0 (ptag)
            
            -- User page (0x0000 a 0x2FFF) -> v=1, r=0
            v_lines(0) <= x"0"; p_lines(0) <= "100000"; 
            v_lines(1) <= x"1"; p_lines(1) <= "100001"; 
            v_lines(2) <= x"2"; p_lines(2) <= "100010"; 
            
            -- System page : low RAM (0x8000) -> v=1, r=0
            v_lines(3) <= x"8"; p_lines(3) <= "101000"; 
            
            -- System page (0xC000 a 0xFFFF) -> v=1, r=1 (Only read)
            v_lines(4) <= x"C"; p_lines(4) <= "111100"; 
            v_lines(5) <= x"D"; p_lines(5) <= "111101"; 
            v_lines(6) <= x"E"; p_lines(6) <= "111110"; 
            v_lines(7) <= x"F"; p_lines(7) <= "111111";
			
		  elsif flush = '1' and addr_line_conf(conv_integer("" & I_or_D)) = '1' then
				v_lines <= (others => (others => '0'));
				p_lines <= (others => (others => '0'));
        elsif rising_edge(clk) and (conf_en(2) = '1') then
            if conf_en(1) = I_or_D then
                if (conf_en(0) = '0') then -- Mod virtual line info
                    v_lines(conv_integer(addr_line_conf)) <= new_line_conf(3 downto 0);
                else -- Mod physical line info
                    p_lines(conv_integer(addr_line_conf)) <= new_line_conf;
                end if;
            end if;
        end if;
    end process;
    
    -- Compa
    is_equal(0) <= '1' when vtag = v_lines(0) else '0';
    is_equal(1) <= '1' when vtag = v_lines(1) else '0';
    is_equal(2) <= '1' when vtag = v_lines(2) else '0';
    is_equal(3) <= '1' when vtag = v_lines(3) else '0';
    is_equal(4) <= '1' when vtag = v_lines(4) else '0';
    is_equal(5) <= '1' when vtag = v_lines(5) else '0';
    is_equal(6) <= '1' when vtag = v_lines(6) else '0';
    is_equal(7) <= '1' when vtag = v_lines(7) else '0';
    
    -- TLB Hit
    hit <= is_equal(0) or is_equal(1) or is_equal(2) or is_equal(3) or 
           is_equal(4) or is_equal(5) or is_equal(6) or is_equal(7);

    -- Decoder
    ph_selected_line <= 
        "000" when is_equal(0) = '1' else
        "001" when is_equal(1) = '1' else
        "010" when is_equal(2) = '1' else
        "011" when is_equal(3) = '1' else
        "100" when is_equal(4) = '1' else
        "101" when is_equal(5) = '1' else
        "110" when is_equal(6) = '1' else
        "111" when is_equal(7) = '1' else
        "000";
                                    
    -- Multiplexor
    ptag <= p_lines(conv_integer(ph_selected_line))(3 downto 0);
    tmp_r <= p_lines(conv_integer(ph_selected_line))(4);
    tmp_v <= p_lines(conv_integer(ph_selected_line))(5);
    
    r <= tmp_r;
    v <= tmp_v;
    
    -- Excepcions
    tlb_excep <= 
        "01" when hit = '0'   else -- TLB MISS (No Hit)
        "10" when tmp_v = '0' else -- Invalid page
        "00";
END Struc;