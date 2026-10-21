# Selection of the appropriate number of clusters
# Complete using the elbow method
# Decide how many clusters to look at
set.seed(123)

n_clusters <- 15

# Initialize total within sum of squares error: wss
wss <- numeric(n_clusters)

# Look over 1 to n possible clusters
for (k in 1:n_clusters) {
  # Fit the model: km.out
  km.out <- kmeans(scale(cluster_input[-1]),
                   k,
                   nstart = 50, 
                   iter.max = 100)
  # Save the within cluster sum of squares
  wss[k] <- km.out$tot.withinss
}

# Produce a scree plot
wss_df <- tibble(clusters = 1:n_clusters, wss = wss)

scree_plot <- ggplot(wss_df, aes(x = clusters, y = wss, group = 1)) +
  geom_point(size = 4)+
  geom_line() +
  scale_x_continuous(breaks = c(2, 4, 6, 8, 10)) +
  xlab('Number of clusters')
scree_plot

# 4 clusters seems appropriate
