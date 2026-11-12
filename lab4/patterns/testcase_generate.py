import numpy as np
import struct
from pathlib import Path

PAD_ZERO = 0
PAD_REPLICATION = 1

ACT_SIGMOID = 0
ACT_TANH = 1
ACT_RELU = 2
ACT_LEAKY_RELU = 3

OUTPUT_DIR = Path(".")
OUT_DIR = Path("./out")
OUT_DIR.mkdir(parents=True, exist_ok=True)


def float_to_hex(value: float) -> str:
    value32 = np.float32(value)
    bits = struct.unpack(">I", struct.pack(">f", float(value32)))[0]
    return f"{bits:08X}"


def hex_to_float32(hex_str):
    u = np.uint32(int(hex_str, 16))
    return u.view(np.float32)


def apply_activation(x: np.ndarray, act_type: int) -> np.ndarray:
    x = x.astype(np.float32)
    if act_type == ACT_SIGMOID:
        return (1.0 / (1.0 + np.exp(-x, dtype=np.float32))).astype(np.float32)
    if act_type == ACT_TANH:
        return np.tanh(x).astype(np.float32)
    if act_type == ACT_RELU:
        return np.maximum(x, np.float32(0.0)).astype(np.float32)
    if act_type == ACT_LEAKY_RELU:
        threshold = np.float32(-(2 ** -123))
        alpha = np.float32(0.125)
        return np.where(
            x > 0,
            x,
            np.where(x > threshold, np.float32(0.0), alpha * x)
        ).astype(np.float32)
    raise ValueError("Unknown activation type")


def pad_image(image: np.ndarray, pad_width: int, pad_type: int) -> np.ndarray:
    mode = "constant" if pad_type == PAD_ZERO else "edge"
    if mode == "constant":
        return np.pad(
            image,
            ((0, 0), (pad_width, pad_width), (pad_width, pad_width)),
            mode=mode,
            constant_values=0.0,
        ).astype(np.float32)
    return np.pad(
        image,
        ((0, 0), (pad_width, pad_width), (pad_width, pad_width)),
        mode=mode,
    ).astype(np.float32)


def apply_padding(x, pad, pad_type):
    if pad_type == PAD_ZERO:
        return np.pad(
            x,
            ((0, 0), (pad, pad), (pad, pad)),
            mode="constant",
            constant_values=0
        ).astype(np.float32)
    else:
        return np.pad(
            x,
            ((0, 0), (pad, pad), (pad, pad)),
            mode="edge"
        ).astype(np.float32)


def min_max_scale_per_channel(image: np.ndarray) -> np.ndarray:
    out = np.empty_like(image, dtype=np.float32)
    for c in range(image.shape[0]):
        channel = image[c].astype(np.float32)
        cmin = np.min(channel)
        cmax = np.max(channel)
        if float(cmax - cmin) == 0.0:
            out[c] = np.zeros_like(channel, dtype=np.float32)
        else:
            out[c] = ((channel - cmin) / (cmax - cmin)).astype(np.float32)
    return out


def conv2d_same(image: np.ndarray, weight: np.ndarray, pad_type: int) -> np.ndarray:
    # image: [in_c, h, w]
    # weight: [out_c, in_c, 3, 3]
    in_c, h, w = image.shape
    out_c = weight.shape[0]
    padded = pad_image(image, 1, pad_type)
    out = np.zeros((out_c, h, w), dtype=np.float32)

    for oc in range(out_c):
        for ic in range(in_c):
            for i in range(h):
                for j in range(w):
                    region = padded[ic, i:i + 3, j:j + 3]
                    out[oc, i, j] += np.sum(region * weight[oc, ic], dtype=np.float32)
    return out.astype(np.float32)


def transposed_conv2d_same(image: np.ndarray, weight: np.ndarray, pad_type: int) -> np.ndarray:
    in_c, h, w = image.shape
    out_c = weight.shape[0]
    out = np.zeros((out_c, h, w), dtype=np.float32)

    for ic in range(in_c):
        for i in range(h):
            for j in range(w):
                val = np.float32(image[ic, i, j])
                for oc in range(out_c):
                    for kh in range(3):
                        for kw in range(3):
                            oi = i + kh - 1
                            oj = j + kw - 1
                            if 0 <= oi < h and 0 <= oj < w:
                                out[oc, oi, oj] += np.float32(val * weight[oc, ic, kh, kw])
    return out.astype(np.float32)


