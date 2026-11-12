import numpy as np
import os
from contextlib import redirect_stdout

np.set_printoptions(threshold=np.inf, linewidth=200, formatter={'int':hex})

def read_gain_map(filename):
    """讀取獨立的 LSC Gain Map 檔案 (144個數值)"""
    data = []
    with open(filename, 'r') as f:
        for line in f:
            line = line.split('//')[0]  # 過濾註解
            tokens = line.split()
            for t in tokens:
                t = t.replace('_', '')
                if t:
                    data.append(int(t, 16)) # 強制以 16 進位讀取
                
    if len(data) < 144:
        raise ValueError(f"Gain map 資料量不足 144 個 (目前 {len(data)} 個)，請檢查檔案內容。")
        
    gain_data = data[:144]
    mesh_table = np.array(gain_data, dtype=np.int32).reshape((4, 6, 6))
    return mesh_table

def read_ta_input(filename, pattern_idx):
    """讀取影像測資 (根據 0-15 的 pattern_idx 提取 256 個數值)"""
    data = []
    if not os.path.exists(filename):
        raise FileNotFoundError(f"找不到測資檔案：{filename}")
        
    with open(filename, 'r') as f:
        for line in f:
            line = line.split('//')[0]
            tokens = line.split()
            for t in tokens:
                t = t.replace('_', '')
                if t:
                    data.append(int(t, 16)) 

    start_idx = pattern_idx * 256
    end_idx = start_idx + 256
    
    if end_idx > len(data):
        raise ValueError(f"檔案 {filename} 資料量不足！無法讀取 Pattern Index {pattern_idx}。")
        
    img_data = data[start_idx:end_idx]
    img_array = np.array(img_data, dtype=np.int32).reshape((16, 16))
    return img_array

def BLC(img):
    """Black Level Correction"""
    out = np.zeros_like(img, dtype=np.int32)
    for y in range(16):
        for x in range(16):
            if y % 2 == 0 and x % 2 == 0:     B = 64  # R
            elif y % 2 == 0 and x % 2 == 1:   B = 48  # Gr
            elif y % 2 == 1 and x % 2 == 0:   B = 52  # Gb
            else:                             B = 72  # B
            
            out[y, x] = max(0, img[y, x] - B)
    return out

