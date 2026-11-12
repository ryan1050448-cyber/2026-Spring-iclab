import numpy as np

# 建立 0 到 4095 的連續數字，並重塑(reshape)為 64x64 的二維陣列
array_64x64 = np.arange(4096).reshape(64, 64)

# 印出陣列查看結果
print(array_64x64)