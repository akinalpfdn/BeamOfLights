import json
import random
import uuid

# --- Configuration ---
LEVELS_TO_GENERATE = [
    {"id": 1, "rows": 20, "cols": 20, "density": 0.60, "min_len": 4, "max_len": 15}, # Medium
    {"id": 2, "rows": 25, "cols": 25, "density": 0.70, "min_len": 5, "max_len": 20}, # Hard
    {"id": 3, "rows": 40, "cols": 40, "density": 0.75, "min_len": 5, "max_len": 40}, # STRESS TEST
]

DIRECTIONS = {
    "right": (0, 1),
    "left": (0, -1),
    "down": (1, 0),
    "up": (-1, 0)
}

OPPOSITE = {
    "right": "left",
    "left": "right",
    "down": "up",
    "up": "down"
}

def random_hex_color():
    """Generates a random neon-bright hex color."""
    # We bias towards high values (80-FF) for neon look
    r = random.randint(100, 255)
    g = random.randint(100, 255)
    b = random.randint(100, 255)
    return f"#{r:02X}{g:02X}{b:02X}"

class Grid:
    def __init__(self, rows, cols):
        self.rows = rows
        self.cols = cols
        self.occupied = set() # Set of (r, c)
        self.beams = []

    def is_free(self, r, c):
        return 0 <= r < self.rows and 0 <= c < self.cols and (r, c) not in self.occupied

    def add_beam(self, min_len, max_len):
        """
        Tries to slide a beam INTO the grid from an edge.
        If successful, adds it to the list.
        """
        # 1. Pick a random starting point on the perimeter
        # Logic: We simulate sliding *IN* from outside. 
        # So the 'head' starts at an edge or adjacent to an empty space (conceptually)
        # For simplicity/solvability: Start at a free cell.
        
        candidates = []
        for r in range(self.rows):
            for c in range(self.cols):
                if (r, c) not in self.occupied:
                    candidates.append((r,c))
        
        if not candidates: return False
        
        start_r, start_c = random.choice(candidates)
        
        # 2. Random Walk 'Snake' generation
        # We grow the snake cell by cell into empty spaces
        current_path = [(start_r, start_c)]
        current_dirs = [] # Direction taken to get to next cell
        
        length = random.randint(min_len, max_len)
        
        for _ in range(length - 1):
            curr_r, curr_c = current_path[-1]
            valid_moves = []
            
            for d_name, (dr, dc) in DIRECTIONS.items():
                nr, nc = curr_r + dr, curr_c + dc
                if self.is_free(nr, nc) and (nr, nc) not in current_path:
                    valid_moves.append((d_name, nr, nc))
            
            if not valid_moves:
                break # Stuck, stop growing
            
            move, next_r, next_c = random.choice(valid_moves)
            current_path.append((next_r, next_c))
            current_dirs.append(move)

        if len(current_path) < min_len:
            return False # Too short

        # 3. Determine 'Slide Direction'
        # To guarantee it can slide out, the TAIL must point towards a valid exit path.
        # This simple generator ensures non-overlap, but 'true' reversibility 
        # implies the snake can slide out.
        # For this logic, we will assume the snake slides 'forward' (towards head) to exit.
        # So Head needs to be "free" initially? 
        # Actually, in Reverse Engineering: We place snakes on top. The last placed snake is free.
        # So we just need to ensure valid placement.
        
        # Mark occupied
        for r, c in current_path:
            self.occupied.add((r, c))
            
        # Create Beam Object
        color = random_hex_color()
        
        # Convert path to Cell Objects
        cells = []
        
        # We need to determine the visual 'direction' for each cell (the arrow)
        # The stored path is [Head, ..., Tail] or [Tail, ..., Head]?
        # Let's say current_path[0] is the START (Tail) and [-1] is END (Head)
        
        # START Cell
        # Direction points to next cell
        first_r, first_c = current_path[0]
        second_r, second_c = current_path[1]
        
        start_dir = get_dir(first_r, first_c, second_r, second_c)
        cells.append({
            "row": first_r, "column": first_c, 
            "type": "start", "direction": start_dir, "color": color
        })
        
        # MIDDLE Cells
        for i in range(1, len(current_path) - 1):
            pr, pc = current_path[i]
            nr, nc = current_path[i+1]
            d = get_dir(pr, pc, nr, nc)
            cells.append({
                "row": pr, "column": pc, 
                "type": "path", "direction": d, "color": color
            })
            
        # END Cell
        last_r, last_c = current_path[-1]
        # End cell direction matches the previous segment flow usually
        # Or it points "out". Let's use the direction arriving at it.
        prev_r, prev_c = current_path[-2]
        end_dir = get_dir(prev_r, prev_c, last_r, last_c)
        
        cells.append({
            "row": last_r, "column": last_c, 
            "type": "end", "direction": end_dir, "color": color
        })
        
        self.beams.append(cells)
        return True

def get_dir(r1, c1, r2, c2):
    if r2 > r1: return "down"
    if r2 < r1: return "up"
    if c2 > c1: return "right"
    if c2 < c1: return "left"
    return "none"

# --- Main Generation Loop ---

final_output = {"levels": []}

for cfg in LEVELS_TO_GENERATE:
    print(f"Generating Level {cfg['id']} ({cfg['rows']}x{cfg['cols']})...")
    grid = Grid(cfg['rows'], cfg['cols'])
    
    target_cells = int(cfg['rows'] * cfg['cols'] * cfg['density'])
    attempts = 0
    
    while len(grid.occupied) < target_cells and attempts < 2000:
        success = grid.add_beam(cfg['min_len'], cfg['max_len'])
        if not success:
            attempts += 1
        else:
            attempts = 0 # Reset fails if we succeed
            
    # Flatten cells
    all_cells = []
    for beam in grid.beams:
        all_cells.extend(beam)
        
    # Add Empties (optional, or your app handles missing cells as empty)
    # Your app seems to expect explicit "empty" cells? 
    # If so, we need to fill the gaps.
    for r in range(cfg['rows']):
        for c in range(cfg['cols']):
            if (r, c) not in grid.occupied:
                all_cells.append({
                    "row": r, "column": c,
                    "type": "empty", "direction": "none", "color": ""
                })
                
    final_output["levels"].append({
        "levelNumber": cfg['id'],
        "gridSize": {"rows": cfg['rows'], "columns": cfg['cols']},
        "difficulty": 5, # Placeholder
        "cells": all_cells
    })
    
    print(f"  - Density achieved: {len(grid.occupied) / (cfg['rows']*cfg['cols']):.2%}")
    print(f"  - Total Beams: {len(grid.beams)}")

# Write to file
with open("levels_generated.json", "w") as f:
    json.dump(final_output, f, indent=2)

print("Done! Copy content from levels_generated.json")