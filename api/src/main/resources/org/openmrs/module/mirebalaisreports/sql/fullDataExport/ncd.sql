DROP TEMPORARY TABLE IF EXISTS temp_obs_join;
DROP TEMPORARY TABLE IF EXISTS temp_ncd_section;

-- NCD section
create TEMPORARY table temp_ncd_section
(
obs_id int,
encounter_id int,
person_id int,
known_chronic_disease_before_referral varchar(50),
prior_treatment_for_chronic_disease varchar(50),
chronic_disease_controlled_during_initial_visit varchar(50),
disease_category text,
comments text,
waist_circumference double,
hip_size double,
hypertension_stage text,
diabetes_mellitus text,
serum_glucose double,
fasting_blood_glucose_test varchar (50),
fasting_blood_glucose double,
managing_diabetic_foot_care text,
diabetes_comment text,
probably_asthma varchar(50),
respiratory_diagnosis text,
bronchiectasis varchar(50),
copd varchar(50),
copd_grade varchar(255),
commorbidities text,
inhaler_training varchar (50),
pulmonary_comment text,
categories_of_heart_failure text,
nyha_class text,
fluid_status text,
cardiomyopathy text,
heart_failure_improbable varchar(50),
heart_remarks text,
left_ventricle_systolic_function varchar(255),
right_ventricle_dimension varchar(255),
mitral_valve_finding varchar(255),
pericardium_findings varchar(255),
inferior_vena_cava_findings varchar(255),
quality varchar(255),
additional_comments text,
other_disease_category text,
other_non_coded_diagnosis text,
medice_past_two_days varchar(50),
reason_poor_compliance text,
cardiovascular_medication text,
respiratory_medication text,
endocrine_medication text,
other_medication text
);

INSERT INTO temp_ncd_section (obs_id, encounter_id, person_id, disease_category, comments)
select obs_id, encounter_id, person_id, group_concat(name), comments from obs o, concept_name cn
where
value_coded = cn.concept_id  and locale="en" and concept_name_type="FULLY_SPECIFIED" and cn.voided = 0 and
o.concept_id = (select concept_id from report_mapping where source="PIH" and code = "NCD category") and o.voided = 0
and encounter_id in (select encounter_id from encounter where voided = 0 and encounter_type = :NCDInitEnc) group by encounter_id;

update temp_ncd_section tns
left join
(select name known_chronic, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "Known chronic disease before referral")) before_referral on tns.encounter_id = before_referral.encounter_id
left join
(select name prior_chronic, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "Known chronic disease before referral")) prior_treatment on tns.encounter_id = prior_treatment.encounter_id
left join
(select name chronic_disease, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "Chronic disease controlled during initial visit"))
controlled on tns.encounter_id = controlled.encounter_id

set tns.known_chronic_disease_before_referral = before_referral.known_chronic,
     tns.prior_treatment_for_chronic_disease = prior_treatment.prior_chronic,
     tns.chronic_disease_controlled_during_initial_visit = controlled.chronic_disease;

update temp_ncd_section tns
left join obs o on o.encounter_id = tns.encounter_id and o.voided = 0 and o.concept_id = (select concept_id from report_mapping where source = "CIEL" and code = 163080)
left join obs o1 on o1.encounter_id = tns.encounter_id and o1.voided = 0 and o1.concept_id = (select concept_id from report_mapping where source = "CIEL" and code = 163081)
left join (select group_concat(name) hypertension, encounter_id
from concept_name cn join obs o on o.value_coded = cn.concept_id and concept_name_type="FULLY_SPECIFIED" and locale="en" and cn.voided = 0
and o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "Type of hypertension diagnosis") group by encounter_id) o2 on
o2.encounter_id = tns.encounter_id
set tns.waist_circumference = o.value_numeric,
    tns.hip_size =  o1.value_numeric,
    tns.hypertension_stage = o2.hypertension;

