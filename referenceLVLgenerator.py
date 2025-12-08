import json
import random
from dataclasses import dataclass
from typing import List, Dict, Optional, Tuple, Set

# --- Configuration ---
LEVEL_CONFIGS = [
    {"id": 1, "rows": 18, "cols": 18, "num_beams": 20, "min_len": 3, "max_len": 16, "difficulty": 3},
    {"id": 2, "rows": 20, "cols": 20, "num_beams": 40, "min_len": 4, "max_len": 28, "difficulty": 3},
    {"id": 3, "rows": 25, "cols": 25, "num_beams": 50, "min_len": 4, "max_len": 42, "difficulty": 4},
]

DIRECTIONS = {
    "right": (0, 1),
    "left": (0, -1),
    "down": (1, 0),
    "up": (-1, 0)
}

@dataclass
class Beam:
    id: int
    color: str
    path: List[Tuple[int, int]]

class LevelGenerator:
    def __init__(self, rows: int, cols: int, num_beams: int, min_len: int, max_len: int):
        self.rows = rows
        self.cols = cols
        self.num_beams = num_beams
        self.min_len = min_len
        self.max_len = max_len
        
        self.grid: Dict[Tuple[int, int], int] = {}
        self.beams: Dict[int, Beam] = {}
        self.dependencies: Dict[int, Set[int]] = {}
        self.next_beam_id = 0

    def generate(self) -> Dict:
        attempts = 0
        while len(self.beams) < self.num_beams and attempts < self.num_beams * 1000:
            if self._try_to_place_beam():
                attempts = 0
            else:
                attempts += 1
        
        if len(self.beams) < self.num_beams:
            print(f"Warning: Could only place {len(self.beams)} out of {self.num_beams} beams.")
            
        return self._to_json()

    def _get_random_color(self):
        r = random.randint(50, 255)
        g = random.randint(50, 255)
        b = random.randint(50, 255)
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
        beam_id = self.next_beam_id
        color = self._get_random_color()

        path, head_pos, head_dir = self._generate_random_walk_beam()
        if not path:
            return False

        if not self._is_exit_path_clear(path, head_pos, head_dir):
            return False

        # CRITICAL FIX: Find all beams that block the exit path
        blocking_beam_ids = self._find_blocking_beams(path, head_pos, head_dir)

        # Check for cycles with each new dependency
        for blocking_beam_id in blocking_beam_ids:
            if self._check_for_cycle(beam_id, blocking_beam_id):
                return False

        self._place_beam(beam_id, color, path, blocking_beam_ids)
        self.next_beam_id += 1
        return True

    def _generate_random_walk_beam(self) -> Tuple[Optional[List[Tuple[int, int]]], Optional[Tuple[int, int]], Optional[str]]:
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
                        (nr, nc) not in self.grid and
                        (nr, nc) not in path):
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

    def _is_exit_path_clear(self, beam_path: List[Tuple[int, int]], head_pos: Tuple[int, int], head_dir: str) -> bool:
        dr, dc = DIRECTIONS[head_dir]
        r, c = head_pos[0] + dr, head_pos[1] + dc
        
        while 0 <= r < self.rows and 0 <= c < self.cols:
            if (r, c) in self.grid or (r, c) in beam_path:
                return False
            r += dr
            c += dc
            
        return True

    # CRITICAL FIX: This function now correctly identifies ANY blocking beam.
    def _find_blocking_beams(self, new_beam_path: List[Tuple[int, int]], start_pos: Tuple[int, int], direction: str) -> Set[int]:
        blocking_beams = set()
        dr, dc = DIRECTIONS[direction]
        r, c = start_pos[0] + dr, start_pos[1] + dc
        
        while 0 <= r < self.rows and 0 <= c < self.cols:
            # If the cell is occupied by an already-placed beam, it's a blocker.
            if (r, c) in self.grid:
                blocking_beams.add(self.grid[(r, c)])
            
            # If the cell is part of the new beam we are trying to place, its exit is blocked.
            if (r, c) in new_beam_path:
                # This case should be caught by _is_exit_path_clear, but as a safeguard:
                return set() # This is an invalid beam configuration.
            
            r += dr
            c += dc
            
        return blocking_beams

    def _check_for_cycle(self, new_beam_id: int, current_beam_id: int) -> bool:
        if current_beam_id == new_beam_id:
            return True
        
        for next_beam_id in self.dependencies.get(current_beam_id, set()):
            if self._check_for_cycle(new_beam_id, next_beam_id):
                return True
        
        return False

    def _place_beam(self, beam_id: int, color: str, path: List[Tuple[int, int]], blocking_beam_ids: Set[int]):
        self.beams[beam_id] = Beam(id=beam_id, color=color, path=path)
        for cell in path:
            self.grid[cell] = beam_id
        self.dependencies[beam_id] = blocking_beam_ids

    def _to_json(self) -> Dict:
        all_cells = []
        for beam in self.beams.values():
            path = beam.path
            for i, (r, c) in enumerate(path):
                cell_type = "path"
                if i == 0: cell_type = "start"
                if i == len(path) - 1: cell_type = "end"
                direction = self._get_direction((r, c), path[i+1]) if i < len(path) - 1 else "none"
                
                all_cells.append({
                    "row": r, "column": c,
                    "type": cell_type, "direction": direction, "color": beam.color
                })

        for r in range(self.rows):
            for c in range(self.cols):
                if (r, c) not in self.grid:
                    all_cells.append({
                        "row": r, "column": c,
                        "type": "empty", "direction": "none", "color": ""
                    })
        
        all_cells.sort(key=lambda x: (x['row'], x['column']))
        return {
            "levelNumber": 0,
            "gridSize": {"rows": self.rows, "columns": self.cols},
            "difficulty": 0,
            "cells": all_cells
        }

# --- Main Execution ---
if __name__ == "__main__":
    final_output = {"levels": []}
    for cfg in LEVEL_CONFIGS:
        print(f"Generating Level {cfg['id']} ({cfg['rows']}x{cfg['cols']})...")
        generator = LevelGenerator(
            rows=cfg['rows'], cols=cfg['cols'], num_beams=cfg['num_beams'],
            min_len=cfg['min_len'], max_len=cfg['max_len']
        )
        level_json = generator.generate()
        level_json['levelNumber'] = cfg['id']
        level_json['difficulty'] = cfg['difficulty']
        final_output["levels"].append(level_json)
        print(f"  - Done. {len(generator.beams)} beams placed.")

    with open("levels.json", "w") as f:
        json.dump(final_output, f, indent=2)

    print("✅ Success! Levels generated with the TRULY FINAL and CORRECTED logic.")