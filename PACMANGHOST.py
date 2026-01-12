from machine import Pin
import time
import random
import math

# Pin definitions
x0_pacman_pin = Pin(2, Pin.IN, Pin.PULL_DOWN)
x1_pacman_pin = Pin(3, Pin.IN, Pin.PULL_DOWN)
x2_pacman_pin = Pin(4, Pin.IN, Pin.PULL_DOWN)
# pacman y-coordindate
y0_pacman_pin = Pin(6, Pin.IN, Pin.PULL_DOWN)
y1_pacman_pin = Pin(7, Pin.IN, Pin.PULL_DOWN)
y2_pacman_pin = Pin(8, Pin.IN, Pin.PULL_DOWN)
# ghost x-coordindate
x0_ghost_pin = Pin(21, Pin.IN, Pin.PULL_DOWN)
x1_ghost_pin = Pin(20, Pin.IN, Pin.PULL_DOWN)
x2_ghost_pin = Pin(19, Pin.IN, Pin.PULL_DOWN)
# ghost y-coordindate
y0_ghost_pin = Pin(18, Pin.IN, Pin.PULL_DOWN)
y1_ghost_pin = Pin(17, Pin.IN, Pin.PULL_DOWN)
y2_ghost_pin = Pin(16, Pin.IN, Pin.PULL_DOWN)
# walls
wall_up = Pin(10, Pin.IN, Pin.PULL_DOWN)
wall_down = Pin(11, Pin.IN, Pin.PULL_DOWN)
wall_left = Pin(12, Pin.IN, Pin.PULL_DOWN)
wall_right = Pin(13, Pin.IN, Pin.PULL_DOWN)
# output
out0 = Pin(27, Pin.OUT)
out1 = Pin(26, Pin.OUT)

# Q-learning parameters
alpha = 0.1         # Learning rate
gamma = 0.9         # Discount factor
epsilon = 0.3       # Exploration rate
min_epsilon = 0.1   # Minimum exploration
epsilon_decay = 0.99  # Exploration decay rate

# Directions
directions = ['up', 'down', 'left', 'right']
moves = [(-1, 0), (1, 0), (0, -1), (0, 1)]  # Corresponding (dy, dx)

# Game state tracking
last_state = None
last_action = None
prev_distance = None
closest_distance = float('inf')
total_rewards = 0
episode_count = 0
state_action_counts = {}  # Track how often we've seen each state-action pair

# Q-table: Maps state-action pairs to expected rewards
# For a lightweight implementation, we'll use a dictionary
# States will be encoded as tuples: (relative_x, relative_y, walls_up, walls_down, walls_left, walls_right)
q_table = {}
state_transitions = {}  # Track which states follow other states given actions

# Experience replay buffer (stores recent experiences to learn from)
experience_buffer = []
buffer_size = 20

def random_sample(population, k):
    """Custom implementation of random.sample for MicroPython"""
    if k > len(population):
        k = len(population)
    
    # Copy the population to avoid modifying the original
    temp_population = population.copy()
    result = []
    
    for i in range(k):
        # Choose a random index
        idx = random.randint(0, len(temp_population) - 1)
        # Add the item to the result
        result.append(temp_population[idx])
        # Remove the item to avoid duplicates
        temp_population.pop(idx)
    
    return result

def encode_state(ghost_x, ghost_y, pac_x, pac_y, walls):
    """Create a compact state representation"""
    # Calculate relative position (limited to range -3 to 3 to keep state space manageable)
    rel_x = max(-3, min(3, pac_x - ghost_x))
    rel_y = max(-3, min(3, pac_y - ghost_y))
    
    # Direction to Pacman
    dir_x = 1 if rel_x > 0 else (-1 if rel_x < 0 else 0)
    dir_y = 1 if rel_y > 0 else (-1 if rel_y < 0 else 0)
    
    # Create a state tuple
    return (rel_x, rel_y, dir_x, dir_y, walls[0], walls[1], walls[2], walls[3])

def get_q_value(state, action):
    """Get Q-value for a state-action pair, defaulting to 0 if not seen before"""
    state_action = (state, action)
    if state_action not in q_table:
        q_table[state_action] = 0.0
    return q_table[state_action]

