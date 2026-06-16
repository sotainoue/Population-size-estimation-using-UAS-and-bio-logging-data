library(tidyverse)
library(zoo)
library(here)
library(rnaturalearth)
library(rnaturalearthdata)
library(sf)
library(viridis)

here::here()
base_size <- 12 

#Figure 2D
logging_data <- read.csv(here::here('data/derived/logging_data.csv'),header=T)
logging_data2 <- subset(logging_data, month %in% c(5,6) & year == 2023)

## point kabushima
kabu_lati <- 40.5386062
kabu_long <- 141.5576031
kabu_data <- data.frame(lon=kabu_long,lat=kabu_lati)

## polygon of japan
land <- ne_countries(scale = "large", returnclass = "sf")

## crop the area
sf::sf_use_s2(FALSE)
land_crop <- st_crop(land, xmin = 141, xmax = 142.6, ymin = 40.2, ymax = 41.5)
sf::st_crs(land_crop)

fig_2d <- ggplot() +
    geom_sf(data = land_crop, fill = "gray90", color = NA) +
    #geom_sf(data = coastline_data$osm_lines, color = "black") +  
    geom_path(data=subset(logging_data2,id=='9B22556'),size=0.2,alpha=0.9 ,aes(x=lon,y=lat, color=date)) + 
    geom_point(data=kabu_data,aes(x=lon,y=lat),color='red',size=2) +
    scale_color_manual(values=inferno(56)) + #scale_color_brewer(palette='Paired') + 
    coord_sf(xlim = c(141,142.6), ylim=c(40.2,41.5),expand=F) + theme_classic()  + 
    labs(title='', subtitle = "", caption = "") + 
    xlab('longitude') + ylab('latitude') + 
    theme(legend.position = 'none',
          axis.text = element_text(size=7), 
          axis.title = element_text(size=9),
          axis.line = element_line(colour="black",size=0),
          panel.background = element_rect(fill = "white", colour = "black", size = 0.5),
          plot.margin = margin(t=1, r=1, b=1, l=1, unit="pt"))
print(fig_2d)

#Figure 3A
test_data <- read.csv(here::here('data/derived/test_data.csv'),header=T)
lm_model <- lm(data=test_data,n_ind_pre ~ n_ind)
slope <- lm_model$coefficients['n_ind'] #will be used for figure
intercept <- lm_model$coefficients[1] #will be used for figure

fig_3a <- ggplot(data=test_data,aes(x=n_ind,y=n_ind_pre)) + geom_point(alpha=0.5,size=0.5) + 
    geom_abline(slope=slope, intercept = intercept, col = '#008280FF',size=1, linetype='dashed') + 
    geom_abline(slope=1, intercept = 0, col = '#BB0021FF',size=1, linetype='dashed') + 
    theme_classic() + ylab('predicted') + xlab('actual') + 
    coord_equal() +
    theme_classic() + 
    theme(strip.text = element_blank(),
          legend.position = 'none',
          panel.background = element_rect(fill = "white", colour = "black", size = 0.75),
          axis.line = element_line(colour="black",size=0),
          text = element_text(size = base_size), 
          axis.title = element_text(size = 10), 
          axis.text = element_text(size = 7),
          plot.margin = margin(t=2, r=2, b=2, l=2, unit="pt"))
print(fig_3a)

#Figure 3B
uas_data <- read.csv(here::here('data/derived/uas_data.csv'),header=T)

fig_3b <- ggplot(data=uas_data, aes(x=as.factor(Month), y=n_total,group=Month)) + 
    geom_boxplot(aes(x=as.factor(Month), y=n_total,group=Month),width=0.5) + 
    geom_point(aes(x=as.factor(Month), y=n_total,group=Month),alpha=0.3) + 
    labs(color = 'Month') + xlab('') + ylab('number of detected individuals') +
    theme_classic()  + ylim(13000,19000) + 
    theme(strip.text = element_blank(),
          legend.position = 'none',
          panel.background = element_rect(fill = "white", colour = "black", size = 1.2),
          axis.line = element_line(colour="black",size=0),
          text = element_text(size = base_size), 
          axis.title = element_text(size = base_size), 
          axis.text = element_text(size = base_size-2), 
          legend.title = element_text(size = base_size), 
          legend.text = element_text(size = base_size-1),
          strip.background = element_rect(fill = "white"))
