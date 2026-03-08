library(dplyr)
library(ggplot2)

# 1) dplyrで前処理
df2 <- df %>% filter(!is.na(x), !is.na(y))

# 2) lmでモデル作成
fit <- lm(y ~ x, data = df2)

# 3) ggplot2で可視化
ggplot(df2, aes(x, y)) +
  geom_point() +
  geom_smooth(method = "lm", se = TRUE)