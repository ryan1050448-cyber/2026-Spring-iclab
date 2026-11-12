from shared import *

def read_testcases_from_file(filepath: Path) -> List[Testcase]:
    testcases = []

    with open(filepath, "r") as f:
        lines = [line.strip() for line in f if line.strip()]

    filter(None, lines)

    idx = 0
    num_patterns = int(lines[idx])
    idx += 1

    for _ in range(num_patterns):
        golden_out = int(lines[idx])
        idx += 1

        drc_sel = int(lines[idx])
        idx += 1

        rects = []
        for _ in range(16):
            layer, x1, y1, x2, y2 = map(int, lines[idx].split())
            rects.append(Rect(layer, x1, y1, x2, y2))
            idx += 1

        testcases.append(Testcase(golden_out, drc_sel, rects))

    return testcases

def main(filepath: Path):
    testcases = read_testcases_from_file(filepath)

    # Example usage: iterate through testcases
    for i, testcase in enumerate(testcases):
        golden = testcase.golden_out
        solve_testcase(testcase, False)
        #solve2(testcase, False)
        solver = testcase.golden_out

        if golden == solver:
            print(f"Pass testcase {i}, answer = {golden}")
        else:
            print(f"Fail testcase {i}, golden = {golden}, solver = {solver}")
            
            print("DRC rule:", testcase.drc_sel)
            for r in testcase.rects:
                print(r)

            print()

            solve_testcase(testcase, True)

            break
    

if __name__ == "__main__":
    main(
        filepath = Path("input_50000.txt")
    )