update temp_ncd_section tns
left join (select encounter_id, group_concat(name) diag from concept_name cn join obs o on
cn.concept_id = value_coded and locale = "en" and concept_name_type = "FULLY_SPECIFIED"
and (select group_concat(concept_id) from report_mapping where source = "CIEL" and code IN (142474,142473,165207,165208,1449,138291))
and o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "DIAGNOSIS")
and cn.voided = 0 and o.voided = 0 group by encounter_id) o3 on o3.encounter_id = tns.encounter_id
left join obs o4 on o4.encounter_id = tns.encounter_id and o4.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "SERUM GLUCOSE") and o4.voided = 0
left join obs o5 on o5.encounter_id = tns.encounter_id and o5.concept_id = (select concept_id from report_mapping where source = "CIEL" and code = "160912") and o5.voided = 0
left join (select group_concat(name) foot_care, encounter_id
from concept_name cn join obs o on o.value_coded = cn.concept_id and concept_name_type="FULLY_SPECIFIED" and locale="en" and cn.voided = 0
and o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "Foot care classification") group by encounter_id)
o6 on o6.encounter_id = tns.encounter_id
left join obs o7 on o7.encounter_id = tns.encounter_id and o7.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "Fasting for blood glucose test") and o7.voided = 0
left join obs o8 on o8.encounter_id = tns.encounter_id and o8.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "11974") and o8.voided = 0
set tns.diabetes_mellitus = o3.diag,
    tns.serum_glucose = o4.value_numeric,
    tns.fasting_blood_glucose_test = IF(o7.value_coded = 1, "Yes", "No"),
    tns.fasting_blood_glucose = o5.value_numeric,
    tns.managing_diabetic_foot_care = o6.foot_care,
    tns.diabetes_comment = o8.value_text;

update temp_ncd_section tns
left join (select encounter_id, group_concat(name) asthma_class from concept_name cn join obs o on cn.concept_id = value_coded
and concept_name_type = "FULLY_SPECIFIED" and locale = "en"
and o.voided = 0 and o.concept_id = (select concept_id from report_mapping where
source = "PIH" and code = "Asthma classification") group by encounter_id) o on tns.encounter_id = o.encounter_id
left join obs o1 on tns.encounter_id = o1.encounter_id and value_coded =
(select concept_id from report_mapping where source = "CIEL" and code = 121375)
and concept_id = (select concept_id from report_mapping where source = "PIH" and code = "DIAGNOSIS")
and o1.voided = 0
left join obs o2 on
tns.encounter_id = o2.encounter_id and o2.value_coded =
(select concept_id from report_mapping where source = "CIEL" and code = "121011")
and o2.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "DIAGNOSIS")
and o2.voided = 0
left join obs o3 on
tns.encounter_id = o3.encounter_id and o3.value_coded =
(select concept_id from report_mapping where source = "CIEL" and code = "1295")
and o3.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "DIAGNOSIS")
and o3.voided = 0
left join obs o4 on tns.encounter_id = o4.encounter_id and o4.voided = 0 and
o4.concept_id = (select concept_id from report_mapping where source = "PIH" and code="COPD group classification")
set tns.respiratory_diagnosis  = o.asthma_class,
     tns.probably_asthma = IF(o1.value_coded is not null, "Yes", "No"),
     tns.bronchiectasis = IF(o2.value_coded is not null, "Yes", "No"),
     tns.copd = IF(o3.value_coded is not null, "Yes", "No"),
     tns.copd_grade = (select name from concept_name where concept_id = o4.value_coded and locale = "en" and voided = 0 and concept_name_type
     = "FULLY_SPECIFIED");

 update temp_ncd_section tns
left join
(select group_concat(distinct(name)) commob, encounter_id from concept_name cn join obs o on
cn.concept_id = value_coded and o.voided = 0 and concept_name_type = "FULLY_SPECIFIED" and locale = "en" and
o.value_coded in (select concept_id from report_mapping
where source = "CIEL" and code IN (121692, 1293, 119051)) group by encounter_id) o
on tns.encounter_id = o.encounter_id
left join obs o1 on o1.voided = 0 and o1.encounter_id = tns.encounter_id and
o1.concept_id =  (select concept_id from report_mapping
where source = "PIH" and code = 7399)
left join obs o2 on o2.encounter_id = tns.encounter_id and
o2.voided = 0 and o2.concept_id = (select concept_id from report_mapping
where source = "PIH" and code = 11972)
set tns.commorbidities = o.commob,
    tns.inhaler_training = IF(o1.value_coded = 1, "Yes", "No"),
    tns.pulmonary_comment = o2.value_text
