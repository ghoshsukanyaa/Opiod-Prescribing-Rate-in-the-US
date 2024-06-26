install.packages("openxlsx")
library(openxlsx)
install.packages("dplyr")
library(dplyr)
install.packages("magrittr")
library(magrittr)
install.packages("tidyverse")
library(ggplot2)
install.packages("mapdata")
library(maps)
library(data.table)
library(lme4)
install.packages("lattice")
library(caret)

##Loading Opioids##
Opioids <- read.xlsx("Opioid Project.xlsx")
Opioids

##Column Names within Opioids##
sort(colnames(Opioids))

##Data Type of Opioids##
str(Opioids)

##Summary of Opioids##
summary(Opioids)

##Opioids dimension##
dim(Opioids)

##VISUALIZATION

# Group by State and summarize the average change
statewise_summary <- Opioids %>%
  group_by(State) %>%
  summarize(Avg_Opioid_Prscrbng_Rate_Chg = mean(Opioid_Prscrbng_Rate_1Y_Chg, na.rm = TRUE))


# Identify the most and least affected states
most_affected <- statewise_summary[which.max(statewise_summary$Avg_Opioid_Prscrbng_Rate_Chg), "State"]
least_affected <- statewise_summary[which.min(statewise_summary$Avg_Opioid_Prscrbng_Rate_Chg), "State"]


# Create a bar plot with highlighted states
ggplot(statewise_summary, aes(x = State, y = Avg_Opioid_Prscrbng_Rate_Chg, fill = State)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = ifelse(statewise_summary$State %in% c(most_affected, least_affected),
                                    c("red", "green"), "blue")) +
  geom_text(aes(label = ifelse(State %in% c(most_affected, least_affected), State, "")),
            vjust = -0.5, angle = 45, hjust = 1, color = "black") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  ggtitle("Average Opioid Prescribing Rate Change by State") +
  xlab("State") +
  ylab("Average Rate Change")

##EDA_Choropleth map depicting decrease in 1yr change in opioid prescribing rates
library(readxl) 
library(dplyr) 
library(ggplot2) 
library(sf) 
library(viridis) # for color scales, using the full viridis package for more options 
library(tigris) # to get state boundaries

# Ensure state-level data in opioid_data, if necessary create a summary 
# This is just a placeholder for actual summary code based on your dataset 
opioid_data_state <- Opioids %>% 
  group_by(State) %>% 
  summarise(Opioid_Prscrbng_Rate_1Y_Chg = mean(Opioid_Prscrbng_Rate_1Y_Chg, na.rm = TRUE))

#Get state boundaries 
states <- tigris::states(cb = TRUE, class = "sf")

# Merge data with the state boundaries 
# Note: Adjust the column names in by.x and by.y to match your dataset 
# Assuming State is the column in your dataset with state names or abbreviations 
opioid_map_data_state <- merge(states, opioid_data_state, by.x = "STUSPS", by.y = "State")

# Create the map with a color palette suitable for a black background 
opioid_map_state <- ggplot(opioid_map_data_state) + 
  geom_sf(aes(fill = Opioid_Prscrbng_Rate_1Y_Chg)) + 
  scale_fill_viridis_c(name = "1Y Change in Opioid Prescribing Rate", option = "C") + 
  labs(title = "1-Year Change in Opioid Prescribing Rate by State", x = "", y = "") + 
  theme_void() + 
  theme(plot.background = element_rect(fill = "black", color = "black"), 
        panel.background = element_rect(fill = "black", color = "black"),
        legend.background = element_rect(fill = "black"), 
        text = element_text(color = "white"), 
        plot.title = element_text(size = 14, face = "bold", color = "white"), 
        legend.text = element_text(size = 10, color = "white"), 
        legend.title = element_text(size = 12, color = "white"), 
        legend.key = element_rect(fill = "black", color = "black"))
# Save the map with specific dimensions 
ggsave("opioid_map_state_black_background.png", plot = opioid_map_state, width = 20, height = 12, dpi = 350)


##MODEL

library(caret)
dummies_model <- dummyVars(~ ., data = Opioids)
dataset_transformed <- predict(dummies_model, newdata = Opioids)

# Convert the transformed dataset back to a data frame
dataset_transformed <- as.data.frame(dataset_transformed)

# Split the data into training and testing sets
set.seed(123) # for reproducibility
sample_size <- floor(0.8 * nrow(dataset_transformed))
train_indices <- sample(seq_len(nrow(dataset_transformed)), size = sample_size)
train <- dataset_transformed[train_indices, ]
test <- dataset_transformed[-train_indices, ]
names(train)
names(test)
dim(train)
dim(test)
memory.limit(size=50000) # Increase the memory limit; size in MB

#Regression
model <- lm(Opioid_Prscrbng_Rate_1Y_Chg ~ ., data = train)
# Summarize the model
summary(model)
# Predict on test set
test_df <- as.data.frame(test)
predictions <- predict(model, newdata = test)


#PERFORMANCE METRICS
# Calculate MSE
mse <- mean((test$Opioid_Prscrbng_Rate_1Y_Chg - predictions)^2)
# Calculate RMSE
rmse <- sqrt(mse)
# Calculate MAE
mae <- mean(abs(test$Opioid_Prscrbng_Rate_1Y_Chg - predictions))

# Calculate R-squared
ss_total <- sum((test$Opioid_Prscrbng_Rate_1Y_Chg - mean(test$Opioid_Prscrbng_Rate_1Y_Chg))^2)
ss_res <- sum((test$Opioid_Prscrbng_Rate_1Y_Chg - predictions)^2)
r_squared <- 1 - (ss_res / ss_total)
# Print the metrics
cat("MSE:", mse, "\n")
cat("RMSE:", rmse, "\n")
cat("MAE:", mae, "\n")
cat("R-squared:", r_squared, "\n")