def update_q_value(state, action, reward, next_state, next_action=None):
    """Update Q-value using Q-learning update rule"""
    # Get current Q-value
    current_q = get_q_value(state, action)
    
    # Calculate the maximum Q-value for the next state
    if next_state:
        next_q_values = [get_q_value(next_state, a) for a in directions]
        max_next_q = max(next_q_values) if next_q_values else 0
    else:
        max_next_q = 0
    
    # Update Q-value using Q-learning formula
    new_q = current_q + alpha * (reward + gamma * max_next_q - current_q)
    
    # Store the updated Q-value
    q_table[(state, action)] = new_q
    
    # Update state transition model
    if state not in state_transitions:
        state_transitions[state] = {}
    if action not in state_transitions[state]:
        state_transitions[state][action] = {}
    if next_state not in state_transitions[state][action]:
        state_transitions[state][action][next_state] = 0
    state_transitions[state][action][next_state] += 1

def add_to_experience(state, action, reward, next_state):
    """Add experience to replay buffer"""
    experience_buffer.append((state, action, reward, next_state))
    if len(experience_buffer) > buffer_size:
        experience_buffer.pop(0)  # Remove oldest experience

def replay_experiences():
    """Learn from past experiences (experience replay)"""
    if len(experience_buffer) < 5:  # Need enough experiences to learn from
        return
    
    # Sample a few experiences to replay using our custom function
    samples = random_sample(experience_buffer, min(5, len(experience_buffer)))
    
    for state, action, reward, next_state in samples:
        update_q_value(state, action, reward, next_state)

def choose_action(state, available_actions, distance_to_pacman):
    """Choose action using epsilon-greedy policy with some smarts"""
    global epsilon, state_action_counts
    
    if not available_actions:
        return None
    
    # Count how many times we've seen this state
    state_count = sum([state_action_counts.get((state, a), 0) for a in directions])
    
    # For rarely seen states, explore more
    local_epsilon = epsilon
    if state_count < 3:
        local_epsilon = 0.5  # Explore more in new states
    
    # Exploration: choose random action
    if random.random() < local_epsilon:
        # With distance heuristic: bias towards actions that seem to decrease distance
        if random.random() < 0.7:  # 70% of exploration uses heuristic
            action_scores = []
            for action_idx, action in enumerate(directions):
                if action not in available_actions:
                    continue
                    
                # Simulate the move
                dx, dy = moves[action_idx]
                if action == 'up':
                    new_distance = distance_to_pacman - 1 if state[2] < 0 else distance_to_pacman + 1
                elif action == 'down':
                    new_distance = distance_to_pacman - 1 if state[2] > 0 else distance_to_pacman + 1
                elif action == 'left':
                    new_distance = distance_to_pacman - 1 if state[3] < 0 else distance_to_pacman + 1
                elif action == 'right':
                    new_distance = distance_to_pacman - 1 if state[3] > 0 else distance_to_pacman + 1
                
                action_scores.append((action, new_distance))
            
            # Choose action with lowest predicted distance
            action_scores.sort(key=lambda x: x[1])
            return action_scores[0][0] if action_scores else random.choice(available_actions)
        else:
            return random.choice(available_actions)
    
    # Exploitation: choose best action according to Q-values
    q_values = {action: get_q_value(state, action) for action in available_actions}
    max_q = max(q_values.values()) if q_values else 0
    
    # Find all actions with the maximum Q-value
    best_actions = [action for action, q in q_values.items() if q == max_q]
    
    # If multiple best actions, choose the one that appears to move towards Pacman
    if len(best_actions) > 1:
        # Use domain knowledge: prefer moves that decrease Manhattan distance
        for action in best_actions:
            # Increment the count for this state-action pair
            if (state, action) not in state_action_counts:
                state_action_counts[(state, action)] = 0
            state_action_counts[(state, action)] += 1
            
            # This is a primitive lookahead, checking if the action seems good
            # based on relative position
            if (action == 'up' and state[0] < 0) or (action == 'down' and state[0] > 0) or \
               (action == 'left' and state[1] < 0) or (action == 'right' and state[1] > 0):
                return action
    
    # Otherwise pick one of the best actions at random
    chosen_action = random.choice(best_actions)
    
    # Increment the count for this state-action pair
    if (state, chosen_action) not in state_action_counts:
        state_action_counts[(state, chosen_action)] = 0
    state_action_counts[(state, chosen_action)] += 1
    
    return chosen_action