;
update temp_ncd_section tns
left join
(
select group_concat(name) heart_failure_category, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "DIAGNOSIS") and
value_coded in
(select concept_id from report_mapping where (source = "CIEL" and code in (5016, 134082, 130562, 5622)) OR (source = "PIH" and
code in (3071, 12231, 4000)))  group by encounter_id
) category_of_heart_failure on category_of_heart_failure.encounter_id = tns.encounter_id
left join
(
select group_concat(name) nyha_class, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "NYHA CLASS")
group by encounter_id) nyha_classes on nyha_classes.encounter_id = tns.encounter_id
left join
(
select group_concat(name) fluid, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "PATIENTS FLUID MANAGEMENT")
group by encounter_id) fluid_statuses on fluid_statuses.encounter_id = tns.encounter_id
left join
(
select group_concat(name) cardiomyopathy, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "DIAGNOSIS")
and o.value_coded in
(select concept_id from report_mapping where source = "CIEL" and code in (113918,163712,142317,139529,5016))
group by encounter_id) cardiomy on cardiomy.encounter_id = tns.encounter_id
left join
obs o on tns.encounter_id = o.encounter_id and o.voided = 0 and o.concept_id =
(select concept_id from report_mapping where source = "PIH" and code = 11926)
left join
obs o1 on tns.encounter_id = o1.encounter_id and o1.voided = 0 and o1.concept_id =
(select concept_id from report_mapping where source = "PIH" and code = 11973)

set tns.categories_of_heart_failure = category_of_heart_failure.heart_failure_category,
     tns.nyha_class = nyha_classes.nyha_class,
     tns.fluid_status = fluid_statuses.fluid,
     tns.cardiomyopathy = cardiomy.cardiomyopathy,
     tns.heart_failure_improbable =IF(o.value_coded = 1, "Yes", "No"),
     tns.heart_remarks = o1.value_text
     ;

update temp_ncd_section tns
left join
(
select group_concat(name) systolic_fxn, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "Left ventricle systolic function")
group by encounter_id) left_systolic on left_systolic.encounter_id = tns.encounter_id
left join
(
select group_concat(name) ventricle_dim, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "Right ventricle dimension")
group by encounter_id) right_ventricle on right_ventricle.encounter_id = tns.encounter_id
left join
(
select group_concat(name) valve_findings, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "MITRAL VALVE FINDINGS")
group by encounter_id) valve_finds on valve_finds.encounter_id = tns.encounter_id
left join
(
select group_concat(name) pericardium_findings, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "PERICARDIUM FINDINGS")
group by encounter_id) pericardium_finds on pericardium_finds.encounter_id = tns.encounter_id
left join
(
select group_concat(name) cava_findings, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "Inferior vena cava findings")
group by encounter_id) inferior_vena on tns.encounter_id = inferior_vena.encounter_id
left join
(
select group_concat(name) quality, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "CIEL" and code = "165253")
group by encounter_id) quality_findings on quality_findings.encounter_id = tns.encounter_id
left join
obs o on tns.encounter_id = o.encounter_id and o.voided = 0 and o.concept_id =
(select concept_id from report_mapping where source = "PIH" and code = 3407)
set tns.left_ventricle_systolic_function = left_systolic.systolic_fxn,
	tns.right_ventricle_dimension = right_ventricle.ventricle_dim,
	tns.mitral_valve_finding =  valve_finds.valve_findings,
    tns.pericardium_findings = pericardium_finds.pericardium_findings,
    tns.inferior_vena_cava_findings = inferior_vena.cava_findings,
    tns.quality = quality_findings.quality,
    tns.additional_comments = o.value_text;