print(fig_3b)

#Figure 3C
cb_data <- read.csv(here::here('output/cb_data.csv'),header=T)
cb_data$ma1day <- rollmean(cb_data$ratio, k = 288, fill = NA)
cb_data$time_group <- as.POSIXct(cb_data$time_group, format="%Y-%m-%dT%H:%M:%SZ", tz="UTC") %>% 
    lubridate::with_tz("Asia/Tokyo")

ssmn_fit <- readRDS(here::here('output/ssmn_fit.rds'))
posterior_samples <- rstan::extract(ssmn_fit)$p
ssmn_p_median <- apply(posterior_samples, 2, median)
ssmn_p_ci_lower <- apply(posterior_samples, 2, quantile, probs = 0.025)
ssmn_p_ci_upper <- apply(posterior_samples, 2, quantile, probs = 0.975)
cb_data$ma1day <- rollmean(cb_data$ratio, k = 288, fill = NA)

df <- data.frame(time_group = cb_data$time_group,
                 ratio_ma1day  = cb_data$ma1day,
                 ssmn_p_median,
                 ssmn_p_ci_lower,
                 ssmn_p_ci_upper,
                 r=cb_data$ratio,
                 N=cb_data$total,
                 y=cb_data$stay)


fig_3c <-ggplot() + 
    geom_point(data=cb_data,aes(x=time_group,y=ratio),color='darkgrey',size=0.4,alpha=0.5)+ 
    geom_line(data=df,aes(x=time_group,y=ssmn_p_median),color='#D81B60',size=0.3,alpha=1) +
    geom_line(data=df,aes(x=time_group,y=ratio_ma1day),size=0.6,color='#1E88E5') + theme_classic() +
    geom_hline(yintercept=0.5, linetype='dashed',size=0.4,color='black',alpha=0.8) + 
    xlab('date') + ylab('probability') + 
    theme(panel.background = element_rect(fill = 'transparent', colour = 'black'))
print(fig_3c)


#Figure 3D
ssmp_fit <- readRDS(here::here('output/ssmp_fit.rds'))
posterior_samples <- rstan::extract(ssmp_fit)$p
ssmp_p_median <- apply(posterior_samples, 2, median)
ssmp_p_ci_lower <- apply(posterior_samples, 2, quantile, probs = 0.025)
ssmp_p_ci_upper <- apply(posterior_samples, 2, quantile, probs = 0.975)
cb_data$ma1day <- rollmean(cb_data$ratio, k = 288, fill = NA)

df <- data.frame(time_group = cb_data$time_group,
                 ratio_ma1day  = cb_data$ma1day,
                 ssmp_p_median,
                 ssmp_p_ci_lower,
                 ssmp_p_ci_upper,
                 r=cb_data$ratio,
                 N=cb_data$total,
                 y=cb_data$stay)

t_session <- which(is.na(cb_data$Fly)==F)
df_drone <- left_join(df[t_session,], cb_data[t_session,],by='time_group')

fig_3d <- ggplot(data=df_drone, aes(x=ssmp_p_median,y=n_total)) + 
    geom_point(size=0.8) + stat_smooth(method='lm',se=F) + 
    ylim(13000,19000) + ylab(expression('a'['obs']*' in each UAV session')) + xlab('predicted p') +
    theme_classic() + 
    theme(axis.text = element_text(size=7), 
          axis.title = element_text(size=9),
          axis.line = element_line(colour="black",size=0),
          panel.background = element_rect(fill = "white", colour = "black", size = 1))

print(fig_3d)


#Figure 3E
dens_list <- list()
summary_list <- list()

