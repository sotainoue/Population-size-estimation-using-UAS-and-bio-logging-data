data {
    //logger part
    int<lower=0> max_T; //number of step
    
    int<lower=0> n_obs; //number of step where logger data exist
    int<lower=0> t[n_obs]; // time step at logger data exist
    int<lower=0> y[n_obs]; // individuals in kabushima observed by logger
    int<lower=0> total_logger[n_obs]; // total individuals with logger in kabushima
}

parameters {
    real<lower=0> s_z;
    vector[max_T] theta;
}

transformed parameters{
    vector<lower=0, upper=1>[max_T] p;
    for (t_i in 1:max_T)
        p[t_i] = inv_logit(theta[t_i]); // logit link fucntion
}

model {
    theta[1] ~ uniform(0, 1);
    theta[2] ~ uniform(0, 1);
    
    //state change along time
    for(i in 3:max_T){
        theta[i] ~ normal(2*theta[i-1] - theta[i-2], s_z);
    }
    
    for (i in 1:n_obs){
        y[i] ~ binomial(total_logger[i], p[t[i]]); 
    }
}