def LSC(img, mesh_table):
    """Lens Shading Correction"""
    out = np.zeros_like(img, dtype=np.int32)
    arr_G = np.zeros_like(img, dtype=np.int32)
    print("\n[LSC Debug] 印出每個座標的 g00, g01, g10, g11 值：")
    for y in range(16):
        for x in range(16):
            if y % 2 == 0 and x % 2 == 0:   ch = 0
            elif y % 2 == 0 and x % 2 == 1: ch = 1
            elif y % 2 == 1 and x % 2 == 0: ch = 2
            else:                           ch = 3
            
            x0 = min(x // 3, 4)
            y0 = min(y // 3, 4)
            rx = min(x - 3 * x0, 2)
            ry = min(y - 3 * y0, 2)
            
            g00 = mesh_table[ch][y0][x0]
            g01 = mesh_table[ch][y0][x0+1]
            g10 = mesh_table[ch][y0+1][x0]
            g11 = mesh_table[ch][y0+1][x0+1]
            
            print(f"Pixel (x={x:2d}, y={y:2d}) | Ch: {ch} | g00: {g00:4d}, g01: {g01:4d}, g10: {g10:4d}, g11: {g11:4d}")
            
            dx = (rx * 256 + 1) // 3
            ix = 256 - dx
            dy = (ry * 256 + 1) // 3
            iy = 256 - dy
            
            G = (g00*ix*iy + g10*ix*dy + g01*dx*iy + g11*dx*dy + 32768) // 65536
            P_prime = (img[y, x] * G + 512) // 1024

            arr_G[y, x] = G
            out[y, x] = max(0, min(P_prime, 4095))
    return out, arr_G

def get_padded_pixel(img, x, y, W=16, H=16):
    """Reflect Padding"""
    if x < 0: x = -x
    elif x >= W: x = 2 * W - 2 - x
    if y < 0: y = -y
    elif y >= H: y = 2 * H - 2 - y
    return img[y, x]

def DPC(img):
    """Defective Pixel Correction"""
    out = np.zeros_like(img, dtype=np.int32)
    for y in range(16):
        for x in range(16):
            win = np.zeros((5, 5), dtype=np.int32)
            for dy in range(-2, 3):
                for dx in range(-2, 3):
                    win[dy+2, dx+2] = get_padded_pixel(img, x+dx, y+dy)
            
            H = [win[2,0], win[2,1], win[2,3], win[2,4]]
            V = [win[0,2], win[1,2], win[3,2], win[4,2]]
            D1 = [win[0,0], win[1,1], win[3,3], win[4,4]]
            D2 = [win[0,4], win[1,3], win[3,1], win[4,0]]
            
            def calc_score_and_median(arr):
                arr_sorted = sorted(arr)
                med = (arr_sorted[1] + arr_sorted[2]) // 2 
                sad = sum(abs(val - med) for val in arr)
                return sad, med
                
            scores, medians = [], []
            for direction in [H, V, D1, D2]:
                s, m = calc_score_and_median(direction)
                scores.append(s)
                medians.append(m)
            
            min_idx = scores.index(min(scores))
            target = medians[min_idx]
            P = win[2, 2]
            
            if abs(P - target) > 320:
                out[y, x] = target
            else:
                out[y, x] = P
    return out

def Demosaic(img):
    """3x3 Bilinear Demosaicing"""
    out = np.zeros((16, 16, 3), dtype=np.int32)
    for y in range(16):
        for x in range(16):
            C = img[y, x]
            N = get_padded_pixel(img, x, y-1)
            S = get_padded_pixel(img, x, y+1)
            E = get_padded_pixel(img, x+1, y)
            W = get_padded_pixel(img, x-1, y)
            NW = get_padded_pixel(img, x-1, y-1)
            NE = get_padded_pixel(img, x+1, y-1)
            SW = get_padded_pixel(img, x-1, y+1)
            SE = get_padded_pixel(img, x+1, y+1)
            
            if y % 2 == 0 and x % 2 == 0:
                out[y, x, 0] = C
                out[y, x, 1] = (N + S + E + W) // 4
                out[y, x, 2] = (NW + NE + SW + SE) // 4
            elif y % 2 == 1 and x % 2 == 1:
                out[y, x, 0] = (NW + NE + SW + SE) // 4
                out[y, x, 1] = (N + S + E + W) // 4
                out[y, x, 2] = C
            elif y % 2 == 0 and x % 2 == 1:
                out[y, x, 0] = (W + E) // 2
                out[y, x, 1] = C
                out[y, x, 2] = (N + S) // 2
            else:
                out[y, x, 0] = (N + S) // 2
                out[y, x, 1] = C
                out[y, x, 2] = (W + E) // 2
    return out

def CCM(img):
    """Color Correction Matrix"""
    out = np.zeros_like(img, dtype=np.int32)
    C_int = np.array([
        [1100, -50, -50],
        [-50, 1100, -50],
        [-50, -50, 1100]
    ])
    
    for y in range(16):
        for x in range(16):
            R, G, B = img[y, x, 0], img[y, x, 1], img[y, x, 2]
            pixel_vec = np.array([R, G, B])
            
            for c in range(3):
                val = np.dot(C_int[c], pixel_vec)
                val = (val + 512) >> 10
                out[y, x, c] = max(0, min(val, 4095))
    return out

def main():
    gain_file = 'lsc_gain_map.txt'
    output_debug_file = 'debug.txt'
    
    # 🌟 只要改這裡！輸入你想 debug 的 6-bit CMD
    # 支援十六進位 (例如 0x15) 或二進位 (例如 0b010101)
    CMD = 0x16  
    
    # 解析指令 (講義規範：高 2 bits 為 SRAM index，低 4 bits 為 Pattern index)
    sram_idx = (CMD >> 4) & 0x03
    pattern_idx = CMD & 0x0F
    
    # 映射到對應的輸入檔案
    sram_file_map = {
        0: 'input_1.txt',
        1: 'input_2.txt',
        2: 'input_3.txt',
        3: 'input_4.txt'
    }
    input_file = sram_file_map[sram_idx]

    # 1. 讀取 Gain Map
    try:
        mesh_table = read_gain_map(gain_file)
    except Exception as e:
        print(f"讀取 Gain Map 失敗: {e}")
        return

    # 2. 抓取指定檔案與 Pattern 的影像數值
    try:
        img_array = read_ta_input(input_file, pattern_idx)
    except Exception as e:
        print(f"錯誤：{e}")
        return

    # 3. 將所有的 print 輸出重新導向寫入到 debug.txt
    print(f"正在處理 CMD: 0x{CMD:02X} (SRAM: {input_file}, Pattern Index: {pattern_idx})...")
    
    with open(output_debug_file, 'w', encoding='utf-8') as f_out:
        with redirect_stdout(f_out):
            print("="*60)
            print(f"========== ISP Pipeline Debug Report (CMD: 0x{CMD:02X}) ==========")
            print(f"Source File  : {input_file} (SRAM Index: {sram_idx})")
            print(f"Pattern Index: {pattern_idx} (0-based)")
            print("="*60)

            print(f"\n=== 0. Input RAW Image ===")
            print(img_array)
            
            img_array = BLC(img_array)
            print("\n=== 1. After BLC ===")
            print(img_array)
            
            img_array, arr_G = LSC(img_array, mesh_table)
            print("\n=== 2. Gain Table ===")
            print(arr_G)
            print("\n=== 2. After LSC ===")
            print(img_array)
            
            img_array = DPC(img_array)
            print("\n=== 3. After DPC ===")
            print(img_array)
            
            img_array_rgb = Demosaic(img_array)
            print("\n=== 4. After Demosaicing (RGB shape: 16x16x3) ===")
            print("--- Red Channel ---")
            print(img_array_rgb[:,:,0])
            print("--- Green Channel ---")
            print(img_array_rgb[:,:,1])
            print("--- Blue Channel ---")
            print(img_array_rgb[:,:,2])
            
            final_img = CCM(img_array_rgb)
            print("\n=== 5. After CCM (Final Output 12-bit) ===")
            print("--- Red Channel ---")
            print(final_img[:,:,0])
            print("--- Green Channel ---")
            print(final_img[:,:,1])
            print("--- Blue Channel ---")
            print(final_img[:,:,2])
            
            print("\n=== 6. Hardware Output Truncation (Upper 8-bit for r_out, g_out, b_out) ===")
            print("--- Red Output (r_out) ---")
            print(final_img[:,:,0] >> 4)
            print("--- Green Output (g_out) ---")
            print(final_img[:,:,1] >> 4)
            print("--- Blue Output (b_out) ---")
            print(final_img[:,:,2] >> 4)

    print(f"成功！Debug 報告已生成至 {output_debug_file}")

if __name__ == "__main__":
    main()