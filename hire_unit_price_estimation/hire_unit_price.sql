--チャネル別採用単価
SELECT
	ct.name AS channel
	,a.pre_hire_confirm_sale
FROM
	jl_ad.application_states AS a
	LEFT JOIN jstaff.members AS m ON a.member_id = m.id
	LEFT JOIN jl_ad.work_sales AS ws ON a.work_id  = ws.work_id
	INNER JOIN jl_ad.channel_types AS ct ON m.media_id = ct.id
	INNER JOIN jl_ad.coefficients AS co ON ct.type = co.channel_type
	LEFT JOIN jl_ad.application_data_logs AS acl ON a.application_id = acl.application_id AND acl.fee_type IN ('応募課金', '掲載課金')
WHERE
	a.first_created BETWEEN CURRENT_DATE - '7 MONTH' ::INTERVAL AND CURRENT_DATE - '1 MONTH' ::INTERVAL
	AND acl.application_id IS NULL
	AND a.pre_hire_confirm_sale <> 0
;
