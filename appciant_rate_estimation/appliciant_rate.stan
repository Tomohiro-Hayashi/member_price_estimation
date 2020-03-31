data{
  int N;
  int<lower=0> x[N];
  int<lower=0> y[N];
}

parameters{
  real<lower=0, upper=1> P[N];
  real<lower=0, upper=1> mu;
  real<lower=0> kappa;
}

transformed parameters {
  real<lower=0> a;
  real<lower=0> b;
  a = mu * kappa;
  b = kappa * (1 - mu);
}

model{
  for (i in 1:N) {
    P[i] ~ beta(a, b);
    y[i] ~ binomial(x[i], P[i]);
  }
}