-- medications
update temp_ncd_section tns
left join
(
select group_concat(name) other_disease, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "DIAGNOSIS")
and o.value_coded in
(select concept_id from report_mapping where (source = "CIEL" and code in (119624, 5622, 113504, 148203, 117441, 115115))
or (source = "PIH" and code = 3181))
group by encounter_id) other_category on other_category.encounter_id = tns.encounter_id
left join obs o on o.encounter_id = tns.encounter_id and o.voided = 0 and o.concept_id
= (select concept_id from report_mapping where source = "PIH" and code = "Diagnosis or problem, non-coded")
left join
(
select group_concat(name) medicine, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "10555")
group by encounter_id) medice_past_two_days on tns.encounter_id = medice_past_two_days.encounter_id
left join
(
select group_concat(name) adherence, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "3140")
group by encounter_id) adherence_info on tns.encounter_id = adherence_info.encounter_id
left join
(
select group_concat(name) medicine, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "MEDICATION ORDERS")
and o.value_coded in
(select concept_id from report_mapping where (source = "CIEL" and code in
(71617, 71138, 73602, 75634, 77676, 79766, 82734, 83936))
or (source = "PIH" and code in (3186, 3185, 3182, 99, 1243, 3428, 3183, 251, 250, 4061, 3190)))
group by encounter_id)cardiovascular on cardiovascular.encounter_id = tns.encounter_id
left join
(
select group_concat(name) medicine, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "MEDICATION ORDERS")
and o.value_coded in
(select concept_id from report_mapping where (source = "CIEL" and code in
(78200, 80092))
or (source = "PIH" and code in (1240, 798)))
group by encounter_id) respiratory on respiratory.encounter_id = tns.encounter_id
left join
(
select group_concat(name) medicine, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "MEDICATION ORDERS")
and o.value_coded in
(select concept_id from report_mapping where (source = "CIEL" and code in
(78082, 78068, 79652))
or (source = "PIH" and code in (4046, 6746, 765)))
group by encounter_id) endocrine on endocrine.encounter_id = tns.encounter_id
left join
(
select group_concat(name) medicine, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "MEDICATION ORDERS")
and o.value_coded in
(select concept_id from report_mapping where (source = "CIEL" and code in
(75018, 81730))
or (source = "PIH" and code in (4034, 2293, 960, 95, 1244, 4057, 923)))
group by encounter_id) other_meds on other_meds.encounter_id = tns.encounter_id

set tns.other_disease_category = other_category.other_disease,
    tns.other_non_coded_diagnosis = o.value_text,
    tns.medice_past_two_days = medice_past_two_days.medicine,
    tns.reason_poor_compliance = adherence_info.adherence,
    tns.cardiovascular_medication = cardiovascular.medicine,
    tns.respiratory_medication = respiratory.medicine,
    tns.endocrine_medication = endocrine.medicine,
    tns.other_medication = other_meds.medicine;

