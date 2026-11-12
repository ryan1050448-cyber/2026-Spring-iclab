(globals
    version = 3
    io_order = default
)

(iopad
    ;; --------------------------------------------------------
    ;; 四個角落必放的 Corner Pads
    ;; --------------------------------------------------------
    (topleft
        (inst name="CORNER0" cell="CORNERD")
    )
    (topright
        (inst name="CORNER1" cell="CORNERD")
    )
    (bottomright
        (inst name="CORNER2" cell="CORNERD")
    )
    (bottomleft
        (inst name="CORNER3" cell="CORNERD")
    )

    ;; --------------------------------------------------------
    ;; TOP 邊：由左至右排列 (Left -> Right)
    ;; --------------------------------------------------------
    (top
        (inst name="VDDC0")        ; Core Power
        (inst name="GNDC0")
        (inst name="I_CLK")        ; 訊號
        (inst name="I_RST_N")
        (inst name="VDDP0")        ; IO Power
        (inst name="GNDP0")
        (inst name="I_IN_DATA_VALID")
        (inst name="I_IN_DATA_0")
        (inst name="I_IN_DATA_1")
        (inst name="I_IN_DATA_2")
        (inst name="VDDP1")        ; IO Power 中間交錯
        (inst name="GNDP1")
        (inst name="I_IN_DATA_3")
        (inst name="I_IN_DATA_4")
        (inst name="I_IN_DATA_5")
        (inst name="I_IN_DATA_6")
        (inst name="I_IN_DATA_7")
        (inst name="VDDP2")        ; IO Power
        (inst name="GNDP2")
    )

    ;; --------------------------------------------------------
    ;; RIGHT 邊：由下至上排列 (Bottom -> Top)
    ;; 第一根在最下方（靠近 Bottom 邊），最後一根在最上方（靠近 Top 邊）
    ;; --------------------------------------------------------
    (right
        (inst name="VDDP8")        ; 最下方，靠近 Bottom 邊的 G 頻道
        (inst name="GNDP8")
        (inst name="O_G_OUT_0")
        (inst name="O_G_OUT_1")
        (inst name="O_G_OUT_2")
        (inst name="VDDP7")
        (inst name="GNDP7")
        (inst name="O_R_OUT_0")
        (inst name="O_R_OUT_1")
        (inst name="O_R_OUT_2")
        (inst name="O_R_OUT_3")
        (inst name="VDDP6")
        (inst name="GNDP6")
        (inst name="O_R_OUT_4")
        (inst name="O_R_OUT_5")
        (inst name="O_R_OUT_6")
        (inst name="O_R_OUT_7")
        (inst name="O_VALID")      ; 靠近右上角
        (inst name="VDDC3")        ; Core Power 放在最上方
        (inst name="GNDC3")
    )

    ;; --------------------------------------------------------
    ;; BOTTOM 邊：由左至右排列 (Left -> Right)
    ;; --------------------------------------------------------
    (bottom
        (inst name="VDDC1")
        (inst name="GNDC1")
        (inst name="O_G_OUT_3")
        (inst name="O_G_OUT_4")
        (inst name="O_G_OUT_5")
        (inst name="VDDP9")
        (inst name="GNDP9")
        (inst name="O_G_OUT_6")
        (inst name="O_G_OUT_7")
        (inst name="O_B_OUT_0")
        (inst name="O_B_OUT_1")
        (inst name="VDDP10")
        (inst name="GNDP10")
        (inst name="O_B_OUT_2")
        (inst name="O_B_OUT_3")
        (inst name="O_B_OUT_4")
        (inst name="O_B_OUT_5")
        (inst name="O_B_OUT_6")
        (inst name="O_B_OUT_7")
        (inst name="VDDP11")
        (inst name="GNDP11")
    )

    ;; --------------------------------------------------------
    ;; LEFT 邊：由下至上排列 (Bottom -> Top)
    ;; 第一根在最下方（靠近 Bottom 邊），最後一根在最上方（靠近 Top 邊）
    ;; --------------------------------------------------------
    (left
        (inst name="VDDP5")        ; 最下方，靠近 Bottom 邊
        (inst name="GNDP5")
        (inst name="I_CMD_5")
        (inst name="I_CMD_4")
        (inst name="I_CMD_3")
        (inst name="VDDP4")
        (inst name="GNDP4")
        (inst name="I_CMD_2")
        (inst name="I_CMD_1")
        (inst name="I_CMD_0")
        (inst name="I_CMD_VALID")
        (inst name="VDDP3")
        (inst name="GNDP3")
        (inst name="I_IN_DATA_8")  ; 往下遞減，這樣 data[8] 會在下方，data[11] 在上方
        (inst name="I_IN_DATA_9")
        (inst name="I_IN_DATA_10")
        (inst name="I_IN_DATA_11") ; 靠近左上角，順接 TOP 邊的 data[0:7]
        (inst name="VDDC2")        ; Core Power 放在最上方
        (inst name="GNDC2")
    )
)