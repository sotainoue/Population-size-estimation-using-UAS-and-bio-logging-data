library(tidyverse)
library(lubridate)
library(rstan)
library(zoo)
library(here)

dir.create(here::here("output"), showWarnings = FALSE, recursive = TRUE)

#stan setting used in the real analysis
iter <- 20000; warmup <- 10000 
#iter <- 2000; warmup <- 1000 #just for checking the code

#set the cooridnates of the colony
kabu_lati <- 40.5386062
kabu_long <- 141.5576031
point_kabu <- c(kabu_long,kabu_lati)

#read data
#validation data
test_data <- read.csv(here::here('data/derived/test_data.csv'),header=T)
lm_model <- lm(data=test_data,n_ind_pre ~ n_ind)
slope <- lm_model$coefficients['n_ind'] #will be used for figure
print(paste('slope of lm is',as.character(slope),sep=' '))

##number of images 
n_image_data <- read.csv(here::here('data/derived/n_image.csv'),header=T)

#bio-logging
##derive data during breeding season and correct time to JST
logging_data <- read.csv(here::here('data/derived/logging_data.csv'),header=T)
logging_data <- logging_data %>%
    mutate(datetime_utc = lubridate::ymd_hms(datetime_utc, tz = "UTC"))

logging_data <- logging_data %>%
    mutate(
        datetime_jst = with_tz(datetime_utc, "Asia/Tokyo"),
        time_group = floor_date(datetime_jst, "10 minutes")
    )

logging_data2 <- subset(logging_data, month %in% c(5,6) & year == 2023)

#whether individuals were present in the colony or not
tmp <- logging_data2 %>%
    group_by(id, time_group) %>%
    summarise(position = names(which.max(table(position))), .groups = "drop")

time_group <- seq(from = as.POSIXct('2023-05-02 00:00:00', tz='Asia/Tokyo'), 
                  to = max(logging_data2$time_group),
                  by = "10 min")
time_df <- tibble(time_group = time_group)
tmp3 <- left_join(time_df,tmp, by='time_group')


b_data <- tmp3 %>%
    group_by(time_group) %>%
    summarise(
        stay = sum(position == "stay", na.rm = TRUE),
        trip = sum(position == "trip", na.rm = TRUE),
        total = sum(!is.na(position)),
        .groups = "drop"
    ) %>%
    mutate(ratio = stay / total)

stopifnot(all(b_data$total > 0)) #check whether all data points have valid sample

ggplot(data=b_data, aes(x=time_group, y=ratio)) + geom_point()

#uas
uas_data <- read.csv(here::here('data/derived/uas_data.csv'),header=T)
#uas_data2 <- pivot_wider(uas_data, names_from=category_id,values_from = number)

uas_data <- mutate(uas_data, 
                    datetime = ymd_hms(paste(date, time), tz='Asia/Tokyo'),
                    time_group = floor_date(datetime, "10 minutes"))
uas_data2 <- dplyr::select(uas_data,time_group,Fly,G,n_total)


#integrate movement data and count data
cb_data <- left_join(b_data,uas_data2,by='time_group')
exist_data <- which(cb_data$total > 0)
stopifnot(length(exist_data) == nrow(cb_data))
t_session <- which(!is.na(cb_data$Fly))
cb_data2 <- subset(cb_data, !is.na(Fly))


#merge
stan_data <- list(max_T = nrow(cb_data), 
                  t = exist_data,
                  n_obs = length(exist_data),
                  y = cb_data$stay[exist_data], 
                  total_logger = cb_data$total[exist_data],
                  t_session = t_session,
                  n_session = nrow(cb_data2),
                  drone=cb_data2$n_total,
                  n_val=nrow(test_data),
                  predicted=test_data$n_ind_pre,
                  truth=test_data$n_ind,
                  nt=n_image_data$nt)

stopifnot(!any(cb_data$stay[exist_data] > cb_data$total[exist_data]))

options(mc.cores = parallel::detectCores())

#run ssmp 
ssmp_model <- stan_model(
    file = here::here("ssm_model/ssmp.stan")
)
ssmp_fit <- sampling(ssmp_model, 
                     data=stan_data,
                     iter=iter,
                     warmup=warmup, 
                     chains=4,
                     thin=4,
                     seed=123)
                    
saveRDS(ssmp_fit,file=here::here('output/ssmp_fit.rds'))

#post-analysis of ssmp
posterior_samples <- rstan::extract(ssmp_fit)$p
p_median <- apply(posterior_samples, 2, median)
p_ci_lower <- apply(posterior_samples, 2, quantile, probs = 0.025)
p_ci_upper <- apply(posterior_samples, 2, quantile, probs = 0.975)
cb_data$ma1day <- rollmean(cb_data$ratio, k = 288, fill = NA)

df <- data.frame(time_group = cb_data$time_group,
                 ratio_ma1day  = cb_data$ma1day,
                 p_median,
                 p_ci_lower,
                 p_ci_upper,
                 r=cb_data$ratio,
                 N=cb_data$total,
                 y=cb_data$stay)

df_drone <- df %>%
    left_join(cb_data, by = "time_group") %>%
    filter(!is.na(Fly))

#check correlation
cor.test(df_drone$p_median,df_drone$n_total)


#run ssmn
ssmn_model <- stan_model(
    file = here::here("ssm_model/ssmn.stan")
)

ssmn_fit <- sampling(ssmn_model, 
                     data=stan_data,
                     chains=4,
                     iter=iter, 
                     warmup=warmup,
                     thin=4,
                     seed=123) 
saveRDS(ssmn_fit,file=here::here('output/ssmn_fit.rds'))

#post-analysis of ssmn
df_N <- data.frame(N_es=rstan::extract(ssmn_fit)$N)
median_value <- median(df_N$N_es)
ci_lower <- quantile(df_N$N_es, probs = 0.025)
ci_upper <- quantile(df_N$N_es, probs = 0.975)
ci_lower50 <- quantile(df_N$N_es, probs = 0.25)
ci_upper50 <- quantile(df_N$N_es, probs = 0.75)

print(median_value)
print(ci_lower)
print(ci_upper)

#write csv
write_csv(b_data, here::here("output/b_data.csv"))
write_csv(uas_data2, here::here("output/uas_data2.csv"))
write_csv(cb_data, here::here("output/cb_data.csv"))
write_csv(df, here::here("output/df_posterior_summary.csv"))





