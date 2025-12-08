import json
import random
from dataclasses import dataclass
from typing import List, Dict, Optional, Tuple, Set

# --- Configuration ---
LEVEL_CONFIGS = [
    {"id": 1, "rows": 8, "cols": 8, "num_beams": 4, "min_len": 3, "max_len": 6, "difficulty": 3},
    {"id": 2, "rows": 10, "cols": 10, "num_beams": 6, "min_len": 4, "max_len": 8, "difficulty": 3},
    {"id": 3, "rows": 15, "cols": 15, "num_beams": 10, "min_len": 4, "max_len": 12, "difficulty": 4},
    {"id": 4, "rows": 20, "cols": 20, "num_beams": 14, "min_len": 5, "max_len": 15, "difficulty": 4},
    {"id": 5, "rows": 25, "cols": 25, "num_beams": 18, "min_len": 6, "max_len": 18, "difficulty": 5},
]

DIRECTIONS = {
    "right": (0, 1),
    "left": (0, -1),
    "down": (1, 0),
    "up": (-1, 0)
}

# --- Data Structures ---

@dataclass
class Beam:
    id: int
    color: str
    path: List[Tuple[int, int]]  # The cells occupied by the beam, from start to end

# --- Level Generator Class ---

class LevelGenerator:
    def __init__(self, rows: int, cols: int, num_beams: int, min_len: int, max_len: int):
        self.rows = rows
        self.cols = cols
        self.num_beams = num_beams
        self.min_len = min_len
        self.max_len = max_len
        
        self.grid: Dict[Tuple[int, int], int] = {}  # Maps (r, c) -> beam_id
        self.beams: Dict[int, Beam] = {}
        self.dependencies: Dict[int, Optional[int]] = {} # Maps beam_id -> beam_id it points to
        self.next_beam_id = 0

    def generate(self) -> Dict:
        """Main method to generate the level."""
        attempts = 0
        while len(self.beams) < self.num_beams and attempts < self.num_beams * 50:
            if self._try_to_place_beam():
                # Success, reset attempts counter
                attempts = 0
            else:
                # Failed to place a beam, increment attempts
                attempts += 1
        
        if len(self.beams) < self.num_beams:
            print(f"Warning: Could only place {len(self.beams)} out of {self.num_beams} beams.")
            
        return self._to_json()

    def _get_random_color(self):
        """Generates distinct neon colors."""
        r = random.randint(50, 255)
        g = random.randint(50, 255)
        b = random.randint(50, 255)
        # Boost saturation
        if random.random() < 0.33: r = 255
        elif random.random() < 0.5: g = 255
        else: b = 255
        return f"#{r:02X}{g:02X}{b:02X}"

    def _get_direction(self, p1: Tuple[int, int], p2: Tuple[int, int]) -> str:
        dr, dc = p2[0] - p1[0], p2[1] - p1[1]
        if dr > 0: return "down"
        if dr < 0: return "up"
        if dc > 0: return "right"
        if dc < 0: return "left"
        return "none"

    def _try_to_place_beam(self) -> bool:
        """Attempts to find a valid spot and configuration for a new beam."""
        beam_id = self.next_beam_id
        color = self._get_random_color()

        # 1. Generate a candidate beam path using a random walk from the edge
        path, head_pos, head_dir = self._generate_random_walk_beam()
        if not path:
            return False

        # 2. Find the target beam that this new beam points to
        target_beam_id = self._find_target_beam(head_pos, head_dir)

        # 3. Check for circular dependencies using the robust algorithm
        if self._check_for_cycle(beam_id, target_beam_id):
            return False # This configuration creates a cycle, discard it

        # 4. Place the beam (it's valid!)
        self._place_beam(beam_id, color, path, target_beam_id)
        self.next_beam_id += 1
        return True

    def _generate_random_walk_beam(self) -> Tuple[Optional[List[Tuple[int, int]]], Optional[Tuple[int, int]], Optional[str]]:
        """Generates a beam path that slides in from the edge."""
        entries = []
        for c in range(self.cols): entries.append((0, c, "down"))
        for c in range(self.cols): entries.append((self.rows - 1, c, "up"))
        for r in range(self.rows): entries.append((r, 0, "right"))
        for r in range(self.rows): entries.append((r, self.cols - 1, "left"))
        random.shuffle(entries)

        for start_r, start_c, start_dir in entries:
            if (start_r, start_c) in self.grid:
                continue

            path = [(start_r, start_c)]
            current_r, current_c = start_r, start_c
            target_len = random.randint(self.min_len, self.max_len)

            for _ in range(target_len - 1):
                neighbors = []
                for dir_name, (dr, dc) in DIRECTIONS.items():
                    nr, nc = current_r + dr, current_c + dc
                    if (0 <= nr < self.rows and 0 <= nc < self.cols and
                        (nr, nc) not in self.grid and (nr, nc) not in path):
                        neighbors.append((nr, nc, dir_name))
                
                if not neighbors: break
                next_r, next_c, _ = random.choice(neighbors)
                path.append((next_r, next_c))
                current_r, current_c = next_r, next_c
            
            if len(path) >= self.min_len:
                head_pos = path[-1]
                neck_pos = path[-2]
                head_dir = self._get_direction(neck_pos, head_pos)
                return path, head_pos, head_dir
        
        return None, None, None

    def _find_target_beam(self, start_pos: Tuple[int, int], direction: str) -> Optional[int]:
        """Finds the first beam head in the given direction."""
        dr, dc = DIRECTIONS[direction]
        r, c = start_pos
        
        while 0 <= r < self.rows and 0 <= c < self.cols:
            if (r, c) in self.grid:
                # We found a beam. Check if this cell is its head.
                beam_id = self.grid[(r, c)]
                beam_path = self.beams[beam_id].path
                if (r, c) == beam_path[-1]: # It's the head
                    return beam_id
            r += dr
            c += dc
            
        return None # No beam head found in this direction

    def _check_for_cycle(self, new_beam_id: int, current_beam_id: Optional[int]) -> bool:
        """
        Recursively checks if a path from current_beam_id leads back to new_beam_id.
        Returns True if a cycle is detected.
        """
        if current_beam_id is None:
            return False # Path leads to empty space, no cycle
        
        if current_beam_id == new_beam_id:
            return True # Cycle detected!
        
        # Recurse with the beam that current_beam_id points to
        next_beam_id = self.dependencies.get(current_beam_id)
        return self._check_for_cycle(new_beam_id, next_beam_id)

    def _place_beam(self, beam_id: int, color: str, path: List[Tuple[int, int]], target_beam_id: Optional[int]):
        """Places a valid beam on the grid and updates data structures."""
        self.beams[beam_id] = Beam(id=beam_id, color=color, path=path)
        for cell in path:
            self.grid[cell] = beam_id
        self.dependencies[beam_id] = target_beam_id

    def _to_json(self) -> Dict:
        """Converts the internal state to the desired JSON format."""
        all_cells = []
        
        # Process all beams first
        for beam in self.beams.values():
            path = beam.path
            for i, (r, c) in enumerate(path):
                cell_type = "path"
                if i == 0: cell_type = "start"
                if i == len(path) - 1: cell_type = "end"

                # Direction is from current cell to the next cell in the path
                direction = self._get_direction((r, c), path[i+1]) if i < len(path) - 1 else "none"
                
                all_cells.append({
                    "row": r, "column": c,
                    "type": cell_type, "direction": direction, "color": beam.color
                })

        # Add empty cells
        for r in range(self.rows):
            for c in range(self.cols):
                if (r, c) not in self.grid:
                    all_cells.append({
                        "row": r, "column": c,
                        "type": "empty", "direction": "none", "color": ""
                    })
        
        # Sort cells by row and column for consistent output
        all_cells.sort(key=lambda x: (x['row'], x['column']))

        return {
            "levelNumber": 0, # This will be set in the main loop
            "gridSize": {"rows": self.rows, "columns": self.cols},
            "difficulty": 0, # This will be set in the main loop
            "cells": all_cells
        }

# --- Main Execution ---

if __name__ == "__main__":
    final_output = {"levels": []}

    for cfg in LEVEL_CONFIGS:
        print(f"Generating Level {cfg['id']} ({cfg['rows']}x{cfg['cols']})...")
        
        generator = LevelGenerator(
            rows=cfg['rows'], 
            cols=cfg['cols'], 
            num_beams=cfg['num_beams'],
            min_len=cfg['min_len'],
            max_len=cfg['max_len']
        )
        
        level_json = generator.generate()
        level_json['levelNumber'] = cfg['id']
        level_json['difficulty'] = cfg['difficulty']
        
        final_output["levels"].append(level_json)
        print(f"  - Done. {len(generator.beams)} beams placed.")

    with open("levels.json", "w") as f:
        json.dump(final_output, f, indent=2)

    print("✅ Success! Levels generated with correct algorithm and JSON format.")