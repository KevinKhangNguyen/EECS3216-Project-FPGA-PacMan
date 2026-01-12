library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package pacman_common is

    -- Tile and Screen Dimensions
    constant TILE_SIZE       : integer := 8;
    constant GRID_WIDTH      : integer := 80;
    constant GRID_HEIGHT     : integer := 60;
    constant SCREEN_WIDTH    : integer := GRID_WIDTH * TILE_SIZE;
    constant SCREEN_HEIGHT   : integer := GRID_HEIGHT * TILE_SIZE;

    -- RGB Colors (4-bit per channel = RGB444)
    constant COLOR_BLACK     : integer := 16#000#; -- blanking
    constant COLOR_WALL      : integer := 16#00F#; -- blue wall
    constant COLOR_PELLET    : integer := 16#FFF#; -- white pellet
    constant COLOR_PACMAN    : integer := 16#FF0#; -- yellow
    constant COLOR_GHOST    : integer := 16#F00#; -- red

end package;

package body pacman_common is
end package body;
