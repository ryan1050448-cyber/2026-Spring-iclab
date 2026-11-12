import os
import random

# ==========================================
# 參數設定
# ==========================================
NUM_INSTRUCTIONS = 4096  # 填滿 0x0000 ~ 0x1FFF
NUM_DATA_WORDS = 4096    # 填滿 0x1000 ~ 0x2FFF

# Opcode Mapping
OP_RTYPE = 0b000
OP_MULT  = 0b001
OP_ADDI  = 0b010
OP_SUBI  = 0b011
OP_LOAD  = 0b100
OP_STORE = 0b101
OP_BEQ   = 0b110
OP_JUMP  = 0b111

def to_hex_str(val, bits=16): return f"{val & ((1<<bits)-1):0{bits//4}x}"
def to_bin_str(val, bits=16): return f"{val & ((1<<bits)-1):0{bits}b}"

def get_signed_imm(val, bits=7):
    if val & (1 << (bits - 1)):
        return val - (1 << bits)
    return val

# ==========================================
# 指令生成邏輯
# ==========================================
def generate_instruction(pc, prevent_store=False):
    while True:
        opcode = random.randint(0, 7)
        if prevent_store and opcode == OP_STORE:
            continue
        break

    rs = random.randint(0, 7)
    rt = random.randint(0, 7)
    rd = random.randint(0, 7)
    imm = random.randint(0, 127) 
    
    inst_val = 0
    asm_str = ""

    if opcode == OP_RTYPE:
        func = random.randint(0, 7)
        inst_val = (OP_RTYPE << 13) | (rs << 10) | (rt << 7) | (rd << 4) | (func << 1) | 0
        func_names = ["ADD", "SUB", "AND", "OR", "NAND", "NOR", "XOR", "SLT"]
        asm_str = f"{func_names[func]:<4} r{rd}, r{rs}, r{rt}"

    elif opcode == OP_MULT:
        rl = random.randint(0, 7)
        inst_val = (OP_MULT << 13) | (rs << 10) | (rt << 7) | (rd << 4) | (rl << 1) | 0
        asm_str = f"MULT r{rd}, r{rl}, r{rs}, r{rt}"

    elif opcode == OP_ADDI:
        inst_val = (OP_ADDI << 13) | (rs << 10) | (rt << 7) | imm
        asm_str = f"ADDI r{rt}, r{rs}, {get_signed_imm(imm)}"

    elif opcode == OP_SUBI:
        inst_val = (OP_SUBI << 13) | (rs << 10) | (rt << 7) | imm
        asm_str = f"SUBI r{rt}, r{rs}, {get_signed_imm(imm)}"

    elif opcode == OP_LOAD:
        inst_val = (OP_LOAD << 13) | (rs << 10) | (rt << 7) | imm
        asm_str = f"LOAD r{rt}, {get_signed_imm(imm)}(r{rs})"

    elif opcode == OP_STORE:
        inst_val = (OP_STORE << 13) | (rs << 10) | (rt << 7) | imm
        asm_str = f"STOR r{rt}, {get_signed_imm(imm)}(r{rs})"

    elif opcode == OP_BEQ:
        imm = random.randint(0, 63) 
        inst_val = (OP_BEQ << 13) | (rs << 10) | (rt << 7) | imm
        asm_str = f"BEQ  r{rs}, r{rt}, {get_signed_imm(imm)}"

    elif opcode == OP_JUMP:
        address = random.randint(0, 4095) * 2 
        inst_val = (OP_JUMP << 13) | address
        asm_str = f"JUMP 0x{to_hex_str(address, 13)}"

    return inst_val, asm_str, opcode

# ==========================================
# 檔案寫入邏輯
# ==========================================
def main():
    print("正在生成完全符合 TA 格式的 DRAM 檔案 (包含 Little Endian 轉換)...")
    os.makedirs("debug", exist_ok=True)

    # 1. 產生 Data DRAM (data_dram_file.dat)
    with open("data_dram_file.dat", "w") as f_data:
        addr = 0x1000
        for i in range(NUM_DATA_WORDS):
            rand_data = random.randint(0, 0xFFFF)
            byte0 = rand_data & 0xFF         # Low Byte
            byte1 = (rand_data >> 8) & 0xFF  # High Byte
            f_data.write(f"@{addr:04X}\n")
            f_data.write(f"{byte0:02x} {byte1:02x} // Raw Data: {rand_data} (0x{rand_data:04X})\n")
            addr += 2
    print("-> 已生成 data_dram_file.dat")

    # 2. 產生 Instruction DRAMs & Debug Files
    with open("inst_1_dram_file.dat", "w") as f_i1, \
         open("inst_2_dram_file.dat", "w") as f_i2, \
         open("debug/debug_core1.txt", "w") as f_d1, \
         open("debug/debug_core2.txt", "w") as f_d2:
        
        # 寫入 Debug Header
        f_d1.write(f"{'PC':<6} | {'Hex':<4} | {'Binary':<16} | {'Assembly'}\n")
        f_d1.write("-" * 60 + "\n")
        f_d2.write(f"{'PC':<6} | {'Hex':<4} | {'Binary':<16} | {'Assembly'}\n")
        f_d2.write("-" * 60 + "\n")

        pc = 0x0000
        for i in range(NUM_INSTRUCTIONS):
            # ===== Core 1 指令 =====
            i1_val, i1_asm, i1_opcode = generate_instruction(pc, prevent_store=False)
            i1_b0 = i1_val & 0xFF
            i1_b1 = (i1_val >> 8) & 0xFF
            f_i1.write(f"@{pc:04X}\n")
            f_i1.write(f"{i1_b0:02x} {i1_b1:02x} // Inst: {i1_asm} | bin: {to_bin_str(i1_val)}\n")
            
            # ===== Core 2 指令 =====
            core1_is_store = (i1_opcode == OP_STORE)
            i2_val, i2_asm, _ = generate_instruction(pc, prevent_store=core1_is_store)
            i2_b0 = i2_val & 0xFF
            i2_b1 = (i2_val >> 8) & 0xFF
            f_i2.write(f"@{pc:04X}\n")
            f_i2.write(f"{i2_b0:02x} {i2_b1:02x} // Inst: {i2_asm} | bin: {to_bin_str(i2_val)}\n")

            # ===== 寫入純文字 Debug 檔 =====
            f_d1.write(f"{to_hex_str(pc, 16):<6} | {to_hex_str(i1_val)} | {to_bin_str(i1_val)} | {i1_asm}\n")
            f_d2.write(f"{to_hex_str(pc, 16):<6} | {to_hex_str(i2_val)} | {to_bin_str(i2_val)} | {i2_asm}\n")

            pc += 2 # Instruction address +2

    print("-> 已生成 inst_1_dram_file.dat 與 inst_2_dram_file.dat")
    print("-> 已生成 debug/debug_core1.txt 與 debug/debug_core2.txt")
    print("完成！你的測資現在可以完美餵給 TA 的 pseudo_DRAM 了！")

if __name__ == "__main__":
    main()