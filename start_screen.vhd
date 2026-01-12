library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pacman_common.ALL;

entity start_screen is
    port (
        clk           : in  std_logic;
        i_row         : in  integer range 0 to SCREEN_HEIGHT-1;
        i_column      : in  integer range 0 to SCREEN_WIDTH-1;
        i_disp_en     : in  std_logic;
        o_red         : out std_logic_vector(3 downto 0);
        o_green       : out std_logic_vector(3 downto 0);
        o_blue        : out std_logic_vector(3 downto 0)
    );
end entity start_screen;

architecture Behavioral of start_screen is
    
    -- flashing bar
    constant FLASH_ROW : integer := 340;
    constant FLASH_COL : integer := 180;
    
    -- pacman text position
    constant TEXT_ROW : integer := 240;  -- vertical center
    constant TEXT_COL : integer := 220;  -- horizontal center

    constant LETTER_WIDTH : integer := 32;
    constant LETTER_HEIGHT : integer := 40;
    constant LETTER_SPACING : integer := 8;

    signal flash_counter : integer range 0 to 25000000 := 0;
    signal flash_state : std_logic := '0';
    
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if flash_counter = 12500000 then
                flash_counter <= 0;
                flash_state <= not flash_state;
            else
                flash_counter <= flash_counter + 1;
            end if;
        end if;
    end process;
    
    -- Rendering process for start screen
    process(i_row, i_column, flash_state)
        variable bar : boolean;
        variable in_letter : boolean;
        variable letter_pos : integer;
        variable letter_x, letter_y : integer;
        variable draw_pixel : boolean;
    begin

        o_red <= (others => '0');
        o_green <= (others => '0');
        o_blue <= (others => '0');
        
        if i_disp_en = '1' then
		  
            bar := (i_row >= FLASH_ROW and i_row < FLASH_ROW + 20 and
                              i_column >= FLASH_COL and i_column < FLASH_COL + 280);
            
            if i_row >= TEXT_ROW and i_row < TEXT_ROW + LETTER_HEIGHT then
                letter_pos := -1;
                for i in 0 to 5 loop
                    if i_column >= TEXT_COL + i * (LETTER_WIDTH + LETTER_SPACING) and 
                       i_column < TEXT_COL + i * (LETTER_WIDTH + LETTER_SPACING) + LETTER_WIDTH then
                        letter_pos := i;
                        letter_x := i_column - (TEXT_COL + i * (LETTER_WIDTH + LETTER_SPACING));
                        letter_y := i_row - TEXT_ROW;
                    end if;
                end loop;

                draw_pixel := false;
                
                -- Draw letter based on position
                if letter_pos = 0 then  -- P
                    draw_pixel := (
                        -- Vertical line
                        (letter_x < 8) or 
                        -- Top horizontal
                        (letter_y < 8 and letter_x < 24) or
                        -- Middle horizontal 
                        (letter_y >= 16 and letter_y < 24 and letter_x < 24) or
                        -- Right curve
                        (letter_x >= 24 and letter_x < 32 and letter_y >= 8 and letter_y < 16)
                    );
                
                elsif letter_pos = 1 then  -- A
                    draw_pixel := (
                        -- Left diagonal
                        (letter_x >= 8 - letter_y/5 and letter_x < 16 - letter_y/5) or
                        -- Right diagonal
                        (letter_x >= 16 + letter_y/5 and letter_x < 24 + letter_y/5) or
                        -- Middle horizontal
                        (letter_y >= 20 and letter_y < 28 and letter_x >= 8 and letter_x < 24)
                    );
                
                elsif letter_pos = 2 then  -- C
                    draw_pixel := (
                        -- Left vertical
                        (letter_x < 8 and letter_y >= 8 and letter_y < 32) or
                        -- Top horizontal
                        (letter_y < 8 and letter_x < 24) or
                        -- Bottom horizontal
                        (letter_y >= 32 and letter_x < 24)
                    );
                
                elsif letter_pos = 3 then  -- M
                    draw_pixel := (
                        -- Left vertical
                        (letter_x < 8) or
                        -- Right vertical
                        (letter_x >= 24) or
                        -- Middle diagonals
                        (letter_x >= 8 and letter_x < 16 and letter_y < letter_x) or
                        (letter_x >= 16 and letter_x < 24 and letter_y < (32 - letter_x))
                    );
                
                elsif letter_pos = 4 then  -- A (again)
                    draw_pixel := (
                        -- Left diagonal
                        (letter_x >= 8 - letter_y/5 and letter_x < 16 - letter_y/5) or
                        -- Right diagonal
                        (letter_x >= 16 + letter_y/5 and letter_x < 24 + letter_y/5) or
                        -- Middle horizontal
                        (letter_y >= 20 and letter_y < 28 and letter_x >= 8 and letter_x < 24)
                    );
                
                elsif letter_pos = 5 then  -- N
                    draw_pixel := (
                        -- Left vertical
                        (letter_x < 8) or
                        -- Right vertical
                        (letter_x >= 24) or
                        -- Diagonal
                        (letter_x >= letter_y - 4 and letter_x < letter_y + 4)
                    );
                end if;
                
                -- yellow color for text
                if draw_pixel then
                    o_red <= (others => '1');
                    o_green <= (others => '1');
                    o_blue <= (others => '0');
                end if;
            end if;
            
				-- white bar
            if bar and flash_state = '1' then
                o_red <= (others => '1');
                o_green <= (others => '1');
                o_blue <= (others => '1');
            end if;
            
            -- blue border
            if (i_row < 5) or (i_row > SCREEN_HEIGHT-6) or (i_column < 5) or (i_column > SCREEN_WIDTH-6) then
                o_red <= (others => '0');
                o_green <= (others => '0');
                o_blue <= (others => '1');
            end if;
        end if;
    end process;
end architecture Behavioral;