def max_pool_2x2_unique(image: np.ndarray):
    # image: [c, h, w], h and w even
    c, h, w = image.shape
    pooled = np.zeros((c, h // 2, w // 2), dtype=np.float32)
    mask = np.zeros_like(image, dtype=np.float32)

    for ch in range(c):
        for i in range(0, h, 2):
            for j in range(0, w, 2):
                window = image[ch, i:i + 2, j:j + 2].astype(np.float32)
                flat = window.reshape(-1)
                max_val = np.max(flat)
                max_positions = np.where(flat == max_val)[0]
                if len(max_positions) != 1:
                    return None, None, False
                idx = int(max_positions[0])
                pooled[ch, i // 2, j // 2] = max_val
                mask[ch, i + idx // 2, j + idx % 2] = np.float32(1.0)

    return pooled, mask, True


def unpool_2x2(pooled: np.ndarray, mask: np.ndarray) -> np.ndarray:
    # pooled: [c, h, w]
    # mask: [c, 2h, 2w]
    c, h, w = pooled.shape
    out = np.zeros_like(mask, dtype=np.float32)
    for ch in range(c):
        for i in range(h):
            for j in range(w):
                window_mask = mask[ch, 2 * i:2 * i + 2, 2 * j:2 * j + 2]
                positions = np.argwhere(window_mask == 1.0)
                if positions.shape[0] != 1:
                    raise ValueError("Unpooling mask is invalid.")
                di, dj = positions[0]
                out[ch, 2 * i + di, 2 * j + dj] = pooled[ch, i, j]
    return out.astype(np.float32)


def save_tensor_hex(path: Path, tensor: np.ndarray):
    tensor = tensor.astype(np.float32)
    with path.open("w", encoding="utf-8") as f:
        if tensor.ndim == 3:
            for c in range(tensor.shape[0]):
                for row in tensor[c]:
                    f.write(" ".join(float_to_hex(v) for v in row) + "\n")
                if c != tensor.shape[0] - 1:
                    f.write("\n")
        elif tensor.ndim == 4:
            first = True
            for a in range(tensor.shape[0]):
                for b in range(tensor.shape[1]):
                    if not first:
                        f.write("\n")
                    first = False
                    for row in tensor[a, b]:
                        f.write(" ".join(float_to_hex(v) for v in row) + "\n")
        else:
            raise ValueError("Unsupported tensor dimension for text export.")


def write_one_case(f, pad_type: int, act_type: int, weights: np.ndarray, image: np.ndarray):
    f.write(f"{pad_type}\n")
    f.write(f"{act_type}\n")

    for layer in range(weights.shape[0]):
        for oc in range(weights.shape[1]):
            for ic in range(weights.shape[2]):
                kernel = weights[layer, oc, ic]
                for row in kernel:
                    f.write(" ".join(float_to_hex(v) for v in row) + "\n")

    for ch in range(image.shape[0]):
        for row in image[ch]:
            f.write(" ".join(float_to_hex(v) for v in row) + "\n")


def save_testcases(path: Path, cases: list):
    with path.open("w", encoding="utf-8") as f:
        for idx, case in enumerate(cases):
            write_one_case(
                f,
                case["pad_type"],
                case["act_type"],
                case["weights"],
                case["image"]
            )
            if idx != len(cases) - 1:
                f.write("\n\n")


def save_multi_tensor_hex(path: Path, tensors: list):
    with path.open("w", encoding="utf-8") as f:
        for idx, tensor in enumerate(tensors):
            tensor = tensor.astype(np.float32)
            if tensor.ndim != 3:
                raise ValueError("save_multi_tensor_hex only supports 3D tensors.")
            for c in range(tensor.shape[0]):
                for row in tensor[c]:
                    f.write(" ".join(float_to_hex(v) for v in row) + "\n")
                if c != tensor.shape[0] - 1:
                    f.write("\n")
            if idx != len(tensors) - 1:
                f.write("\n\n")


def _parse_int_line(s: str) -> int:
    s = s.strip()
    if s.lower().startswith("0x"):
        return int(s, 16)
    if any(c in s.upper() for c in "ABCDEF"):
        return int(s, 16)
    return int(s)


def _split_cases_by_blank_lines(lines):
    blocks = []
    current = []

    for line in lines:
        if line.strip() == "":
            if current:
                blocks.append(current)
                current = []
        else:
            current.append(line.strip())

    if current:
        blocks.append(current)

    return blocks


def load_case_from_txt(filename):
    cases = load_cases_from_txt(filename)
    if len(cases) == 0:
        raise ValueError("檔案中沒有任何 case")
    return (
        cases[0]["pad_type"],
        cases[0]["act_type"],
        cases[0]["weights"],
        cases[0]["image"],
    )


def load_cases_from_txt(filename):
    with open(filename, "r", encoding="utf-8") as f:
        raw_lines = f.readlines()

    blocks = _split_cases_by_blank_lines(raw_lines)

    expected_weights = 4 * 2 * 2 * 3 * 3
    expected_image = 2 * 8 * 8
    expected_total = expected_weights + expected_image

    cases = []

    for case_idx, block in enumerate(blocks):
        if len(block) < 3:
            raise ValueError(f"第 {case_idx} 筆 case 行數太少，無法解析")

        pad_type = _parse_int_line(block[0])
        act_type = _parse_int_line(block[1])

        hex_tokens = []
        for line in block[2:]:
            hex_tokens.extend(line.split())

        if len(hex_tokens) != expected_total:
            raise ValueError(
                f"第 {case_idx} 筆 case 的 hex 數量錯誤，"
                f"預期 {expected_total} 個，實際 {len(hex_tokens)} 個"
            )

        float_vals = np.array([hex_to_float32(x) for x in hex_tokens], dtype=np.float32)

        weights = float_vals[:expected_weights].reshape(4, 2, 2, 3, 3)
        image = float_vals[expected_weights:expected_total].reshape(2, 8, 8)

        cases.append({
            "pad_type": pad_type,
            "act_type": act_type,
            "weights": weights,
            "image": image,
        })

    return cases


def generate_case(rng):
    pad_type = int(rng.randint(0, 2))
    act_type = int(rng.randint(0, 4))

    weights = rng.uniform(-1.0, 1.0, size=(4, 2, 2, 3, 3)).astype(np.float32)
    image = rng.uniform(-127.0, 128.0, size=(2, 8, 8)).astype(np.float32)

    scaled = min_max_scale_per_channel(image)
    pad = 1
    scaled_padded = apply_padding(scaled, pad, pad_type)

    conv0 = conv2d_same(scaled, weights[0], pad_type)
    pool0, mask0, ok0 = max_pool_2x2_unique(conv0)
    if not ok0:
        return None

    act0 = apply_activation(pool0, act_type)
    act0_padded = apply_padding(act0, pad, pad_type)

    conv1 = conv2d_same(act0, weights[1], pad_type)
    pool1, mask1, ok1 = max_pool_2x2_unique(conv1)
    if not ok1:
        return None

    act1 = apply_activation(pool1, act_type)

    unpool2 = unpool_2x2(act1, mask1)
    deconv2 = conv2d_same(unpool2, weights[2], pad_type)
    act2 = apply_activation(deconv2, act_type)

    unpool3 = unpool_2x2(act2, mask0)
    deconv3 = conv2d_same(unpool3, weights[3], pad_type)
    act3 = apply_activation(deconv3, act_type)

    return {
        "pad_type": pad_type,
        "act_type": act_type,
        "weights": weights,
        "image": image,
        "scaled": scaled,
        "scaled_padding": scaled_padded,
        "after_conv0": conv0,
        "after_pooling0": pool0,
        "after_activation0": act0,
        "after_act0_padding": act0_padded,
        "after_conv1": conv1,
        "after_pooling1": pool1,
        "after_activation1": act1,
        "act1_mask": mask1,
        "unpool2": unpool2,
        "deconv2": deconv2,
        "after_activation2": act2,
        "unpool3": unpool3,
        "deconv3": deconv3,
        "after_activation3": act3,
    }


def run_case(case):
    pad_type = case["pad_type"]
    act_type = case["act_type"]
    weights = case["weights"]
    image = case["image"]

    scaled = min_max_scale_per_channel(image)
    pad = 1
    scaled_padded = apply_padding(scaled, pad, pad_type)

    conv0 = conv2d_same(scaled, weights[0], pad_type)
    pool0, mask0, ok0 = max_pool_2x2_unique(conv0)
    if not ok0:
        raise RuntimeError("Failed at pooling0: max is not unique.")

    act0 = apply_activation(pool0, act_type)
    act0_padded = apply_padding(act0, pad, pad_type)

    conv1 = conv2d_same(act0, weights[1], pad_type)
    pool1, mask1, ok1 = max_pool_2x2_unique(conv1)
    if not ok1:
        raise RuntimeError("Failed at pooling1: max is not unique.")

    act1 = apply_activation(pool1, act_type)

    unpool2 = unpool_2x2(act1, mask1)
    deconv2 = conv2d_same(unpool2, weights[2], pad_type)
    act2 = apply_activation(deconv2, act_type)

    unpool3 = unpool_2x2(act2, mask0)
    deconv3 = conv2d_same(unpool3, weights[3], pad_type)
    act3 = apply_activation(deconv3, act_type)

    return {
        "pad_type": pad_type,
        "act_type": act_type,
        "weights": weights,
        "image": image,
        "scaled": scaled,
        "scaled_padding": scaled_padded,
        "after_conv0": conv0,
        "after_pooling0": pool0,
        "after_activation0": act0,
        "after_act0_padding": act0_padded,
        "after_conv1": conv1,
        "after_pooling1": pool1,
        "after_activation1": act1,
        "act1_mask": mask1,
        "unpool2": unpool2,
        "deconv2": deconv2,
        "after_activation2": act2,
        "unpool3": unpool3,
        "deconv3": deconv3,
        "after_activation3": act3,
    }


def save_case_outputs(case_result, out_dir: Path, prefix: str = ""):
    prefix = f"{prefix}_" if prefix else ""

    save_tensor_hex(out_dir / f"{prefix}min_max.txt", case_result["scaled"])
    save_tensor_hex(out_dir / f"{prefix}scaled_padding.txt", case_result["scaled_padding"])
    save_tensor_hex(out_dir / f"{prefix}after_conv0.txt", case_result["after_conv0"])
    save_tensor_hex(out_dir / f"{prefix}after_pooling0.txt", case_result["after_pooling0"])
    save_tensor_hex(out_dir / f"{prefix}after_activation0.txt", case_result["after_activation0"])
    save_tensor_hex(out_dir / f"{prefix}after_act0_padding.txt", case_result["after_act0_padding"])
    save_tensor_hex(out_dir / f"{prefix}after_conv1.txt", case_result["after_conv1"])
    save_tensor_hex(out_dir / f"{prefix}after_pooling1.txt", case_result["after_pooling1"])
    save_tensor_hex(out_dir / f"{prefix}after_activation1.txt", case_result["after_activation1"])
    save_tensor_hex(out_dir / f"{prefix}act1_mask.txt", case_result["act1_mask"])
    save_tensor_hex(out_dir / f"{prefix}unpool2.txt", case_result["unpool2"])
    save_tensor_hex(out_dir / f"{prefix}deconv2.txt", case_result["deconv2"])
    save_tensor_hex(out_dir / f"{prefix}after_activation2.txt", case_result["after_activation2"])
    save_tensor_hex(out_dir / f"{prefix}unpool3.txt", case_result["unpool3"])
    save_tensor_hex(out_dir / f"{prefix}deconv3.txt", case_result["deconv3"])
    # 注意：after_activation3 不在這裡存單筆，改成最後集中存 multi-case


def main():
    seed = None
    rng = np.random.RandomState(seed)

    num_cases = 3000
    max_attempts_per_case = 1000

    cases = []
    results = []

    for case_idx in range(num_cases):
        case = None
        for _ in range(max_attempts_per_case):
            case = generate_case(rng)
            if case is not None:
                break
        if case is None:
            raise RuntimeError(f"Failed to generate valid case {case_idx}")

        cases.append(case)

        result = run_case(case)
        results.append(result)

        # save_case_outputs(result, OUT_DIR, prefix=f"case{case_idx}")
        # print(
        #     f"case{case_idx}: "
        #     f"pad_type={result['pad_type']} "
        #     f"act_type={result['act_type']}"
        # )

    save_testcases(OUTPUT_DIR / "testcase.txt", cases)
    save_multi_tensor_hex(
        OUTPUT_DIR / "golden.txt",
        [r["after_activation3"] for r in results]
    )

    print(f"Generated {len(cases)} cases into testcase.txt")
    print("Generated multi-case final output: golden.txt")
    print(f"Intermediate outputs are saved in: {OUT_DIR.resolve()}")


if __name__ == "__main__":
    main()