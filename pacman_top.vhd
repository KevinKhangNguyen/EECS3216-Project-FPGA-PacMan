library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pacman_common.all;

entity pacman_top is
    PORT( 
        KEY                                : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        SW                                 : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        MAX10_CLK1_50                      : IN STD_LOGIC;
        LEDR                               : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        HEX5, HEX4, HEX3, HEX2, HEX1, HEX0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        GPIO                               : INOUT std_logic_vector(35 downto 0);

        -- VGA I/O
        VGA_HS : OUT STD_LOGIC;
        VGA_VS : OUT STD_LOGIC;
        VGA_R  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        VGA_G  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        VGA_B  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
end pacman_top;

architecture top_level of pacman_top is

    -- VGA timing
    signal clk_25_175_MHz : std_logic;
    signal row            : integer range 0 to SCREEN_HEIGHT-1;
    signal column         : integer range 0 to SCREEN_WIDTH-1;
    signal disp_en        : std_logic;

    signal update_pulse   : std_logic := '0';

    -- VGA color signals
    signal red_sig, green_sig, blue_sig : std_logic_vector(3 downto 0);
    signal start_red, start_green, start_blue : std_logic_vector(3 downto 0);
    signal game_red, game_green, game_blue : std_logic_vector(3 downto 0);

    signal key_dir : std_logic_vector(3 downto 0);
     
    signal pacman_row_bin : std_logic_vector(2 downto 0);
    signal pacman_col_bin : std_logic_vector(2 downto 0);
    signal ghost_row_bin : std_logic_vector(2 downto 0);
    signal ghost_col_bin : std_logic_vector(2 downto 0);
     
    signal up_wall : std_logic;
    signal down_wall : std_logic;
    signal left_wall : std_logic;
    signal right_wall : std_logic;
     
    signal ghost_bin0: std_logic;
    signal ghost_bin1: std_logic;
     
    signal gpio_35_in : std_logic := '0';
    signal gpio_34_in : std_logic := '0';

    signal score_count : integer range 0 to 255 := 0;
    signal win_flag : std_logic := '0';

    signal score_bcd : std_logic_vector(7 downto 0);
    
    -- Start screen component
    component start_screen is
        port (
            clk           : in  std_logic;
            i_row         : in  integer range 0 to SCREEN_HEIGHT-1;
            i_column      : in  integer range 0 to SCREEN_WIDTH-1;
            i_disp_en     : in  std_logic;
            o_red         : out std_logic_vector(3 downto 0);
            o_green       : out std_logic_vector(3 downto 0);
            o_blue        : out std_logic_vector(3 downto 0)
        );
    end component;

    component vga_pll_25_175 is
        port(
            inclk0 : in  std_logic;
            c0     : out std_logic
        );
    end component;

    component dual_boot is
        port(
            clk_clk       : in std_logic := 'X';
            reset_reset_n : in std_logic := 'X'
        );
    end component;
    
    -- Seven-segment display decoder
    function hex_to_7seg(hex: in std_logic_vector(3 downto 0)) return std_logic_vector is
    begin
        case hex is
            when "0000" => return "11000000"; -- 0
            when "0001" => return "11111001"; -- 1
            when "0010" => return "10100100"; -- 2
            when "0011" => return "10110000"; -- 3
            when "0100" => return "10011001"; -- 4
            when "0101" => return "10010010"; -- 5
            when "0110" => return "10000010"; -- 6
            when "0111" => return "11111000"; -- 7
            when "1000" => return "10000000"; -- 8
            when "1001" => return "10010000"; -- 9
            when others => return "11111111"; -- blank
        end case;
    end function;

begin

    key_dir <= "0001" when KEY(0) = '0' else  -- UP/LEFT based on SW(0)
               "0010" when KEY(1) = '0' else  -- DOWN/RIGHT based on SW(0)
               "1000";  -- default = no movement or continue current direction
                    
    gpio_35_in <= GPIO(35);
    gpio_34_in <= GPIO(34);
    
    -- Ghost control signals from pico
    ghost_bin0 <= gpio_35_in;
    ghost_bin1 <= gpio_34_in;
     

    -- VGA pixel clock
    u_pll : vga_pll_25_175
        port map (
            inclk0 => MAX10_CLK1_50,
            c0     => clk_25_175_MHz
        );

    -- VGA controller
    u_vga : entity work.vga_controller
        port map (
            pixel_clk => clk_25_175_MHz,
            reset_n   => '1',
            h_sync    => VGA_HS,
            v_sync    => VGA_VS,
            disp_ena  => disp_en,
            column    => column,
            row       => row,
            n_blank   => open,
            n_sync    => open
        );

    -- Start screen
    u_start_screen : start_screen
        port map (
            clk       => clk_25_175_MHz,
            i_row     => row,
            i_column  => column,
            i_disp_en => disp_en,
            o_red     => start_red,
            o_green   => start_green,
            o_blue    => start_blue
        );

    -- Frame update
    process(clk_25_175_MHz)
    begin
        if rising_edge(clk_25_175_MHz) then
            if disp_en = '0' and row = SCREEN_HEIGHT - 1 and column = SCREEN_WIDTH - 1 then
                update_pulse <= '1';
            else
                update_pulse <= '0';
            end if;
        end if;
    end process;

    -- Game module
    u_game : entity work.image_gen
        port map (
            pixel_clk       => clk_25_175_MHz,
            disp_en         => disp_en,
            row             => row,
            column          => column,
            red             => game_red,
            green           => game_green,
            blue            => game_blue,
            i_update_pulse  => update_pulse,
            i_reset_pulse   => '0',
            i_key_press     => key_dir,
            i_sw            => SW,
            pacman_row_bin  => pacman_row_bin,
            pacman_col_bin  => pacman_col_bin,
            ghost_row_bin   => ghost_row_bin,
            ghost_col_bin   => ghost_col_bin,
            up_wall         => up_wall,
            down_wall       => down_wall,
            left_wall       => left_wall,
            right_wall      => right_wall,
            ghost_bin0      => ghost_bin0,
            ghost_bin1      => ghost_bin1,
            score_count     => score_count,
            win_flag        => win_flag
        );
          
    -- Convert score to BCD
    process(score_count)
        variable tens_digit : integer range 0 to 9;
        variable ones_digit : integer range 0 to 9;
    begin
        tens_digit := score_count / 10;
        ones_digit := score_count mod 10;
        
        score_bcd(7 downto 4) <= std_logic_vector(to_unsigned(tens_digit, 4));
        score_bcd(3 downto 0) <= std_logic_vector(to_unsigned(ones_digit, 4));
    end process;
    
    -- Start screen
    process(SW, start_red, start_green, start_blue, game_red, game_green, game_blue)
    begin
        if SW(9) = '1' then
            -- Show start screen when SW(9) is ON
            VGA_R <= start_red;
            VGA_G <= start_green;
            VGA_B <= start_blue;
        else
            -- Show game screen when SW(9) is OFF
            VGA_R <= game_red;
            VGA_G <= game_green;
            VGA_B <= game_blue;
        end if;
    end process;
	 
    HEX1 <= hex_to_7seg(score_bcd(7 downto 4));  -- Tens digit
    HEX0 <= hex_to_7seg(score_bcd(3 downto 0));  -- Ones digit
    HEX5 <= (others => '1');
    HEX4 <= (others => '1');
    HEX3 <= (others => '1');
    HEX2 <= (others => '1');
    
    LEDR(0) <= not KEY(0);
    LEDR(1) <= not KEY(1);
    LEDR(2) <= '0';
    LEDR(3) <= '0';
    LEDR(4) <= '0'; 
    LEDR(5) <= '0';
    LEDR(6) <= '0';
    LEDR(7) <= '0';
    LEDR(8) <= '0';
    LEDR(9) <= SW(9);

    -- Pacman x coordinates
    GPIO(1) <= pacman_col_bin(0);  -- GPIO 1 = Row bit 0 (LSB)
    GPIO(3) <= pacman_col_bin(1);  -- GPIO 3 = Row bit 1
    GPIO(5) <= pacman_col_bin(2);  -- GPIO 5 = Row bit 2 (MSB)
     
    -- Pacman y coordinates
    GPIO(0) <= pacman_row_bin(0);  -- GPIO 0 = Column bit 0 (LSB)
    GPIO(2) <= pacman_row_bin(1);  -- GPIO 2 = Column bit 1
    GPIO(4) <= pacman_row_bin(2);  -- GPIO 4 = Column bit 2 (MSB)
     
    -- Ghost x coordinates
    GPIO(11) <= ghost_col_bin(0);  -- GPIO 11 = Ghost Row bit 0 (LSB)
    GPIO(13) <= ghost_col_bin(1);  -- GPIO 13 = Ghost Row bit 1
    GPIO(15) <= ghost_col_bin(2);  -- GPIO 15 = Ghost Row bit 2 (MSB)
     
    -- Ghost y coordinates
    GPIO(10) <= ghost_row_bin(0);  -- GPIO 10 = Ghost Column bit 0 (LSB)
    GPIO(12) <= ghost_row_bin(1);  -- GPIO 12 = Ghost Column bit 1
    GPIO(14) <= ghost_row_bin(2);  -- GPIO 14 = Ghost Column bit 2 (MSB)
     
    -- Wall values
    GPIO(20) <= up_wall;
    GPIO(21) <= left_wall;
    GPIO(22) <= down_wall;
    GPIO(23) <= right_wall;

end top_level;