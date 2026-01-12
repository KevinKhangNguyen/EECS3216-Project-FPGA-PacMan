library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pacman_common.ALL;
use work.mapping_pkg.ALL;  -- Include the package with row_mapping and col_mapping
use work.wall_mapping.ALL;

entity maze_rom is
    port (
        MAX10_CLK1_50 : in  std_logic;
        i_row         : in  integer range 0 to GRID_HEIGHT;
        i_col         : in  integer range 0 to GRID_WIDTH;
        o_tile        : out std_logic_vector(2 downto 0);
        o_color       : out integer range 0 to 4095;
        KEY           : in  std_logic_vector(1 downto 0);
        SW            : in  std_logic_vector(9 downto 0);
        pacman_row_bin : out std_logic_vector(2 downto 0);
        pacman_col_bin : out std_logic_vector(2 downto 0);
        ghost_row_bin : out std_logic_vector(2 downto 0);
        ghost_col_bin : out std_logic_vector(2 downto 0);
        up_wall       : out std_logic;
        down_wall     : out std_logic; 
        left_wall     : out std_logic;
        right_wall    : out std_logic;
        ghost_bin0    : in  std_logic;
        ghost_bin1    : in  std_logic;
        score_count   : out integer range 0 to 255;  -- Score counter output
        win_flag      : out std_logic               -- Win flag indicator
    );
end maze_rom;

architecture Behavioral of maze_rom is
    signal tile_val : std_logic_vector(2 downto 0);
    
    -- Original starting positions
    constant PACMAN_START_ROW : integer := 2;  -- Middle row
    constant PACMAN_START_COL : integer := 2;  -- Middle column
    constant GHOST_START_ROW  : integer := 3;  -- Middle row
    constant GHOST_START_COL  : integer := 2;  -- Middle column
    
    -- Pacman and Ghost position signals
    signal pacman_row_num  : integer range 0 to 4 := PACMAN_START_ROW;
    signal pacman_col_num  : integer range 0 to 5 := PACMAN_START_COL;
    signal ghost_row_num   : integer range 0 to 4 := GHOST_START_ROW;
    signal ghost_col_num   : integer range 0 to 5 := GHOST_START_COL;
    
    -- Pellet map (1 = pellet exists, 0 = pellet collected)
    type pellet_map_type is array (0 to 4, 0 to 5) of std_logic;
    signal pellet_map : pellet_map_type := (
        ('1', '1', '1', '1', '1', '1'),  -- Row 0 (all cells have pellets)
        ('1', '1', '1', '1', '1', '1'),  -- Row 1
        ('1', '1', '1', '1', '1', '1'),  -- Row 2
        ('1', '1', '1', '1', '1', '1'),  -- Row 3
        ('1', '1', '1', '1', '1', '1')   -- Row 4
    );
    
    -- Game state signals
    signal pellet_count    : integer range 0 to 30 := 0;   -- Total pellets collected
    signal total_pellets   : integer := 30;                -- Total pellets in the maze
    signal game_win        : std_logic := '0';             -- Win flag
    signal game_reset      : std_logic := '0';             -- Game reset signal
    
    -- Add debounce signals
    signal key0_prev : std_logic := '1';
    signal key1_prev : std_logic := '1';
    signal counter : integer range 0 to 5000000 := 0;  -- For debouncing
    signal can_move : std_logic := '1';
    
