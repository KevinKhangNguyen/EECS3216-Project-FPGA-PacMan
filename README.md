# EECS3216-Project-FPGA-PacMan
A school project that uses a DE-10 Lite to manage and maintain character and ghost movements. Utilizing A Raspberry Pi Pico 2W, ghost movements are calculated using Q-learning before
transmitting the signal through GPIO pins using UART protocol.

Link to video demo: [Demo](https://youtu.be/1clQPIeaPKM)

# FPGA-Based Multi-Board Pacman Game with Integrated AI 
## 📖 Introduction
This project implements a **Pacman-style game** on an FPGA using the DE10-Lite board for real-time graphics and gameplay logic, combined with a Raspberry Pi Pico 2W for AI-driven ghost movement.

- **Display:** VGA output from DE10-Lite to monitor.
- **Controls:**  
  - `KEY0` / `KEY1` → Movement (Up/Down or Left/Right)  
  - `SW0` → Toggle movement mode  
  - `SW9` → Start screen toggle  
  - `SW8` → System reset  
- **AI:** The Pico uses a Q-learning algorithm to dynamically control the ghost, adapting its strategy based on Pacman's position and maze layout.

**Winning Condition:** Collect all 30 pellets before being caught by the ghost. If caught, Pacman and the ghost reset to default positions.

---

## ⚙️ Implementation Details

### Hardware
- DE10-Lite FPGA board  
- Raspberry Pi Pico 2W  
- Breadboard & jumper wires  
- VGA cable & monitor  
- Micro-USB cables

### Software
- Quartus Prime (FPGA development)
- MicroPython (for Pico AI logic)

### FPGA ↔ Pico Communication
- 19 GPIO pins over UART protocol.
- Data sent in binary:
  - Pacman: 3 pins for X, 3 pins for Y
  - Ghost: 3 pins for X, 3 pins for Y
  - Wall sensors: 4 pins (up, down, left, right)
  - AI output: 2 pins for ghost movement decision + 1 ground

---

## 📂 Code Overview

### `Image_gen.vhd`
- Generates game visuals for VGA display.
- Draws maze walls, Pacman (yellow square), and ghost (red square).

### `Maze_rom.vhd`
- Defines the maze layout, wall mapping, and pellet placement.

### `Start_screen.vhd`
- Displays the game’s start/title screen.

### `wall_mapping.vhd.bak`
- Utility package mapping rows and columns to game grid coordinates.

### `Pacman_top.vhd`
- Top-level game controller:
  - Connects FPGA I/O (switches, keys, LEDs, VGA, GPIO).
  - Instantiates VGA controller, PLL, start screen, and game logic.
  - Sends Pacman/ghost positions and wall data to Pico.
  - Receives ghost movement commands from Pico.
  - Tracks and displays score on 7-segment displays.
  - Manages game states and frame updates.

### `Pacman_common.vhd`
- Common constants and types:
  - Grid and screen dimensions
  - Color definitions (RGB 12-bit values)

### `PACMANGHOST.py`
- Pico-based Q-learning ghost AI.
- State representation includes relative position to Pacman and wall data.
- Uses epsilon-greedy action selection with decreasing exploration rate.
- Interfaces with FPGA via GPIO pins.
- Updates Q-table and adapts movement strategy in real-time.

---

## 🖥️ Design Overview
- **FPGA:** Handles rendering, input processing, collision detection, and score tracking.
- **Pico:** Handles AI decision-making for the ghost using reinforcement learning.
- **Communication:** FPGA sends game state to Pico; Pico sends ghost movement commands back.

---

## 🧪 Testing & Debugging
- Verified GPIO connections and pin assignments.
- Tested boundary conditions, wall collisions, and input handling.
- Used Pico console output for debugging AI decision-making.
- Iteratively refined ghost movement and player control logic.

---

## 🚧 Challenges
- VGA display signal setup and synchronization.
- Debouncing hardware buttons (solution: switched to onboard `KEY0`/`KEY1`).
- Pin assignment conflicts between FPGA and Pico 2W.
- Debugging bidirectional data transfer.

---
**This project demonstrates:**
- FPGA-based real-time graphics and game logic.
- Integration of external AI hardware using GPIO communication.
- Application of reinforcement learning for dynamic gameplay.