for(i in seq_along(theta_dashs)){

    model_name <- paste0(here::here('output/sens_fit_'), as.character(i), '.rds')
    sens_res <- readRDS(model_name)
    N_post <- rstan::extract(sens_res, pars = "N")$N

    df_N <- data.frame(
        N_es = as.vector(N_post),
        theta_dash = theta_dashs[i]
    )

    dens <- density(df_N$N_es)
    
    dens_list[[i]] <- data.frame(
        x = dens$x,
        y = dens$y,
        theta_dash = factor(theta_dashs[i])
    )

    summary_list[[i]] <- data.frame(
        theta_dash = theta_dashs[i],
        median = median(df_N$N_es),
        ci_lower = quantile(df_N$N_es, 0.025),
        ci_upper = quantile(df_N$N_es, 0.975)
    )
}

dens_df <- bind_rows(dens_list)
summary_df <- bind_rows(summary_list)

summary_zero <- summary_df %>%

    filter(theta_dash == 0)


#Figure 3F
sub_sample <- readRDS(here::here('output/sub_sample.rds'))
full_dens_df <- readRDS(here::here('output/full_dens_df.rds'))


fig_3e <-
    ggplot() +
    geom_rect(data=sub_sample, aes(xmin=lo_ci, xmax=up_ci), ymin=-0.00001, ymax=0.00076, fill='black',alpha=0.3) +
    geom_line(data = subset(full_dens_df,category=='simulation'), 
              aes(x = x, y = y,color=as.factor(id),group=id),alpha=0.8) +
    facet_grid(sample_size_ratio~dataset2,
               labeller = as_labeller(c('drone'='UAS reduction', 
                                        'logger'='logger reduction',
                                        '90%'='90%',
                                        '75%'='75%',
                                        '50%'='50%'))) +
    geom_vline(xintercept = median(subset(full_dens_df,category=='observed')$x),linetype=2, color='grey30') +
    scale_color_manual(values=inferno(10)) +
    ylim(0,0.00035) + 
    #geom_vline(xintercept = lo_ci,linetype=2, color='grey80') +
    #geom_vline(xintercept = up_ci,linetype=2, color='grey80') +
    theme_classic()+xlab("Estimated N") + ylab('density') +
    theme(axis.line = element_line(colour="black",size=0),
          strip.background  = element_blank(),
          legend.position='none',
          legend.box.background = element_rect(fill="white",colour = "black",size=0.4),
          panel.background = element_rect(fill = "white", colour = "black", size = 1))
print(fig_3e)


#Table S3
symbols_1 <- c('N','sigma_obs')

sum_tbl <- rstan::summary(ssmn_fit)$summary

table_s3_1 <- tibble::tibble(
    symbol  = symbols_1,
    mean    = sum_tbl[symbols_1, "mean"],
    sd      = sum_tbl[symbols_1, "sd"],
    median  = sum_tbl[symbols_1, "50%"],
    lowerCI = sum_tbl[symbols_1, "2.5%"],
    upperCI = sum_tbl[symbols_1, "97.5%"]
) %>%
    dplyr::mutate(
        dplyr::across(where(is.numeric), ~ signif(.x, 5))
    )

symbols_2 <- c('sigma_zeta','alpha','beta','alpha_prime','beta_prime','sigma_prime')

table_s3_2 <- tibble::tibble(
    symbol  = symbols_2,
    mean    = sum_tbl[symbols_2, "mean"],
    sd      = sum_tbl[symbols_2, "sd"],
    median  = sum_tbl[symbols_2, "50%"],
    lowerCI = sum_tbl[symbols_2, "2.5%"],
    upperCI = sum_tbl[symbols_2, "97.5%"]
) %>%
    dplyr::mutate(
        dplyr::across(where(is.numeric), ~ signif(.x, 3))
    )

table_s3 <- rbind(table_s3_1, table_s3_2)
write_csv(as.data.frame(table_s3), here::here("output/table_s3.csv"))