begin

    -- Reset detection from SW(8)
    game_reset <= SW(8);

    -- Combinational: compute walls, pellets, and overlay Pac‑Man and ghost
    process(i_row, i_col, pacman_row_num, pacman_col_num, ghost_row_num, ghost_col_num, pellet_map)
    begin
        -- Default empty
        tile_val <= "000";

        -- outer border
        if (i_row >= 1 and i_row <= 58 and i_col >= 7 and i_col <= 73) then
            if (i_row = 1 or i_row = 58 or i_col = 7 or i_col = 73) then
                tile_val <= "011";
            end if;
        end if;

        -- upper vertical wall at col=40
        if (i_row >= 1 and i_row <= 12 and i_col = 40) then
            if (i_row = 1 or i_row = 12 or i_col = 40) then
                tile_val <= "011";
            end if;
        end if;

        -- lower vertical wall at col=40
        if (i_row >= 46 and i_row <= 58 and i_col = 40) then
            if (i_row = 46 or i_row = 58 or i_col = 40) then
                tile_val <= "011";
            end if;
        end if;

        -- upper middle wall (row=24, cols 30–50)
        if (i_row = 24 and i_col >= 30 and i_col <= 50) then
            if (i_row = 24 or i_col = 30 or i_col = 50) then
                tile_val <= "011";
            end if;
        end if;

        -- lower middle wall (row=35, cols 30–50)
        if (i_row = 35 and i_col >= 30 and i_col <= 50) then
            if (i_row = 35 or i_col = 30 or i_col = 50) then
                tile_val <= "011";
            end if;
        end if;

        -- upper left corner (horiz)
        if (i_row = 12 and i_col >= 18 and i_col <= 29) then
            if (i_row = 12 or i_col = 18 or i_col = 29) then
                tile_val <= "011";
            end if;
        end if;
        -- upper left corner (vert)
        if (i_row >= 12 and i_row <= 24 and i_col = 18) then
            if (i_row = 12 or i_row = 24 or i_col = 18) then
                tile_val <= "011";
            end if;
        end if;

        -- bottom left corner (horiz)
        if (i_row = 46 and i_col >= 18 and i_col <= 29) then
            if (i_row = 46 or i_col = 18 or i_col = 29) then
                tile_val <= "011";
            end if;
        end if;
        -- bottom left corner (vert)
        if (i_row >= 35 and i_row <= 46 and i_col = 18) then
            if (i_row = 35 or i_row = 46 or i_col = 18) then
                tile_val <= "011";
            end if;
        end if;

        -- bottom right corner (horiz)
        if (i_row = 46 and i_col >= 51 and i_col <= 62) then
            if (i_row = 46 or i_col = 51 or i_col = 62) then
                tile_val <= "011";
            end if;
        end if;
        -- bottom right corner (vert)
        if (i_row >= 35 and i_row <= 46 and i_col = 62) then
            if (i_row = 35 or i_row = 46 or i_col = 62) then
                tile_val <= "011";
            end if;
        end if;

        -- upper right corner (horiz)
        if (i_row = 12 and i_col >= 51 and i_col <= 62) then
            if (i_row = 12 or i_col = 51 or i_col = 62) then
                tile_val <= "011";
            end if;
        end if;
        -- upper right corner (vert)
        if (i_row >= 12 and i_row <= 24 and i_col = 62) then
            if (i_row = 12 or i_row = 24 or i_col = 62) then
                tile_val <= "011";
            end if;
        end if;

        -- Draw pellets based on pellet_map
        if (tile_val = "000") then
            for r in 0 to 4 loop
                for c in 0 to 5 loop
                    if (i_row = row_mapping(r) and i_col = col_mapping(c) and pellet_map(r, c) = '1') then
                        tile_val <= "001";  -- Pellet
                    end if;
                end loop;
            end loop;
        end if;

        -- overlay Pac‑Man at the current (pacman_row_num, pacman_col_num) mapping
        if (i_row >= row_mapping(pacman_row_num) - 2 and
            i_row <= row_mapping(pacman_row_num) + 2 and
            i_col >= col_mapping(pacman_col_num) - 2 and
            i_col <= col_mapping(pacman_col_num) + 2) then
            tile_val <= "010";
        end if;
          
        -- Ghost
        if (i_row >= row_mapping(ghost_row_num) - 2 and
            i_row <= row_mapping(ghost_row_num) + 2 and
            i_col >= col_mapping(ghost_col_num) - 2 and
            i_col <= col_mapping(ghost_col_num) + 2) then
            tile_val <= "100";
        end if;
    end process;
     
    -- Convert pacman position to binary
    pacman_row_bin <= std_logic_vector(to_unsigned(pacman_row_num, 3));
    pacman_col_bin <= std_logic_vector(to_unsigned(pacman_col_num, 3));
     
    ghost_row_bin <= std_logic_vector(to_unsigned(ghost_row_num, 3));
    ghost_col_bin <= std_logic_vector(to_unsigned(ghost_col_num, 3));

    process(MAX10_CLK1_50)
    begin
        if rising_edge(MAX10_CLK1_50) then
            if game_reset = '1' or game_win = '1' then
                -- Reset positions
                pacman_row_num <= PACMAN_START_ROW;
                pacman_col_num <= PACMAN_START_COL;
                ghost_row_num <= GHOST_START_ROW;
                ghost_col_num <= GHOST_START_COL;
                
                -- Reset pellet map
                for r in 0 to 4 loop
                    for c in 0 to 5 loop
                        pellet_map(r, c) <= '1';
                    end loop;
                end loop;
                
                -- Reset game state
                pellet_count <= 0;
                game_win <= '0';
                can_move <= '1';
                counter <= 0;
                
            else
                -- Handle debouncing with counter
                if counter > 0 then
                    counter <= counter - 1;
                elsif can_move = '0' and KEY(0) = '1' and KEY(1) = '1' then
                    -- Both keys released, we can move again
                    can_move <= '1';
                else
                    -- Store previous key values for edge detection
                    key0_prev <= KEY(0);
                    key1_prev <= KEY(1);
                    
                    -- Check for key presses (active low, detect falling edge)
                    if KEY(0) = '0' and key0_prev = '1' and can_move = '1' then
                        -- KEY(0) pressed
                        if SW(0) = '1' then
                            -- LEFT movement (when SW[0] is on)
                            if left_mapping(6 * pacman_row_num + pacman_col_num) = 0 then
                                pacman_col_num <= pacman_col_num - 1;
                            end if;
									 
									 -- Move ghost up
									if ghost_bin0 = '0' and ghost_bin1 = '0' then
										 if up_mapping(6 * ghost_row_num + ghost_col_num) = 0 then
											  ghost_row_num <= ghost_row_num - 1;
										 end if;
										 
									-- Move ghost down
									elsif ghost_bin0 = '0' and ghost_bin1 = '1' then
										 if down_mapping(6 * ghost_row_num + ghost_col_num) = 0 then
											  ghost_row_num <= ghost_row_num + 1;
										 end if;
										 
									-- Move ghost left
									elsif ghost_bin0 = '1' and ghost_bin1 = '0' then
										 if left_mapping(6 * ghost_row_num + ghost_col_num) = 0 then
											  ghost_col_num <= ghost_col_num - 1;
										 end if;
										 
									-- Move ghost right
									elsif ghost_bin0 = '1' and ghost_bin1 = '1' then
										 if right_mapping(6 * ghost_row_num + ghost_col_num) = 0 then
											  ghost_col_num <= ghost_col_num + 1;
										 end if;
									end if;
                        else
                            -- UP movement (when SW[0] is off)
                            if up_mapping(6 * pacman_row_num + pacman_col_num) = 0 then
                                pacman_row_num <= pacman_row_num - 1;
                            end if;
									  -- Move ghost up
									if ghost_bin0 = '0' and ghost_bin1 = '0' then
										 if up_mapping(6 * ghost_row_num + ghost_col_num) = 0 then
											  ghost_row_num <= ghost_row_num - 1;
										 end if;
										 
									-- Move ghost down
									elsif ghost_bin0 = '0' and ghost_bin1 = '1' then
										 if down_mapping(6 * ghost_row_num + ghost_col_num) = 0 then
											  ghost_row_num <= ghost_row_num + 1;
										 end if;
										 
									-- Move ghost left
									elsif ghost_bin0 = '1' and ghost_bin1 = '0' then
										 if left_mapping(6 * ghost_row_num + ghost_col_num) = 0 then
											  ghost_col_num <= ghost_col_num - 1;
										 end if;
										 
									-- Move ghost right
									elsif ghost_bin0 = '1' and ghost_bin1 = '1' then
										 if right_mapping(6 * ghost_row_num + ghost_col_num) = 0 then
											  ghost_col_num <= ghost_col_num + 1;
										 end if;
									end if;
                        end if;
                        can_move <= '0';
                        counter <= 5000000;  -- Set debounce delay
                        
                    elsif KEY(1) = '0' and key1_prev = '1' and can_move = '1' then
                        -- KEY(1) pressed
                        if SW(0) = '1' then
                            -- RIGHT movement (when SW[0] is on)
                            if right_mapping(6 * pacman_row_num + pacman_col_num) = 0 then
                                pacman_col_num <= pacman_col_num + 1;
                            end if;
									  -- Move ghost up
									if ghost_bin0 = '0' and ghost_bin1 = '0' then
										 if up_mapping(6 * ghost_row_num + ghost_col_num) = 0 then
											  ghost_row_num <= ghost_row_num - 1;
										 end if;
										 
									-- Move ghost down
									elsif ghost_bin0 = '0' and ghost_bin1 = '1' then
										 if down_mapping(6 * ghost_row_num + ghost_col_num) = 0 then
											  ghost_row_num <= ghost_row_num + 1;
										 end if;
										 
									-- Move ghost left
									elsif ghost_bin0 = '1' and ghost_bin1 = '0' then
										 if left_mapping(6 * ghost_row_num + ghost_col_num) = 0 then
											  ghost_col_num <= ghost_col_num - 1;
										 end if;
										 
									-- Move ghost right
									elsif ghost_bin0 = '1' and ghost_bin1 = '1' then
										 if right_mapping(6 * ghost_row_num + ghost_col_num) = 0 then
											  ghost_col_num <= ghost_col_num + 1;
										 end if;
									end if;
									
                        else
                            -- DOWN movement (when SW[0] is off)
                            if down_mapping(6 * pacman_row_num + pacman_col_num) = 0 then
                                pacman_row_num <= pacman_row_num + 1;
                            end if;
									 
									  -- Move ghost up
									if ghost_bin0 = '0' and ghost_bin1 = '0' then
										 if up_mapping(6 * ghost_row_num + ghost_col_num) = 0 then
											  ghost_row_num <= ghost_row_num - 1;
										 end if;
										 
									-- Move ghost down
									elsif ghost_bin0 = '0' and ghost_bin1 = '1' then
										 if down_mapping(6 * ghost_row_num + ghost_col_num) = 0 then
											  ghost_row_num <= ghost_row_num + 1;
										 end if;
										 
									-- Move ghost left
									elsif ghost_bin0 = '1' and ghost_bin1 = '0' then
										 if left_mapping(6 * ghost_row_num + ghost_col_num) = 0 then
											  ghost_col_num <= ghost_col_num - 1;
										 end if;
										 
									-- Move ghost right
									elsif ghost_bin0 = '1' and ghost_bin1 = '1' then
										 if right_mapping(6 * ghost_row_num + ghost_col_num) = 0 then
											  ghost_col_num <= ghost_col_num + 1;
										 end if;
									end if;
                        end if;
                        can_move <= '0';
                        counter <= 5000000;
                    end if;

                        -- Check if there's a pellet at the new position and collect it
                        if pellet_map(pacman_row_num, pacman_col_num) = '1' then
                            pellet_map(pacman_row_num, pacman_col_num) <= '0';  -- Mark as collected
                            pellet_count <= pellet_count + 1;  -- Increment score
                            
                            -- Check win condition (all pellets collected)
                            if pellet_count + 1 >= total_pellets then
                                game_win <= '1';  -- Player won!
                            end if;
                        end if;
                    
                    -- Check for collision with ghost (game over)
                    if ghost_row_num = pacman_row_num and ghost_col_num = pacman_col_num then
                        -- Reset after collision
                        pacman_row_num <= PACMAN_START_ROW;
                        pacman_col_num <= PACMAN_START_COL;
                        ghost_row_num <= GHOST_START_ROW;
                        ghost_col_num <= GHOST_START_COL;
                    end if;
                end if;
            end if;
        end if;
    end process;
     
    -- Wall signals for ghost movement logic
    up_wall <= '1' when up_mapping(6 * ghost_row_num + ghost_col_num) = 1 else '0';
    down_wall <= '1' when down_mapping(6 * ghost_row_num + ghost_col_num) = 1 else '0';
    left_wall <= '1' when left_mapping(6 * ghost_row_num + ghost_col_num) = 1 else '0';
    right_wall <= '1' when right_mapping(6 * ghost_row_num + ghost_col_num) = 1 else '0';

    -- Output the score and win flag
    score_count <= pellet_count;
    win_flag <= game_win;

    -- Tile color lookup
    process(tile_val)
    begin
        if (tile_val = "011") then
            o_color <= COLOR_WALL;
        elsif (tile_val = "001") then
            o_color <= COLOR_PELLET;
        elsif (tile_val = "010") then
            o_color <= COLOR_PACMAN;
        elsif (tile_val = "100") then
            o_color <= COLOR_GHOST;
        else
            o_color <= COLOR_BLACK;
        end if;
    end process;

    -- Final outputs
    o_tile <= tile_val;

end Behavioral;