def solve_laser_optimal(pattern_name, points):
    """
    Input: points is a list of (x, y) tuples.
    Output: Prints the maximum coverage count and all optimal center combinations for the pattern.
    """
    # 1. Define grid size and radius parameters
    # [cite_start]The grid is 16x16 [cite: 55][cite_start], and the radius is 4[cite: 56].
    GRID_SIZE = 16
    RADIUS_SQ = 16  # r=4, r^2=16

    # 2. Pre-compute which target point indices are covered by each possible center (cx, cy)
    # This avoids repetitive distance calculations in the nested loops, significantly improving speed.
    possible_centers = [(x, y) for x in range(GRID_SIZE) for y in range(GRID_SIZE)]
    center_coverage = []

    for cx, cy in possible_centers:
        covered_indices = set()
        for idx, (px, py) in enumerate(points):
            # Distance formula check: (x-cx)^2 + (y-cy)^2 <= 16
            # [cite_start]Note: The problem states that a distance exactly equal to 4 is considered inside the circle[cite: 110].
            dist_sq = (px - cx)**2 + (py - cy)**2
            if dist_sq <= RADIUS_SQ:
                covered_indices.add(idx)
        center_coverage.append({
            'center': (cx, cy),
            'covered': covered_indices
        })

    # 3. Enumerate all combinations of two circle centers (Brute Force)
    # Total combinations are approx. 256*256/2 = 32,768, which computes very quickly.
    max_covered_count = -1
    best_solutions = []

    num_centers = len(possible_centers)
    
    print(f"Calculating all combinations for {pattern_name}, please wait...")
    
    for i in range(num_centers):
        c1_data = center_coverage[i]
        
        # To avoid duplicates, (C1, C2) and (C2, C1) are treated as the same; 
        # therefore, the inner loop starts from i.
        for j in range(i, num_centers):
            c2_data = center_coverage[j]
            
            # Use set union to calculate how many unique points are covered by the two circles
            union_set = c1_data['covered'] | c2_data['covered']
            current_count = len(union_set)

            if current_count > max_covered_count:
                max_covered_count = current_count
                best_solutions = [(c1_data['center'], c2_data['center'])]
            elif current_count == max_covered_count:
                best_solutions.append((c1_data['center'], c2_data['center']))

    # 4. Output statistical results
    print(f"\n======== {pattern_name} Analysis Results ========")
    print(f"Total Target Points: {len(points)}")
    print(f"Maximum Coverage Count (Golden Answer): {max_covered_count}")
    print(f"Found {len(best_solutions)} optimal center coordinate pairs (C1, C2) achieving this coverage:")
    print("-" * 50)
    
    # List all solutions
    for idx, sol in enumerate(best_solutions):
        c1, c2 = sol
        print(f"  Solution {idx+1}: C1={c1}, C2={c2}")
    
    print("-" * 50)
    print("Note: The problem allows any one of the optimal solutions. Your hardware circuit only needs to output one of them to score.")

# ==========================================
# Data Input Section
# ==========================================

# Pattern 2 Coordinate Data (Transcribed from your uploaded image)
p2_x = [8, 6, 7, 12, 1, 10, 11, 3, 7, 8, 13, 0, 10, 11, 2, 5, 8, 14, 5, 8, 9, 10, 11, 1, 2, 11, 12, 2, 3, 5, 8, 15, 2, 6, 7, 6, 7, 9, 2, 4]
p2_y = [0, 1, 2, 2, 3, 3, 3, 4, 4, 4, 4, 5, 5, 6, 7, 7, 7, 7, 8, 8, 8, 8, 8, 9, 9, 9, 9, 10, 11, 11, 11, 11, 12, 12, 12, 13, 13, 13, 14, 14]

def parse_data(x_list, y_list):
    return list(zip(x_list, y_list))

if __name__ == "__main__":
    # Create point data for Pattern 2
    pattern2_points = parse_data(p2_x, p2_y)
    
    # Execute solver
    solve_laser_optimal("Pattern 2", pattern2_points)