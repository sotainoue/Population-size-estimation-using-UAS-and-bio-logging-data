data {
    //logger part
    int<lower=0> max_T; //number of step
    
    int<lower=0> n_obs; //number of step where logger data exist
    int<lower=0> t[n_obs]; // time step at logger data exist
    int<lower=0> y[n_obs]; // individuals in kabushima observed by logger
    int<lower=0> total_logger[n_obs]; // total individuals with logger in kabushima
    
    //Drone part
    int<lower=0> n_session; //number of session
    int<lower=0> t_session[n_session]; //time at drone session
    real<lower=0> drone[n_session];
    
    //validation part
    int n_val; //number of validation samples (m in the manuscript)
    real<lower=0> truth[n_val]; //number of individuals in one small image (ground truth)
    real<lower=0> predicted[n_val]; //number of individuals in one small image (prediction) 
    
    int<lower=0> nt[n_session]; // number of tiles in one session
}

parameters {
    real<lower=0> sigma_zeta; //variance parameter of observation equation for p
    real<lower=17000> N; //true population size
    vector[max_T] theta; 
    
    real<lower=0>alpha; //intercept of linear model for validation
    real alpha_prime;
    
    real beta; //slope of linear model for validation
    real beta_prime;
    
    real<lower=0> sigma_prime; //standard deviation parameter of linear model for validation
    real<lower=0> sigma_obs; //standard deviation of observation equation for N

    real delta_theta; //fixed logit-scale offset between individual attendance probability and population-level attendance probability
}

transformed parameters{
    vector<lower=0, upper=1>[max_T] p_logger;
        vector<lower=0, upper=1>[T] p_pop;
    
        for (t_i in 1:max_T){
            p_logger[t_i] = inv_logit(theta[t_i]); Individual attendance probability
            p_pop[t_i]    = inv_logit(theta[t_i] + delta_theta); Population-level attendance probability
        }
}
    
model {
    theta[1] ~ normal(0, 1);
    theta[2] ~ normal(0, 1);
    
    //state change along time
    for(i in 3:max_T){
        theta[i] ~ normal(2*theta[i-1] - theta[i-2], sigma_zeta);
    }
    
    for (i in 1:n_obs){
        y[i] ~ binomial(total_logger[i], p[t[i]]); 
    }
    
    beta_prime ~ normal(1, 0.2);
    
    for(i in 1:n_val){
        predicted[i] ~ normal(beta_prime*truth[i]+alpha_prime, sigma_prime);
    }
    
    alpha ~ normal(alpha_prime,0.05);
    beta ~ normal(beta_prime, 0.05);
    
    for(i in 1:n_session){
        drone[i] ~ normal(beta*N*p[t_session[i]] + nt[i]*alpha,sigma_obs);
    }
}

