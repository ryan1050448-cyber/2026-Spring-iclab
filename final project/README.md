# Final Project — DCCPU + APR

| 項目 | 內容 |
| --- | --- |
| **主題** | DCCPU + APR |
| **Rank** | 43/44 |
| **分數** | 70.07 |


## 心得
這次的performance佔了50%，真的很傷。

大概就是midterm project的東西要想辦法去降低power，基本上用一個SRAM會是最省power的方式，並且控制SRAM的CS讓他在不需要被讀寫的時候關掉。

助教有給我們比較不同方法的clock gating方式，但那個方法會導致RTL simulation和Gate level simulation的行為有落差，我怕會導致demo出問題，
所以就沒有用clock gating，結果就是performance輸爛。