-- obs join
CREATE TEMPORARY table temp_obs_join
AS
(
SELECT
     o.encounter_id,
    (SELECT date_started FROM visit WHERE visit_id = e.visit_id) visit_date,
    visit_id,
    MAX(DATE(CASE
            WHEN e.encounter_id = o.encounter_id THEN e.encounter_datetime
        END)) 'encounter_date',
-- Encounter Type
GROUP_CONCAT(DISTINCT(CASE WHEN e.encounter_id = o.encounter_id THEN (SELECT name FROM encounter_type WHERE encounter_type_id = e.encounter_type) END)
    SEPARATOR ', ') visit_type,
    MAX(CASE
        WHEN
            rm.source = 'PIH'
                AND rm.code = 'Type of referring service'
        THEN
            cn.name
    END) 'Type_of_referring_service',
    MAX(CASE
        WHEN
            rm.source = 'PIH'
                AND rm.code = 'Known chronic disease before referral'
        THEN
            cn.name
    END) 'Known_disease_before_referral',
    MAX(CASE
        WHEN
            rm.source = 'PIH'
                AND rm.code = 'Prior treatment for chronic disease'
        THEN
            cn.name
    END) 'Prior_treatment',
    MAX(CASE
        WHEN
            rm.source = 'PIH'
                AND rm.code = 'Chronic disease controlled during initial visit'
        THEN
            cn.name
    END) 'Disease_controlled_initial_visit',
    GROUP_CONCAT(CASE
            WHEN
                rm.source = 'PIH'
                    AND rm.code = 'NCD category'
            THEN
                cn.name
        END
        SEPARATOR ', ') 'NCD_category',
    MAX(CASE
        WHEN
            rm.source = 'PIH'
                AND rm.code = 'NCD category'
        THEN
            o.comments
    END) 'Other_NCD_category',
    MAX(CASE
        WHEN rm.source = 'CIEL' AND rm.code = '5089' THEN o.value_numeric
    END) 'Weight_kg',
    MAX(CASE
        WHEN rm.source = 'CIEL' AND rm.code = '5090' THEN o.value_numeric
    END) 'Height_cm',
    ROUND(MAX(CASE
                WHEN rm.source = 'CIEL' AND rm.code = '5089' THEN o.value_numeric
            END) / ((MAX(CASE
                WHEN rm.source = 'CIEL' AND rm.code = '5090' THEN o.value_numeric
            END) / 100) * (MAX(CASE
                WHEN rm.source = 'CIEL' AND rm.code = '5090' THEN o.value_numeric
            END) / 100)),
            1) 'BMI',
    MAX(CASE
        WHEN rm.source = 'CIEL' AND rm.code = '5085' THEN o.value_numeric
    END) 'Systolic_BP',
    MAX(CASE
        WHEN rm.source = 'CIEL' AND rm.code = '5086' THEN o.value_numeric
    END) 'Diastolic_BP',
    MAX(CASE
        WHEN
            rm.source = 'CIEL'
                AND rm.code = '163080'
        THEN
            o.value_numeric
    END) 'Waist_cm',
    MAX(CASE
        WHEN
            rm.source = 'CIEL'
                AND rm.code = '163081'
        THEN
            o.value_numeric
    END) 'hip_cm',
    ROUND(MAX(CASE
                WHEN
                    rm.source = 'CIEL'
                        AND rm.code = '163080'
                THEN
                    o.value_numeric
            END) / MAX(CASE
                WHEN
                    rm.source = 'CIEL'
                        AND rm.code = '163081'
                THEN
                    o.value_numeric
            END),
            2) 'Waist/Hip Ratio',

    MAX(CASE
        WHEN
            rm.source = 'PIH'
                AND rm.code = 'PATIENTS FLUID MANAGEMENT'
        THEN
            cn.name
    END) 'Patients_Fluid_Management',
    GROUP_CONCAT(CASE
            WHEN
                rm.source = 'PIH'
                    AND rm.code = 'Type of diabetes diagnosis'
            THEN
                cn.name
        END
        SEPARATOR ', ') 'Diabetes_type',
    MAX(CASE
        WHEN
            rm.source = 'PIH'
                AND rm.code = 'Hypoglycemia symptoms'
        THEN
            cn.name
    END) 'Hypoglycemia_symptoms',
    MAX(CASE
        WHEN
            rm.source = 'PIH'
                AND rm.code = 'Puffs per week of salbutamol'
        THEN
            o.value_numeric
    END) 'Puffs_week_salbutamol',
    MAX(CASE
        WHEN
            rm.source = 'PIH'
                AND rm.code = 'Asthma classification'
        THEN
            cn.name
    END) 'Asthma_classification',
    MAX(CASE
        WHEN
            rm.source = 'PIH'
                AND rm.code = 'Number of seizures since last visit'
        THEN
            o.value_numeric
    END) 'Number_seizures_since_last_visit',
    MAX(CASE
        WHEN
            rm.source = 'PIH'
                AND rm.code = 'Appearance at appointment time'
        THEN
            cn.name
    END) 'Adherance_to_appointment',
    MAX(CASE
        WHEN
            rm.source = 'PIH'
                AND rm.code = 'Lack of meds in last 2 days'
        THEN
            cn.name
    END) 'Lack_of_meds_2_days',
    MAX(CASE
        WHEN
            rm.source = 'PIH'
                AND rm.code = 'PATIENT HOSPITALIZED SINCE LAST VISIT'
        THEN
            cn.name
    END) 'Patient_hospitalized_since_last_visit',
    GROUP_CONCAT(CASE
            WHEN
                rm.source = 'PIH'
                    AND rm.code = 'Medications prescribed at end of visit'
            THEN
                cn.name
        END
        SEPARATOR ',') 'Medications_Prescribed',
    MAX(CASE
        WHEN
            rm.source = 'PIH'
                AND rm.code = 'Medications prescribed at end of visit'
        THEN
            o.comments
    END) 'Other_meds',
    MAX(CASE
        WHEN
            rm.source = 'CIEL'
                AND rm.code = '159644'
        THEN
            o.value_numeric
    END) 'HbA1c',
    MAX(CASE
        WHEN
            rm.source = 'PIH'
                AND rm.code = 'PATIENT PLAN COMMENTS'
        THEN
            o.value_text
    END) 'Patient_Plan_Comments',
     MAX(CASE
         WHEN
             rm.source = 'PIH'
             AND rm.code = 'RETURN VISIT DATE'
             THEN
                 o.value_datetime
         END) 'Next_NCD_appointment'
FROM encounter e, report_mapping rm, obs o
LEFT OUTER JOIN concept_name cn ON o.value_coded = cn.concept_id AND cn.locale = 'en' AND cn.locale_preferred = '1'  AND cn.voided = 0
LEFT OUTER JOIN obs obs2 ON obs2.obs_id = o.obs_group_id
LEFT OUTER JOIN report_mapping obsgrp ON obsgrp.concept_id = obs2.concept_id
WHERE 1=1
AND
e.encounter_id IN
(
   SELECT e3.encounter_id
   FROM encounter e3
     INNER JOIN
    (SELECT visit_id, encounter_type, MAX(encounter_datetime) AS enc_date
    FROM encounter
     WHERE 1=1
     AND encounter_type IN (:NCDInitEnc, :NCDFollowEnc, :vitEnc, :labResultEnc)
      GROUP BY visit_id,encounter_type) maxdate
     ON maxdate.visit_id = e3.visit_id AND e3.encounter_type= maxdate.encounter_type AND e3.encounter_datetime = maxdate.enc_date
)
AND rm.concept_id = o.concept_id
AND o.encounter_id = e.encounter_id
AND e.voided = 0
AND o.voided = 0
GROUP BY e.visit_id
);

