library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.pacman_common.all;

entity image_gen is
    Port (
        pixel_clk      : in  std_logic;
        disp_en        : in  std_logic;
        row            : in  integer range 0 to SCREEN_HEIGHT - 1;
        column         : in  integer range 0 to SCREEN_WIDTH - 1;
        red            : out std_logic_vector(3 downto 0);
        green          : out std_logic_vector(3 downto 0);
        blue           : out std_logic_vector(3 downto 0);
        i_update_pulse : in  std_logic;
        i_reset_pulse  : in  std_logic;
        i_key_press    : in  std_logic_vector(3 downto 0);
        i_sw           : in  std_logic_vector(9 downto 0);
        pacman_row_bin : out std_logic_vector(2 downto 0);
        pacman_col_bin : out std_logic_vector(2 downto 0);
        ghost_row_bin  : out std_logic_vector(2 downto 0);
        ghost_col_bin  : out std_logic_vector(2 downto 0);
        up_wall        : out std_logic;
        down_wall      : out std_logic; 
        left_wall      : out std_logic;
        right_wall     : out std_logic;
        ghost_bin0     : in  std_logic;
        ghost_bin1     : in  std_logic;
        score_count    : out integer range 0 to 255;
        win_flag       : out std_logic
    );
end image_gen;

architecture Behavioral of image_gen is

    component maze_rom is
        Port (
            MAX10_CLK1_50 : in  std_logic;
            i_row         : in  integer range 0 to GRID_HEIGHT;
            i_col         : in  integer range 0 to GRID_WIDTH;
            o_tile        : out std_logic_vector(2 downto 0);
            o_color       : out integer range 0 to 4095;
            KEY           : in  std_logic_vector(1 downto 0);
            SW            : in  std_logic_vector(9 downto 0);
            pacman_row_bin: out std_logic_vector(2 downto 0);
            pacman_col_bin: out std_logic_vector(2 downto 0);
            ghost_row_bin : out std_logic_vector(2 downto 0);
            ghost_col_bin : out std_logic_vector(2 downto 0);
            up_wall       : out std_logic;
            down_wall     : out std_logic; 
            left_wall     : out std_logic;
            right_wall    : out std_logic;
            ghost_bin0    : in  std_logic;
            ghost_bin1    : in  std_logic;
            score_count   : out integer range 0 to 255;
            win_flag      : out std_logic
        );
    end component;

    -- Pacman component
    component pacman is
        Port (
            i_clock        : in  std_logic;
            i_update_pulse : in  std_logic;
            i_reset_pulse  : in  std_logic;
            i_row          : in  integer;
            i_column       : in  integer;
            i_draw_en      : in  std_logic;
            i_key_press    : in  std_logic_vector(3 downto 0);
            o_pos_x        : out integer;
            o_pos_y        : out integer;
            o_color        : out integer range 0 to 4095;
            o_draw         : out std_logic
        );
    end component;

    -- Ghost component
    component ghosts is
        Port (
            i_clock        : in  std_logic;
            i_update_pulse : in  std_logic;
            i_reset_pulse  : in  std_logic;
            i_row          : in  integer;
            i_column       : in  integer;
            i_draw_en      : in  std_logic;
            i_pac_x        : in  integer;
            i_pac_y        : in  integer;
            o_pac_hit      : out std_logic;
            o_color        : out integer range 0 to 4095;
            o_draw         : out std_logic
        );
    end component;

    -- Signals for tile lookup
    signal tile_row : integer range 0 to GRID_HEIGHT - 1;
    signal tile_col : integer range 0 to GRID_WIDTH - 1;
    signal tile_type : std_logic_vector(2 downto 0) := "000";
    signal tile_color : integer range 0 to 4095;
    
    -- Signal for passing KEY inputs to maze_rom
    signal key_to_maze : std_logic_vector(1 downto 0);

    -- Signals for Pacman
    signal pac_x     : integer;
    signal pac_y     : integer;
    signal pac_color : integer range 0 to 4095;
    signal pac_draw  : std_logic;

    -- Signals for Ghosts
    signal ghost_color : integer range 0 to 4095;
    signal ghost_draw  : std_logic;
    signal ghost_hit   : std_logic;

    -- Pixel color signals
    signal pixel_color     : integer range 0 to 4095;
    signal pixel_color_slv : std_logic_vector(11 downto 0);
    
    -- Internal signals for game state
    signal internal_score : integer range 0 to 255;
    signal internal_win : std_logic;

begin

    -- Map the key inputs from pacman_top to maze_rom
    -- In both modes, i_key_press(0) and i_key_press(1) are used
    key_to_maze(0) <= not i_key_press(0);  -- UP/LEFT (active low)
    key_to_maze(1) <= not i_key_press(1);  -- DOWN/RIGHT (active low)

    -- Tile row and column calculation
    tile_row <= row / TILE_SIZE;
    tile_col <= column / TILE_SIZE;
    
    -- Updated maze_rom instantiation with proper connections including SW
    maze_lookup : maze_rom port map (
        MAX10_CLK1_50  => pixel_clk,
        i_row          => tile_row,
        i_col          => tile_col,
        o_tile         => tile_type,
        o_color        => tile_color,
        KEY            => key_to_maze,  -- Connect the key inputs
        SW             => i_sw,          -- Connect switches
        pacman_row_bin => pacman_row_bin,
        pacman_col_bin => pacman_col_bin,
        ghost_row_bin  => ghost_row_bin,
        ghost_col_bin  => ghost_col_bin,
        up_wall        => up_wall,
        down_wall      => down_wall,
        left_wall      => left_wall,
        right_wall     => right_wall,
        ghost_bin0     => ghost_bin0,
        ghost_bin1     => ghost_bin1,
        score_count    => internal_score, -- Connect to internal score signal
        win_flag       => internal_win    -- Connect to internal win signal
    );


    -- Final pixel draw priority process
    -- Modified to use the color directly from maze_rom when appropriate
    process(disp_en, tile_type, tile_color, pac_draw, pac_color, ghost_draw, ghost_color, i_sw)
    begin
        if disp_en = '1' then  -- Only render game if not in start screen mode
            if ghost_draw = '1' then
                pixel_color <= ghost_color;
            elsif pac_draw = '1' then
                pixel_color <= pac_color;
            else
                -- Use tile_color from maze_rom directly
                pixel_color <= tile_color;
            end if;
        else
            pixel_color <= COLOR_BLACK;
        end if;
    end process;

    -- Pass through the game state signals to top level
    score_count <= internal_score;
    win_flag <= internal_win;

    -- Drive VGA output signals
    pixel_color_slv <= std_logic_vector(to_unsigned(pixel_color, 12));
    red   <= pixel_color_slv(11 downto 8);
    green <= pixel_color_slv(7 downto 4);
    blue  <= pixel_color_slv(3 downto 0);

end Behavioral;