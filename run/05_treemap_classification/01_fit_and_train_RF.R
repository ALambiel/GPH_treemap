library(terra)
library(ranger)
library(caret)


####
#-------- 0) Local paths and variables
####

# - Local paths

# Spectral Information data frame
hsipath <- "/path_to/hsi.rds"

# Output dir
exdir <- "/path_to_exdir"

# precise here which columns in HSI data frame are not reflectance values (e.g. 'x', 'y', 'sp',...)
columns <- c('sp', 'x', 'y','ID')

# Covariates folder (if needed) 
covarpath <- "" #"/path_to_covar_folder"

# Output folder
version <- "HSI_only"
exfold <- file.path(exdir, version, "models")
dir.create(exfold, recursive = TRUE, showWarnings = FALSE)

# number of components to keep after PCA
npc <- 4

# Loadind data 

# - Read HSI extraction data
if (file.exists(hsipath)) {
  hsi <- readRDS(hsipath)
} else {
  stop("Error : HSI file does not exist.")
}


# - Check and read covariates
if (dir.exists(covarpath)) {
  covar_files <- list.files(covarpath, full.names = TRUE) 
  use_covar <- length(covar_files) > 0
} else {
  covar_files <- NULL
  use_covar <- FALSE
}

if (use_covar) {
  stk <- c(rast(covar_files))
  message("Covariates loaded successfully.")
} else {
  message("No covariates found. Proceeding without covariates.")
}

####
#-------- 1) Preparing input data 
####  
print(paste("Version:", version))
print("Preparing input data")

# - 1.1) Splitting data in train and test sets

set.seed(12)

ind <- sample(2, nrow(hsi), replace = TRUE, prob = c(0.7, 0.3))
train <- hsi[ind==1,]
test <- hsi[ind==2,]

# - 1.2) Dimensional reduction of HSI with PCA
print("Dimension reduction with PCA")

ncolumns <- which(names(hsi)%in%columns)
pca_res <- prcomp(train[,-ncolumns],
                  rank. = npc,       #keep only the 4 first PCs, which explain 0.99452 of the variance
                  center = TRUE,
                  scale. = TRUE)
summary(pca_res)

# - 1.3) Extract covariates values for each observations 

# get observation points from the train set
obs <- train[, columns]

if (use_covar) {
  if (!"x" %in% names(obs) || !"y" %in% names(obs)) {
    stop("Error : No variables 'x' and 'y' in data frame 'obs'")
  }
  sampl <- vect(obs, geom = c("x", "y"))
  crs(sampl) <- crs(stk)
  cov <- extract(stk, sampl)[, -1]
  ndf <- cbind(obs, pca_res$x, cov)
  names(ndf) <- c(names(obs), paste0("PC", 1:npc), names(stk))
} else {
  ndf <- cbind(obs, pca_res$x)
}


# - Do the same with test set

pred_t <- predict(pca_res, test[, -ncolumns])
test_obs <- test[, columns]

if (use_covar) {
  sampl_t <- vect(test_obs, geom = c("x", "y"))
  cov_t <- extract(stk, sampl_t)[, -1]
  ndf_test <- cbind(test_obs, pred_t, cov_t)
  names(ndf_test) <- c(names(test_obs), paste0("PC", 1:npc), names(stk))
} else {
  ndf_test <- cbind(test_obs, pred_t)
}


# Adjust for RF model input
index <- which(names(ndf)=="sp"|!names(ndf) %in% columns)

ndf_test <- ndf_test[, index]
rf_df <- ndf[, index]


####
#-------- 2) Build RandomForest model
####
print("Building RF model")

# - 2.1) Model fitting


fit_control <- trainControl(method='cv', 
                            number=10,    #10-fold CV
                            classProbs = TRUE)

rfGrid <-  expand.grid(mtry = c(2:4),
                       splitrule = c("gini", "extratrees"),
                       min.node.size= c(1,5,10))


# - 2.2) Run a random forest model with ranger

start <- Sys.time()
print(paste0("Start time : ",start))

set.seed(12)
fit_rf <- train(sp~.,
                data = rf_df,
                method ='ranger',
                trControl = fit_control,
                tuneGrid = rfGrid,
                num.trees = 1000)


end <- Sys.time()
print(paste("End time :",end))
print(paste("Done. time elapsed: ", difftime(end,start,units="mins")," minutes",sep=""))

if (!is.null(fit_rf$bestTune)) {
  best_tune <- fit_rf$bestTune
  message("Best parameters - mtry: ", best_tune$mtry, 
          ", splitrule: ", best_tune$splitrule, 
          ", min.node.size: ", best_tune$min.node.size)
} else {
  message("Warning: No best tuning parameters found.")
}


# - 2.3) Predicting to test set 

p <- predict(fit_rf, ndf_test[,-1])




####
#-------- 3) Evaluate
####
print("Evaluating model")

# - Confusion matrix 

confusionMatrix(p, as.factor(ndf_test$sp))


####
#-------- 4) Save models
####

saveRDS(pca_res, file.path(exfold, paste0("PCAmodel_", Sys.Date(), ".rds")))

saveRDS(fit_rf, file.path(exfold, paste0("RFmodel_", Sys.Date(), ".rds")))

saveRDS(test, file.path(exfold, paste0("test_", Sys.Date(), ".rds")))
saveRDS(train, file.path(exfold, paste0("train_", Sys.Date(), ".rds")))

print("Completed")