SELECT
    p.patient_id,
    zl.identifier zlemr,
    zl_loc.name loc_registered,
    un.value unknown_patient,
    DATE(pp.date_enrolled) enrolled_in_program,
	cn_state.name program_state,
	cn_out.name program_outcome,
    pr.gender,
    ROUND(DATEDIFF(e.encounter_datetime, pr.birthdate) / 365.25,
            1) age_at_enc,
    pa.state_province department,
    pa.city_village commune,
    pa.address3 section,
    pa.address1 locality,
    pa.address2 street_landmark,
    el.name encounter_location,
    CONCAT(pn.given_name, ' ', pn.family_name) provider,
    known_chronic_disease_before_referral,
    prior_treatment_for_chronic_disease,
    chronic_disease_controlled_during_initial_visit,
    temp_obs_join.*,
    disease_category,
    comments,
    waist_circumference,
    hip_size,
    hypertension_stage,
    diabetes_mellitus,
    serum_glucose,
    fasting_blood_glucose_test,
    fasting_blood_glucose,
    managing_diabetic_foot_care,
    diabetes_comment,
    probably_asthma,
    respiratory_diagnosis,
    bronchiectasis,
    copd,
    copd_grade,
    commorbidities,
    inhaler_training,
    pulmonary_comment,
    categories_of_heart_failure,
    nyha_class,
    fluid_status,
    cardiomyopathy,
    heart_failure_improbable,
    heart_remarks,
    left_ventricle_systolic_function,
    right_ventricle_dimension,
    mitral_valve_finding,
    pericardium_findings,
    inferior_vena_cava_findings,
    quality,
    additional_comments,
    other_disease_category,
    other_non_coded_diagnosis,
    medice_past_two_days,
    reason_poor_compliance,
    cardiovascular_medication,
    respiratory_medication,
    endocrine_medication,
    other_medication
