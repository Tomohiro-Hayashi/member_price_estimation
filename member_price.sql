WITH
applicant_rate AS (
	SELECT
		ct.name AS channel
		,channel_type
		,COUNT(DISTINCT m.id) register_num
		,LEAST(CAST(COUNT(DISTINCT a.member_id) * MAX(co.appliciant_coefficient) AS INT), register_num) appliciant_num
		,appliciant_num / greatest(register_num,1) :: REAL AS appliciant_rate
	FROM
		jstaff.members AS m
		LEFT JOIN jl_ad.application_states AS a ON m.id = a.member_id
		INNER JOIN jl_ad.channel_types AS ct ON m.media_id = ct.id
		INNER JOIN jl_ad.coefficients AS co ON ct.type = co.channel_type
	WHERE m.created BETWEEN CURRENT_DATE - '31 DAYS' ::INTERVAL AND CURRENT_DATE - '1 DAYS' ::INTERVAL
	GROUP BY channel, channel_type
	HAVING register_num >=5
),

sales_and_hire_rate AS (
	SELECT
		ct.name AS channel
		,CAST(SUM(a.is_pre_hire_confirmed * ws.pre_hire_confirm_to_hire_rate) AS INT) predicted_hire_num
		,COUNT(DISTINCT a.member_id) entry_num
		,(predicted_hire_num * 1.0 / greatest(entry_num,1)) :: REAL AS hire_rate
		,SUM(a.pre_hire_confirm_sale) pre_hire_confirm_sales
		,SUM(a.is_pre_hire_confirmed) prehire_num
		,pre_hire_confirm_sales / greatest(prehire_num,1) AS hire_price
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
	GROUP BY channel
),

applicant_unite_price AS (
	SELECT
		m1.name AS channel
		,SUM(acl.application_price) application_sales
		,COUNT(a.member_id) application_num
		,COUNT(CASE WHEN acl.application_price IS NOT NULL THEN a.member_id END) price_biling_num
		,price_biling_num *1.0 / greatest(application_num,1) price_biling_rate
		,application_sales / greatest(application_num,1) :: INT AS application_charge_appliciant_price
	FROM
		jstaff.members AS m
		INNER JOIN jl_ad.application_states AS a ON m.id = a.member_id
		LEFT JOIN jl_ad.application_data_logs AS acl ON a.application_id = acl.application_id AND acl.fee_type = '応募課金'
		INNER JOIN jstaff.media AS m1 ON m.media_id = m1.id
	WHERE a.first_created BETWEEN  CURRENT_DATE - '4 MONTHS' :: INTERVAL AND CURRENT_DATE - '2 MONTHS' :: INTERVAL AND a.is_processing = 0
	GROUP BY channel
)

SELECT
	m.name AS channel
	,m.id AS media_id
	,channel_type
	,CASE WHEN m.name ~ 'cpc|android|ios|retargeting|acquire|indivision' AND m.name !~ 'jstaff' THEN 1 ELSE 0 END AS is_ad
	,register_num
	,appliciant_num
	,appliciant_rate
	,entry_num
	,predicted_hire_num
	,hire_rate
	,pre_hire_confirm_sales
	,prehire_num
	,hire_price
	,application_sales
	,application_num
	,price_biling_num
	,price_biling_rate
	,application_charge_appliciant_price
	,((hire_price * hire_rate + NVL(application_charge_appliciant_price, 0)) * appliciant_rate) :: INT AS member_price
	,CURRENT_DATE AS updated_at
FROM
	jstaff.media AS m
	LEFT JOIN applicant_rate AS a ON m.name = a.channel
	LEFT JOIN sales_and_hire_rate AS p ON a.channel = p.channel
	LEFT JOIN applicant_unite_price AS ac ON m.name = ac.channel
WHERE
	channel_type IS NOT NULL
;
