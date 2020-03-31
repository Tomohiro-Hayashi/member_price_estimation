SELECT
  m1.name AS channel
  --------------------------------------------------
  ,SUM(acl.application_price) sum_application_price
  ,COUNT(a.member_id) entry_num
  --------------------------------------------------
  ,sum_application_price / entry_num :: INT AS application_charge_appliciant_price
FROM
  jstaff.members AS m
  INNER JOIN jl_ad.application_states AS a ON m.id = a.member_id
  LEFT JOIN jl_ad.application_data_logs AS acl ON a.application_id = acl.application_id AND acl.fee_type = '応募課金'
  INNER JOIN jstaff.media AS m1 ON m.media_id = m1.id
WHERE a.first_created BETWEEN  CURRENT_DATE - '4 MONTHS' :: INTERVAL AND CURRENT_DATE - '2 MONTHS' :: INTERVAL AND a.is_processing = 0
GROUP BY channel
