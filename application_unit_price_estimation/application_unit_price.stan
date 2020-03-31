data{
  int N;
  int C;
  int<lower=0> x[N];
  int<lower=0> cid[N];
}

parameters{
  real<lower=0> y[C];
  real<lower=0> sigma;
}

model{
  for (i in 1:N) {
    x[i] ~ normal(y[cid[i]], sigma);
  }
}
