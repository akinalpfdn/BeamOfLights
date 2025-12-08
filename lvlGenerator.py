import json
import random

# --- Configuration ---
LEVEL_CONFIGS = [
    {"id": 1, "rows": 8, "cols": 8, "density": 0.90, "min_len": 3, "max_len": 15, "hearts": 3},
    {"id": 2, "rows": 10, "cols": 10, "density": 0.95, "min_len": 4, "max_len": 20, "hearts": 3},
    {"id": 3, "rows": 15, "cols": 15, "density": 0.90, "min_len": 4, "max_len": 30, "hearts": 4},
    {"id": 4, "rows": 20, "cols": 20, "density": 0.95, "min_len": 5, "max_len": 30, "hearts": 4},
    {"id": 5, "rows": 25, "cols": 25, "density": 0.95, "min_len": 6, "max_len": 40, "hearts": 5},
    {"id": 6, "rows": 30, "cols": 30, "density": 0.90, "min_len": 6, "max_len": 60, "hearts": 5},
    {"id": 7, "rows": 40, "cols": 40, "density": 0.90, "min_len": 8, "max_len": 100, "hearts": 6},
]

DIRECTIONS = {
    "right": (0, 1),
    "left": (0, -1),
    "down": (1, 0),
    "up": (-1, 0)
}

def random_hex_color():
    """Generates distinct neon colors."""
    r = random.randint(50, 255)
    g = random.randint(50, 255)
    b = random.randint(50, 255)
    # Boost saturation
    if random.random() < 0.33: r = 255
    elif random.random() < 0.5: g = 255
    else: b = 255
    return f"#{r:02X}{g:02X}{b:02X}"

