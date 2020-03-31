library('rstan')
library('dplyr')

##データ読み出し
member_price <- read.csv(file='/Users/200510/Desktop/TN/ROASの推定/member_price.csv', header=T, fileEncoding="utf-8")
member_price[is.na(member_price)] <- 0
member_price$channel_type_id <- as.integer(as.factor(member_price$channel_type))
member_price$channel_id <- as.integer(as.factor(member_price$channel))
set.seed(3)

##チャネル別応募率の推定
appliciant_data <- list(
  N = length(member_price$register_num),
  x = member_price$register_num,
  y = member_price$appliciant_num
)
Model_appliciant_rate <- stan(
  file='/Users/200510/Desktop/TN/ROASの推定/appciant_rate_estimation/appliciant_rate.stan',
  data=appliciant_data,
  iter=1200,
  warmup=200,
  thin=1,
  chains=3
)
member_price$predicted_appliciant_rate <- get_posterior_mean(Model_appliciant_rate)[1:length(member_price$register_num),4]
member_price[c("channel", "register_num", "appliciant_num", "appliciant_rate", "predicted_appliciant_rate")]
write.csv(member_price[c("channel", "register_num", "appliciant_num", "appliciant_rate", "predicted_appliciant_rate")], '/Users/200510/Desktop/TN/ROASの推定/appciant_rate_estimation/output_application_rate.csv')

##チャネル別採用率の推定
hire_data <- list(
  N = length(member_price$entry_num),
  x = member_price$entry_num,
  y = member_price$predicted_hire_num
)

Model_hire_data <- stan(
  file='/Users/200510/Desktop/TN/ROASの推定/hire_rate_estimation/hire_rate.stan',
  data=hire_data,
  iter=2000,
  warmup=1000,
  thin=1,
  chains=3
)
member_price$predicted_hire_rate <- get_posterior_mean(Model_hire_data)[1:length(member_price$entry_num),4]
member_price[c("channel","entry_num","predicted_hire_num","hire_rate", "predicted_hire_rate")]
write.csv(member_price[c("channel","entry_num","hire_num","hire_rate", "predicted_hire_rate")], '/Users/200510/Desktop/TN/ROASの推定/hire_rate_estimation/output_hire_rate.csv')

##チャネル別応募単価発生確率の推定
billing_data <- list(
  N = length(member_price$application_num),
  C = max(member_price$channel_id),
  x = member_price$application_num,
  y = member_price$price_biling_num,
  cid = member_price$channel_id
)
Model_appliciant_price_data <- stan(
  file='/Users/200510/Desktop/TN/ROASの推定/billing_rate_estimation/billing_rate.stan',
  data=billing_data,
  iter=2000,
  warmup=1000,
  thin=1,
  chains=3
)
stan_trace(Model_appliciant_price_data)
member_price$predicted_price_biling_rate <- summary(Model_appliciant_price_data)$summary[paste0("p[",1:Model_appliciant_price_data@par_dims$p,"]"),"mean"]
member_price[c("channel","application_num","price_biling_num","price_biling_rate","predicted_price_biling_rate")]
write.csv(member_price[c("channel","application_num","price_biling_num","price_biling_rate","predicted_price_biling_rate")], '/Users/200510/Desktop/TN/ROASの推定/billing_rate_estimation/output_price_biling_rate.csv')

##チャネル別応募単価の推定
application_unit_price <- read.csv("/Users/200510/Desktop/TN/ROASの推定/application_unit_price_estimation/application_unit_price.csv")
application_unit_price$channel_id <- as.integer(as.factor(application_unit_price$channel))
application_price <- list(
  N = length(application_unit_price$application_price),
  C = max(application_unit_price$channel_id),
  x = application_unit_price$application_price,
  cid = application_unit_price$channel_id
)
Model_application_price <- stan(
  file='/Users/200510/Desktop/TN/ROASの推定/application_unit_price_estimation/application_unit_price.stan',
  data=application_price,
  iter=2000,
  warmup=1000,
  thin=1,
  chains=3
)

stan_trace(Model_application_price)

application_price <- data.frame(channel_id = seq(1,23,1))
application_price$channel_application_price <- as.integer(summary(Model_application_price)$summary[paste0("y[",1:Model_application_price@par_dims$y,"]"),"mean"])
member_price <- inner_join(member_price, application_price, by="channel_id")
member_price$predicted_application_charge_appliciant_price <- as.integer(member_price$predicted_price_biling_rate * member_price$channel_application_price)
member_price[c("channel","application_num","price_biling_num","predicted_application_charge_appliciant_price","application_charge_appliciant_price")]
write.csv(member_price[c("channel","application_num","price_biling_num" ,"predicted_application_charge_appliciant_price","application_charge_appliciant_price")], '/Users/200510/Desktop/TN/ROASの推定/application_unit_price_estimation/output_application_price.csv')


##チャネル別採用単価の推定
hire_unit_price <- read.csv("/Users/200510/Desktop/TN/ROASの推定/hire_unit_price_estimation/hire_unit_price.csv")
hire_unit_price$channel_id <-as.integer(as.factor(hire_unit_price$channel))
hire_price <- list(
  N = length(hire_unit_price$pre_hire_confirm_sale),
  C = max(hire_unit_price$channel_id),
  x = hire_unit_price$pre_hire_confirm_sale,
  cid = hire_unit_price$channel_id
)
Model_hire_price <- stan(
  file='/Users/200510/Desktop/TN/ROASの推定/hire_unit_price_estimation/hire_unit_price.stan',
  data=hire_price,
  iter=2000,
  warmup=1000,
  thin=1,
  chains=3
)

stan_trace(Model_hire_price)

hire_price <- data.frame(channel_id = seq(1,23,1))
hire_price$predicted_hire_price <- as.integer(summary(Model_hire_price)$summary[paste0("y[",1:Model_hire_price@par_dims$y,"]"),"mean"])
member_price <- inner_join(member_price, hire_price, by="channel_id")
member_price[c("channel","predicted_hire_price", "hire_price")]
write.csv(member_price[c("channel","predicted_hire_price")], '/Users/200510/Desktop/TN/ROASの推定/hire_unit_price_estimation/output_hire_price.csv')

##チャネルあたりの顧客単価の推定
member_price$predicted_member_price <- as.integer( (member_price$predicted_hire_rate * member_price$predicted_hire_price  + member_price$predicted_application_charge_appliciant_price) * member_price$predicted_appliciant_rate )
member_price[c("channel", "channel_type", "is_ad", 
               "predicted_hire_rate", "hire_rate",
               "predicted_hire_price", "hire_price",
               "predicted_application_charge_appliciant_price", "application_charge_appliciant_price",
               "predicted_member_price", "member_price")]

output_data <- member_price[c("channel", "channel_type", "is_ad", "predicted_hire_rate", "predicted_hire_price", "predicted_application_charge_appliciant_price",  "predicted_member_price", "member_price")]
write.csv(output_data, '/Users/200510/Desktop/TN/ROASの推定/output_member_price.csv')
