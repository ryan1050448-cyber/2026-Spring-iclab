# Lab7 — CDC

| 項目 | 內容 |
| --- | --- |
| **主題** | CDC |
| **Rank** | x |
| **分數** | 95 |


## 心得
這次的CDC比以往都麻煩，之前大多都是module 1到module 3就結束，但我們還要從module 3再回到module 1，這最大的問題就是很容易在module 3遇到
convergence的問題。

Convergence會出現在從同一個source端來的兩個訊號有邏輯交叉關係，訊號會被標記從哪裡過來，如果兩個交疊的訊號追溯源頭是來自同一個source，JG 
就會跳出convergence，首先就是module 3本來就很容易出現這個問題，因為接收module 2過來的，還要輸出給module 2，我要從FIFO syn看有沒有empty
或是full，就一定會汙染到其他訊號，然後訊號間過幾層後就會重疊，convergence問題就蹦出來了，然後我就死了。

即使是在出現convergence的情況下，我的functionality也不會出問題，但JG就是窮舉所有可能，所以就很沒救。最終是檔五層buffer讓JG抓不到convergence
問題才可以交件。