FROM
    patient p
-- Most recent ZL EMR ID
INNER JOIN (SELECT patient_id, identifier, location_id FROM patient_identifier WHERE identifier_type = :zlId
            AND voided = 0 AND preferred = 1 ORDER BY date_created DESC) zl ON p.patient_id = zl.patient_id
-- ZL EMR ID location
INNER JOIN location zl_loc ON zl.location_id = zl_loc.location_id
-- Unknown patient
LEFT OUTER JOIN person_attribute un ON p.patient_id = un.person_id AND un.person_attribute_type_id = :unknownPt
            AND un.voided = 0
-- Gender
INNER JOIN person pr ON p.patient_id = pr.person_id AND pr.voided = 0
--  Most recent address
LEFT OUTER JOIN (SELECT * FROM person_address WHERE voided = 0 ORDER BY date_created DESC) pa ON p.patient_id = pa.person_id
INNER JOIN (SELECT person_id, given_name, family_name FROM person_name WHERE voided = 0 ORDER BY date_created DESC) n ON p.patient_id = n.person_id
INNER JOIN encounter e ON p.patient_id = e.patient_id AND e.voided = 0 AND e.encounter_type IN (:NCDInitEnc, :NCDFollowEnc, :vitEnc, :labResultEnc)
INNER JOIN location el ON e.location_id = el.location_id
-- UUID of NCD program
LEFT JOIN patient_program pp ON pp.patient_id = p.patient_id AND pp.voided = 0 AND pp.program_id IN
      (SELECT program_id FROM program WHERE uuid = '515796ec-bf3a-11e7-abc4-cec278b6b50a') -- uuid of the NCD program
-- patient state
LEFT OUTER JOIN patient_state ps ON ps.patient_program_id = pp.patient_program_id AND ps.end_date IS NULL AND ps.voided = 0
LEFT OUTER JOIN program_workflow_state pws ON pws.program_workflow_state_id = ps.state AND pws.retired = 0
LEFT OUTER JOIN concept_name cn_state ON cn_state.concept_id = pws.concept_id  AND cn_state.locale = 'en' AND cn_state.locale_preferred = '1'  AND cn_state.voided = 0
-- outcome
LEFT OUTER JOIN concept_name cn_out ON cn_out.concept_id = pp.outcome_concept_id AND cn_out.locale = 'en' AND cn_out.locale_preferred = '1'  AND cn_out.voided = 0
--  Provider Name
INNER JOIN encounter_provider ep ON ep.encounter_id = e.encounter_id AND ep.voided = 0
INNER JOIN provider pv ON pv.provider_id = ep.provider_id
INNER JOIN person_name pn ON pn.person_id = pv.person_id AND pn.voided = 0
-- Straight Obs Joins
INNER JOIN
temp_obs_join ON temp_obs_join.encounter_id = ep.encounter_id
-- NCD section
LEFT JOIN temp_ncd_section on temp_ncd_section.encounter_id = e.encounter_id
WHERE p.voided = 0
-- exclude test patients
AND p.patient_id NOT IN (SELECT person_id FROM person_attribute WHERE value = 'true' AND person_attribute_type_id = :testPt
                         AND voided = 0)
-- Remove all the empty ncd forms.
AND e.visit_id IN (SELECT enc.visit_id FROM encounter enc WHERE encounter_type IN (:NCDInitEnc, :NCDFollowEnc)
AND enc.encounter_id IN (SELECT obs.encounter_id FROM obs JOIN encounter ON
 patient_id = person_id AND encounter_type IN (:NCDInitEnc, :NCDFollowEnc) AND obs.voided = 0))
AND DATE(e.encounter_datetime) >= :startDate
AND DATE(e.encounter_datetime) <= :endDate
GROUP BY e.encounter_id ORDER BY p.patient_id;
