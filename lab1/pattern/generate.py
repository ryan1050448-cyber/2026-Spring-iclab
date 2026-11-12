from shared import *
from collections import defaultdict

def main(total_case: int, filepath: Path):
    testcases = []
    cases = defaultdict(int)

    for i in range(total_case):
        #sel_layer = i * 9 // total_case
        sel_layer = int(9 * (i / total_case) ** 0.5)

        cases[sel_layer] += 1
        testcase = generate_testcase(sel_layer)
        solve_testcase(testcase)

        testcases.append(testcase)

        #print("---------------------------------------")

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(f"{len(testcases)}\n")

        for testcase in testcases:
            f.write("\n")
            f.write(f"{testcase.golden_out}\n")
            f.write(f"{testcase.drc_sel}\n")

            for r in testcase.rects:
                f.write(f"{r.layer} {r.x1} {r.y1} {r.x2} {r.y2}\n")

    print("generated cases:")
    print(dict(cases))

if __name__ == "__main__":
    main(
        total_case = 3000,
        filepath = Path("input.txt")
    )