def calculate_reward(old_distance, new_distance, ghost_x, ghost_y, pac_x, pac_y):
    """Calculate reward based on change in distance and other factors"""
    global closest_distance
    
    # Base reward on distance change
    if new_distance < old_distance:
        reward = 1.0  # Getting closer is good
    elif new_distance > old_distance:
        reward = -0.5  # Getting further is bad
    else:
        reward = -0.1  # No change is slightly bad (to encourage movement)
    
    # Additional reward if this is the closest we've been
    if new_distance < closest_distance:
        closest_distance = new_distance
        reward += 0.5
    
    # Penalty for walls to encourage finding paths
    if sum([wall_up.value(), wall_down.value(), wall_left.value(), wall_right.value()]) >= 3:
        reward -= 0.2  # Discourage getting trapped
    
    # Big reward for catching Pacman (if we're close)
    if new_distance == 0:
        reward += 10.0
    
    return reward

def predict_next_state(state, action_idx):
    """Predict the next state after taking an action (simple model)"""
    rel_x, rel_y, dir_x, dir_y, w_up, w_down, w_left, w_right = state
    dx, dy = moves[action_idx]
    
    # Update relative position
    new_rel_x = rel_x - dx  # If ghost moves right, pacman is relatively more left
    new_rel_y = rel_y - dy  # If ghost moves down, pacman is relatively more up
    
    # Direction remains the same as it's based on pacman's relative position
    return (new_rel_x, new_rel_y, dir_x, dir_y, w_up, w_down, w_left, w_right)

# Main game loop
print("Ghost AI starting with Q-learning...")
try:
    while True:
        # Read Pacman position
        pacman_x0 = x0_pacman_pin.value()
        pacman_x1 = x1_pacman_pin.value()
        pacman_x2 = x2_pacman_pin.value()
        pacman_y0 = y0_pacman_pin.value()
        pacman_y1 = y1_pacman_pin.value()
        pacman_y2 = y2_pacman_pin.value()
        pacman_x = (pacman_x0 << 2) | (pacman_x1 << 1) | pacman_x2
        pacman_y = (pacman_y0 << 2) | (pacman_y1 << 1) | pacman_y2
        
        # Read Ghost position
        ghost_x0 = x0_ghost_pin.value()
        ghost_x1 = x1_ghost_pin.value()
        ghost_x2 = x2_ghost_pin.value()
        ghost_y0 = y0_ghost_pin.value()
        ghost_y1 = y1_ghost_pin.value()
        ghost_y2 = y2_ghost_pin.value()
        ghost_x = (ghost_x0 << 2) | (ghost_x1 << 1) | ghost_x2
        ghost_y = (ghost_y0 << 2) | (ghost_y1 << 1) | ghost_y2
        
        # Read wall sensors
        walls = [wall_up.value(), wall_down.value(), wall_left.value(), wall_right.value()]
        
        # Calculate current distance
        current_distance = abs(ghost_x - pacman_x) + abs(ghost_y - pacman_y)
        
        # Encode current state
        current_state = encode_state(ghost_x, ghost_y, pacman_x, pacman_y, walls)
        
        # Determine valid moves
        valid_moves = []
        for i, wall in enumerate(walls):
            if not wall:
                valid_moves.append(directions[i])
        
        # If we have a previous state and action, calculate reward and update Q-table
        if last_state is not None and last_action is not None and prev_distance is not None:
            reward = calculate_reward(prev_distance, current_distance, ghost_x, ghost_y, pacman_x, pacman_y)
            total_rewards += reward
            
            update_q_value(last_state, last_action, reward, current_state)
            add_to_experience(last_state, last_action, reward, current_state)
            
            # Every 10 moves, replay some experiences
            if episode_count % 10 == 0:
                replay_experiences()
        
        # Choose next action
        action = choose_action(current_state, valid_moves, current_distance)
        
        # Display debug info
        print(f"State: {current_state}, Action: {action}")
        print(f"Distance: {current_distance}, Valid moves: {valid_moves}")
        print(f"Total rewards: {total_rewards}, Epsilon: {epsilon:.2f}")
        
        # Update last state and action
        last_state = current_state
        last_action = action
        prev_distance = current_distance
        
        # Set output pins based on chosen action
        if action == 'up':
            out0.value(0)
            out1.value(0)
        elif action == 'down':
            out0.value(0)
            out1.value(1)
        elif action == 'left':
            out0.value(1)
            out1.value(0)
        elif action == 'right':
            out0.value(1)
            out1.value(1)
        
        # Decay exploration rate
        epsilon = max(min_epsilon, epsilon * epsilon_decay)
        
        # Increment episode counter
        episode_count += 1
        
        # Wait before next move (shorter time for more responsive gameplay)
        time.sleep(0.7)

except KeyboardInterrupt:
    print("AI terminated")


