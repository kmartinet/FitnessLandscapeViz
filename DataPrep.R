# DataPrep.R
# This file includes an example of how to prepare data for use in the included DisplayPlots Shiny app
# The end of this file includes a loop implementation for creating plots for multiple generations within one replicate

######## Single Implementation ########

# Load packages
library(mgcv) # For fitting GAMs
library(rgl)  # For creating 3D plots

# Load data
data <- read.csv("./Data/OnlyFit_K_Burrow_Gen0-48.csv")
# This example data was generated using Project Hastur's experiment mode. 
# The Evolutionary treatment was "OnlyFit," which means that Base and Tower fitness was active, but People were Absent
# The strategy used was "Burrow," which means that the player positioned turrets right next to Protean burrows

# Filter data
# I am interested in visualizing the fitness landscape for one generation in one replicate
# Get data from replicate 6
KSB6 <- data[which(data$replicate == 6),]
# Get data from generation 28 (I know this one looks cool)
KSB6_28 <- KSB6[which(KSB6$Generation == 28),]

# Designate traits of interest
traits <-  c("Health", "SightRange", "Armor", "Damage", "WalkSpeed", "RunSpeed",  
             "Acceleration", "TurnRate", "Swim", "Jump", "ColliderSurfaceArea", 
             "Attraction0", "Attraction1", "Attraction2")
# Create new dataframe with just traits of interest
trait_dat <- KSB6_28[traits]

# Save fitness values
# I choose relfit here, which is fitness based on the number of offspring each Protean produced
fitness <- KSB6_28$relfit

# Standardize traits (mean of 0, sd of 1)
traits_standardized <- scale(trait_dat)

# Perform PCA to reduce dimensionality
pca_model <- prcomp(traits_standardized, center = TRUE, scale. = TRUE)
pca_scores <- pca_model$x

# Combine PCA scores with fitness
fitness_data <- as.data.frame(cbind(pca_scores, fitness=fitness))

# Fit a GAM using cubic splines
# Inspired by the methods in Stroud, J.T., Moore, M.P., Langerhans, R.B., & Losos, J.B. 2023. Fluctuating selection maintains distinct species phenotypes in an ecological community in the wild. PNAS 120(42):e2222071120
gam_model <- gam(fitness ~ s(PC1, bs = "cs") + s(PC2, bs = "cs"), data = fitness_data)
summary(gam_model)

# Prepare data for surface heatmap
grid <- expand.grid(PC1 = seq(min(fitness_data$PC1), max(fitness_data$PC1), length=100),
                    PC2 = seq(min(fitness_data$PC2), max(fitness_data$PC2), length=100))
# Predict fitness over the grid to create a smooth surface for plotting
grid$fitness <- predict(gam_model, newdata = grid)

# Convert grid to matrices for plotting
PC1_matrix <- matrix(grid$PC1, nrow = 100, ncol = 100)
PC2_matrix <- matrix(grid$PC2, nrow = 100, ncol = 100)
fitness_matrix <- matrix(grid$fitness, nrow = 100, ncol = 100)

# Create and save 3D plot of fitness landscape
filename <- "./Data/KSB6_28.rds"
plot_title <- "KSB6 Gen 28"
open3d()
# Create 3D scatter plot of the original data
plot3d(x = fitness_data$PC1, y = fitness_data$PC2, z = fitness_data$fitness, 
       type = "s", size = 1, col = "blue", xlab = "PC1", ylab = "PC2", zlab = "Fitness", main = plot_title)
# Add the surface plot of the predicted fitness values
surface3d(PC1_matrix, PC2_matrix, fitness_matrix, color = "red", alpha = 0.5)

# Save 3D plot
rgl.snapshot(filename)
scene <- scene3d()
saveRDS(scene, filename)
close3d()

# Now a .rds file with the designated file name is in the ./Data directory! This file can be viewed using the DisplayPlots Shiny app


######## Loop Implementation ########
# If you are interested in creating fitness landscapes for several generations, here is a loop implementation of the example code above

# Load packages
library(mgcv)
library(rgl) 

# Load data
data <- read.csv("./Data/OnlyFit_K_Burrow_Gen0-48.csv")

# Traits of interest
traits <-  c("Health", "SightRange", "Armor", "Damage", "WalkSpeed", "RunSpeed",  
             "Acceleration", "TurnRate", "Swim", "Jump", "ColliderSurfaceArea", 
             "Attraction0", "Attraction1", "Attraction2")

# Choosing replicate 1
rep <- 1
# Designate prefix for .rds file name
prefix <- "KSB"

# Let's say I'd like to create .rds files for generations 25-30
for(g in c(25:30)){
  # Filter data
  dat_rep <- data[which(data$replicate == rep),]
  dat_gen <- dat_rep[which(dat_rep$Generation == g),]
  dat_traits <- dat_gen[traits]
  fitness <- dat_gen$relfit
  
  # Standardize traits (mean of 0, sd of 1 for each column)
  traits_standardized <- scale(dat_traits)
  
  # Perform PCA to reduce dimensionality
  pca_model <- prcomp(traits_standardized, center = TRUE, scale. = TRUE)
  pca_scores <- pca_model$x
  
  # Combine PCA scores with fitness
  fitness_data <- as.data.frame(cbind(pca_scores, fitness=fitness))
  
  # Fit a GAM using cubic splines
  gam_model <- gam(fitness ~ s(PC1, bs = "cs") + s(PC2, bs = "cs"), data = fitness_data)
  
  # Prepare data for surface heatmap
  grid <- expand.grid(PC1 = seq(min(fitness_data$PC1), max(fitness_data$PC1), length=100),
                      PC2 = seq(min(fitness_data$PC2), max(fitness_data$PC2), length=100))
  grid$fitness <- predict(gam_model, newdata = grid)
  
  # Convert grid to matrices for plotting
  PC1_matrix <- matrix(grid$PC1, nrow = 100, ncol = 100)
  PC2_matrix <- matrix(grid$PC2, nrow = 100, ncol = 100)
  fitness_matrix <- matrix(grid$fitness, nrow = 100, ncol = 100)
  
  # Create and save 3D plot of fitness landscape
  filename <- paste0("./Data/", prefix, rep, "_", g, ".rds")
  plot_title <- paste0(prefix, rep, " Gen ", g)
  open3d()
  # Create 3D scatter plot of the original data
  plot3d(x = fitness_data$PC1, y = fitness_data$PC2, z = fitness_data$fitness, 
         type = "s", size = 1, col = "blue", xlab = "PC1", ylab = "PC2", zlab = "Fitness", main = plot_title)
  # Add the surface plot of the predicted fitness values
  surface3d(PC1_matrix, PC2_matrix, fitness_matrix, color = "red", alpha = 0.5)
  
  # Save 3D plot
  rgl.snapshot(filename)
  scene <- scene3d()
  saveRDS(scene, filename)
  close3d()
}