class Grid:
    def __init__(self, rows, cols):
        self.rows = rows
        self.cols = cols
        self.occupied = set()
        self.reserved_exits = set()
        self.beams = []
        self.beam_heads = {}  # Maps beam head position to beam index
        self.beam_tails = {}  # Maps beam tail position to beam index
        self.beam_exit_paths = {}  # Maps beam index to its exit path

    def is_valid(self, r, c):
        return 0 <= r < self.rows and 0 <= c < self.cols

    def get_valid_entries(self):
        """
        Returns (start_r, start_c, virtual_r, virtual_c).
        virtual_* is the off-grid node implying the entry direction.
        """
        entries = []
        for c in range(self.cols):
            entries.append((0, c, -1, c))           # Top
            entries.append((self.rows - 1, c, self.rows, c)) # Bottom
        for r in range(self.rows):
            entries.append((r, 0, r, -1))           # Left
            entries.append((r, self.cols - 1, r, self.cols)) # Right
        return entries

    def are_collinear(self, p1, p2, p3):
        """Checks if three points form a straight line (Safe Head Logic)."""
        (r1, c1), (r2, c2), (r3, c3) = p1, p2, p3
        if c1 == c2 == c3: return True
        if r1 == r2 == r3: return True
        return False

    def check_circular_dependencies(self, new_beam_idx, new_exit_path):
        """
        Checks if adding a new beam would create circular dependencies.
        Returns True if safe, False if it would create a circular dependency.
        """
        # Create a temporary mapping that includes the new beam
        temp_beam_exit_paths = self.beam_exit_paths.copy()
        temp_beam_exit_paths[new_beam_idx] = new_exit_path
        
        # Build a dependency graph
        dependencies = {}
        
        # Initialize all beams with empty dependencies
        for i in range(len(self.beams) + 1):  # +1 for the new beam
            dependencies[i] = set()
        
        # Find dependencies: beam A depends on beam B if B blocks A's exit
        for beam_idx, exit_path in temp_beam_exit_paths.items():
            for r, c in exit_path:
                if self.is_valid(r, c) and (r, c) in self.beam_heads:
                    # This exit path is blocked by another beam's head
                    blocking_beam_idx = self.beam_heads[(r, c)]
                    dependencies[beam_idx].add(blocking_beam_idx)
        
        # Check for circular dependencies using DFS
        visited = set()
        rec_stack = set()
        
        def has_cycle(node):
            visited.add(node)
            rec_stack.add(node)
            
            for neighbor in dependencies[node]:
                if neighbor not in visited:
                    if has_cycle(neighbor):
                        return True
                elif neighbor in rec_stack:
                    return True
            
            rec_stack.remove(node)
            return False
        
        for node in dependencies:
            if node not in visited:
                if has_cycle(node):
                    return False
        
        return True

    def generate_beam_slide_in(self, min_len, max_len):
        entries = self.get_valid_entries()
        random.shuffle(entries)
        
        for start_r, start_c, virt_r, virt_c in entries:
            # Blocked Check
            if (start_r, start_c) in self.occupied or (start_r, start_c) in self.reserved_exits:
                continue

            # 1. Generate Deep Path (Random Walk)
            path = [(virt_r, virt_c), (start_r, start_c)]
            
            current_r, current_c = start_r, start_c
            target_dist = max_len + random.randint(2, 10)
            
            for _ in range(target_dist):
                neighbors = []
                for _, (dr, dc) in DIRECTIONS.items():
                    nr, nc = current_r + dr, current_c + dc
                    if (self.is_valid(nr, nc) and 
                        (nr, nc) not in self.occupied and 
                        (nr, nc) not in self.reserved_exits and
                        (nr, nc) not in path):
                         neighbors.append((nr, nc))
                
                if not neighbors: break
                
                next_r, next_c = random.choice(neighbors)
                path.append((next_r, next_c))
                current_r, current_c = next_r, next_c
            
            # --- CRASH FIX: Check Path Length ---
            actual_path_len = len(path)
            
            # We need space for the snake (min_len) AND the exit node (1 extra).
            # If the path is too short (e.g. hit a dead end immediately), discard it.
            if actual_path_len - 1 < min_len:
                continue

            # 2. Find a Valid Snake Slice
            # We use min() to ensure we don't exceed the actual generated path length
            target_len = random.randint(min_len, min(actual_path_len - 1, max_len))
            
            # Valid start indices for the HEAD
            start_index_limit = actual_path_len - target_len
            
            valid_head_indices = []
            for i in range(1, start_index_limit + 1):
                # HEAD is path[i]. NECK is path[i+1]. EXIT is path[i-1].
                # Collinear check ensures Head points straight to Exit.
                if self.are_collinear(path[i-1], path[i], path[i+1]):
                    valid_head_indices.append(i)
            
            if not valid_head_indices:
                continue 
                
            # Pick deepest valid spot for packing
            head_idx = valid_head_indices[-1] 
            
            # Slice: Head -> Tail (Inwards)
            snake_slice_path = path[head_idx : head_idx + target_len]
            
            # Reverse for JSON: [Tail, ..., Neck, Head]
            final_coords = snake_slice_path[::-1]
            
            # Get the exit path
            exit_path = path[0 : head_idx]
            
            # Check if adding this beam would create circular dependencies
            new_beam_idx = len(self.beams)
            if not self.check_circular_dependencies(new_beam_idx, exit_path):
                continue
            
            color = random_hex_color()
            cells_json = []
            
            for i, (r, c) in enumerate(final_coords):
                cell_type = "path"
                direction = "none"
                
                if i == 0: cell_type = "start"
                if i == len(final_coords) - 1: cell_type = "end"
                
                if i < len(final_coords) - 1:
                    # Body/Tail Direction: Points to NEXT node
                    nr, nc = final_coords[i+1]
                    direction = self.get_direction(r, c, nr, nc)
                else:
                    # HEAD Direction: Derived from PREVIOUS node (End-1)
                    pr, pc = final_coords[i-1]
                    direction = self.get_direction(pr, pc, r, c)
                
                cells_json.append({
                    "row": r, "column": c,
                    "type": cell_type, "direction": direction, "color": color
                })

            self.beams.append(cells_json)
            
            # Occupy Body
            for r, c in snake_slice_path:
                self.occupied.add((r, c))
                
            # Reserve Exit Path
            for r, c in exit_path:
                if self.is_valid(r, c):
                    self.reserved_exits.add((r, c))
            
            # Track beam head and tail positions
            head_r, head_c = final_coords[-1]  # Last element is the head
            tail_r, tail_c = final_coords[0]   # First element is the tail
            self.beam_heads[(head_r, head_c)] = new_beam_idx
            self.beam_tails[(tail_r, tail_c)] = new_beam_idx
            
            # Store the exit path for this beam
            self.beam_exit_paths[new_beam_idx] = exit_path
            
            return True

        return False

    def get_direction(self, r1, c1, r2, c2):
        if r2 > r1: return "down"
        if r2 < r1: return "up"
        if c2 > c1: return "right"
        if c2 < c1: return "left"
        return "none"

# --- Main Execution ---

final_output = {"levels": []}

for cfg in LEVEL_CONFIGS:
    print(f"Generating Level {cfg['id']} ({cfg['rows']}x{cfg['cols']})...")
    grid = Grid(cfg['rows'], cfg['cols'])
    
    total_cells = cfg['rows'] * cfg['cols']
    target_filled = int(total_cells * cfg['density'])
    
    fails = 0
    while len(grid.occupied) < target_filled and fails < 10000:
        success = grid.generate_beam_slide_in(cfg['min_len'], cfg['max_len'])
        if not success:
            fails += 1
        else:
            fails = 0
    if fails>999:
        print("fail exist")        
    random.shuffle(grid.beams)
    
    all_cells = []
    for beam in grid.beams:
        all_cells.extend(beam)
        
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
        "difficulty": cfg['hearts'],
        "cells": all_cells
    })
    print(f"  - Done. {len(grid.beams)} beams.")

with open("levels.json", "w") as f:
    json.dump(final_output, f, indent=2)

print("✅ Success! Fixed circular dependency issue.")