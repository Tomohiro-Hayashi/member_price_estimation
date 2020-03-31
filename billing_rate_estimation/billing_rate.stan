data{
  int N;
  int<lower=0> x[N];
  int<lower=0> y[N];
}

parameters{
  real<lower=0, upper=1> p[N];
  real<lower=0, upper=1> mu;
  real<lower=0> sigma;
}

transformed parameters {
}
model{
  for (i in 1:N) {
    p[i] ~ normal(mu, sigma);
    y[i] ~ binomial(x[i], p[i]);
  }
}
