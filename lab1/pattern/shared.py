import random
from pathlib import Path
from dataclasses import dataclass
from typing import List, Tuple, Optional

@dataclass(frozen=True)
class Rect:
    layer: int
    x1: int
    y1: int
    x2: int
    y2: int
    
    def w(self) -> int:
        return self.x2 - self.x1

    def h(self) -> int:
        return self.y2 - self.y1

def generate_random_rect(layer: int) -> Rect:
    x1 = random.randint(0, 14)
    y1 = random.randint(0, 14)
    x2 = random.randint(x1 + 1, 15)
    y2 = random.randint(y1 + 1, 15)

    return Rect(layer, x1, y1, x2, y2)

@dataclass(frozen=False)
class Testcase:
    golden_out: int
    drc_sel: int
    rects: List[Rect]

def generate_testcase(sel_layer_count: int = 8) -> Testcase:
    drc_sel = random.randint(0, 13)
    rects = []

    sel_layer = (drc_sel // 2 + 1)
    for i in range(16):
        layer = sel_layer
        while (i >= sel_layer_count) and (layer == sel_layer): # generate non-sel-layer
            layer = random.randint(0, 7)
        
        rect = generate_random_rect(layer)
        while (rect.layer == 7) and (rect.w() < 2 or rect.h() < 2):
            rect = generate_random_rect(layer)

        rects.append(rect)
    
    random.shuffle(rects)
    return Testcase(-1, drc_sel, rects)

def solve_testcase(testcase: Testcase, debug: bool = False):
    sel_layer = (testcase.drc_sel // 2 + 1)

    image = [[0] * 17 for i in range(17)]
    for rect in testcase.rects:
        if rect.layer != sel_layer:
            continue

        if debug:
            print(rect)
        
        for i in range(16):
            for j in range(16):
                if (rect.x1 <= i) and (i < rect.x2) and (rect.y1 <= j) and (j < rect.y2):
                    image[i + 1][j + 1] |= 1
    
    if debug:
        for line in image:
            print(line)
    
    # Find borders
    upper_borders = []
    lower_borders = []

    for i in range(1, 17):
        run_start = None
        for j in range(17):
            if (image[i - 1][j] == 0 and image[i][j] == 1):
                if run_start is None:
                    run_start = j
            else:
                if run_start is not None:
                    upper_borders.append((i, run_start, j - 1))
                    run_start = None

    for i in range(0, 16):
        run_start = None
        for j in range(17):
            if (image[i + 1][j] == 0 and image[i][j] == 1):
                if run_start is None:
                    run_start = j
            else:
                if run_start is not None:
                    lower_borders.append((i, run_start, j - 1))
                    run_start = None

    left_borders = []
    right_borders = []

    for j in range(1, 17):
        run_start = None
        for i in range(17):
            if (image[i][j - 1] == 0 and image[i][j] == 1):
                if run_start is None:
                    run_start = i
            else:
                if run_start is not None:
                    left_borders.append((j, run_start, i - 1))
                    run_start = None

    for j in range(0, 16):
        run_start = None
        for i in range(17):
            if (image[i][j + 1] == 0 and image[i][j] == 1):
                if run_start is None:
                    run_start = i
            else:
                if run_start is not None:
                    right_borders.append((j, run_start, i - 1))
                    run_start = None
    
    if debug:
        print("Border upper / lower / left / right")
        print(upper_borders)
        print(lower_borders)
        print(left_borders)
        print(right_borders)

    # Find violations
    mode = testcase.drc_sel % 2 # 0 = Width, 1 = Spacing
    max_width = [2, 2, 3, 2, 2, 2, 3, 2, 4, 3, 4, 3, 5, 4][testcase.drc_sel]

    violations = 0
    if debug:           
        print("mode: ", mode, ", width: ", max_width)
    # horizontals
    for upper in upper_borders:
        for lower in lower_borders:
            # check intersect
            if (upper[1] <= lower[2]) and (lower[1] <= upper[2]):
                diff = (lower[0] - upper[0] + 1) if (mode == 0) else (upper[0] - lower[0] - 1)
                
                if not((0 < diff) and (diff < max_width)):
                    continue
                
                # check region is connected
                valid = False
                for j in range(max(upper[1], lower[1]), min(upper[2], lower[2]) + 1):
                    line_valid = True
                    if mode == 0: # check connect by 1s
                        for i in range(upper[0], lower[0] + 1):
                            if image[i][j] != 1:
                                line_valid = False
                    # Note: These cases are ignored by the TA pattern                    
                    else: # check connect by 0s
                        for i in range(lower[0] + 1, upper[0]):
                            if image[i][j] != 0:
                                line_valid = False
                    if line_valid:
                        valid = True
                        break
                
                if not valid:
                    continue

                violations += 1
                if debug:
                    print("hori", upper, lower)
    # verticals
    for left in left_borders:
        for right in right_borders:
            # check intersect
            if (left[1] <= right[2]) and (right[1] <= left[2]):
                diff = (right[0] - left[0] + 1) if (mode == 0) else (left[0] - right[0] - 1)
                
                if not((0 < diff) and (diff < max_width)):
                    continue

                # check region is connected
                valid = False
                for i in range(max(left[1], right[1]), min(left[2], right[2]) + 1):
                    line_valid = True
                    if mode == 0: # check connect by 1s
                        for j in range(left[0], right[0] + 1):
                            if image[i][j] != 1:
                                line_valid = False
                    # Note: These cases are ignored by the TA pattern     
                    else: # check connect by 0s
                        for j in range(right[0] + 1, left[0]):
                            if image[i][j] != 0:
                                line_valid = False
                    if line_valid:
                        valid = True
                        break
                
                if not valid:
                    continue

                violations += 1
                if debug:
                    print("vert", left, right)      

    testcase.golden_out = violations