DROP TEMPORARY TABLE IF EXISTS temp_mentalhealth_visit;

SET sql_safe_updates = 0;
SET SESSION group_concat_max_len = 100000;

set @startDate = "1900-01-01";
set @endDate = "2019-11-07";

set @encounter_type = encounter_type('Mental Health Consult');
set @role_of_referring_person = concept_from_mapping('PIH','Role of referring person');
set @other_referring_person = concept_from_mapping('PIH','OTHER');
set @type_of_referral_role = concept_from_mapping('PIH','Type of referral role');
set @other_referring_role_type = concept_from_mapping('PIH','OTHER');
set @hospitalization = concept_from_mapping('CIEL','976');
set @hospitalization_reason = concept_from_mapping('CIEL','162879');
set @type_of_patient =  concept_from_mapping('PIH', 'TYPE OF PATIENT');
set @inpatient_hospitalization = concept_from_mapping('PIH','INPATIENT HOSPITALIZATION');
set @traumatic_event = concept_from_mapping('PIH','12362');
set @yes =   concept_from_mapping('PIH', 'YES');
set @adherence_to_appt = concept_from_mapping('PIH','Appearance at appointment time');
set @depression_screening = concept_from_Mapping('CIEL','165554');
set @zldsi_score = concept_from_Mapping('CIEL','163225');
set @ces_dc = concept_from_Mapping('CIEL','163228');
set @psc_35 = concept_from_Mapping('CIEL','165534');
set @pcl = concept_from_Mapping('CIEL','165535');
set @cgi_s = concept_from_Mapping('CIEL','163222');
set @cgi_i = concept_from_Mapping('CIEL','163223');
set @cgi_e = concept_from_Mapping('CIEL','163224');
set @whodas = concept_from_Mapping('CIEL','163226');
set @days_with_difficulties = concept_from_mapping('PIH','Days with difficulties in past month');
set @days_without_usual_activity = concept_from_mapping('PIH','Days without usual activity in past month');
set @days_with_less_activity = concept_from_mapping('PIH','Days with less activity in past month');
set @aims = concept_from_mapping('CIEL','163227');
set @seizure_frequency = concept_from_mapping('PIH','Number of seizures in the past month');
set @past_suicidal_evaluation = concept_from_mapping('CIEL','1628');
set @current_suicidal_evaluation = concept_from_mapping('PIH','Mental health diagnosis');
set @last_suicide_attempt_date = concept_from_mapping('CIEL','165530');
set @suicidal_screen_completed = concept_from_mapping('PIH','Suicidal evaluation');
set @suicidal_screening_result = concept_from_mapping('PIH', 'Result of suicide risk evaluation');
set @security_plan = concept_from_mapping('PIH','Security plan');
set @discuss_patient_with_supervisor = concept_from_mapping('CIEL', '165532');
set @hospitalize_due_to_suicide_risk = concept_from_mapping('CIEL', '165533');
set @mh_diagnosis = concept_from_mapping('PIH','Mental health diagnosis');
set @hum_diagnoses = concept_from_mapping('PIH','HUM Psychological diagnoses');
set @mental_health_intervention = concept_from_mapping('PIH','Mental health intervention');
set @other = concept_from_mapping('PIH','OTHER');
set @medication = concept_from_mapping('PIH', 'Mental health medication');
set @medication_comments = concept_from_mapping('PIH', 'Medication comments (text)');
set @pregnant = concept_from_mapping('CIEL', '5272');
set @last_menstruation_date = concept_from_mapping('PIH','DATE OF LAST MENSTRUAL PERIOD');
set @estimated_delivery_date = concept_from_mapping('PIH','ESTIMATED DATE OF CONFINEMENT');
set @type_of_provider = concept_from_mapping('PIH','Type of provider');
set @disposition = concept_from_mapping('PIH','HUM Disposition categories');
set @disposition_comment = concept_from_mapping('PIH','PATIENT PLAN COMMENTS');
set @return_date = concept_from_mapping('PIH','RETURN VISIT DATE');


create temporary table temp_mentalhealth_visit
(
patient_id int,
zl_emr_id varchar(255),
gender varchar(50),
unknown_patient text,
patient_address text,
provider varchar(255),
loc_registered varchar(255),
location_id int,
enc_location varchar(255),
encounter_id int,
encounter_date datetime,
age_at_enc double,
visit_date date,
visit_id int,
referred_from_community_by varchar(255),
other_referring_person varchar(255),
type_of_referral_role varchar(255),
other_referring_role_type varchar(255),
hospitalized_since_last_visit varchar(50),
hospitalization_reason text,
hospitalized_at_time_of_visit varchar(50),
traumatic_event varchar(50),
adherence_to_appt varchar(225),
depression_screening varchar(255),
zldsi_score double,
ces_dc double,
psc_35 double,
pcl double,
cgi_s double,
cgi_i double,
cgi_e double,
whodas double,
days_with_difficulties double,
days_without_usual_activity double,
days_with_less_activity double,
aims varchar(255),
seizure_frequency double,
past_suicidal_evaluation varchar(255),
current_suicidal_evaluation varchar(255),
last_suicide_attempt_date date,
suicidal_screen_completed varchar(50),
suicidal_screening_result varchar(255),
high_result_for_suicidal_screening text,
diagnosis text,
psychological_intervention text,
other_psychological_intervention text,
medication text,
medication_comments text,
pregnant varchar(50),
last_menstruation_date date,
estimated_delivery_date date,
type_of_provider text,
type_of_referral_roles text,
disposition varchar(255),
disposition_comment varchar(255),
return_date date
);

insert into temp_mentalhealth_visit (   patient_id,
										zl_emr_id, gender,
                                        encounter_id,
                                        encounter_date,
                                        age_at_enc,
                                        provider,
                                        patient_address,
                                        -- loc_registered,
                                        location_id,
                                        -- visit_date,
                                        visit_id
                                        )
select patient_id,
	   zlemr(patient_id),
       gender(patient_id),
       encounter_id,
       encounter_datetime,
       age_at_enc(patient_id, encounter_id),
       provider(encounter_id),
       person_address(patient_id),
       -- loc_registered(patient_id),
       location_id,
       -- visit_date(patient_id),
       visit_id
 from encounter where voided = 0 and encounter_type = @encounter_type
-- filter by date
 AND date(encounter_datetime) >=  date(@startDate)
 AND date(encounter_datetime) <=  date(@endDate)
;

-- exclude test patients
delete from temp_mentalhealth_visit where
patient_id IN (SELECT person_id FROM person_attribute WHERE value = 'true' AND person_attribute_type_id = (select
person_attribute_type_id from person_attribute_type where name = "Test Patient")
                         AND voided = 0)
;

-- unknown patient
update temp_mentalhealth_visit tmhv
set tmhv.unknown_patient = IF(tmhv.patient_id = unknown_patient(tmhv.patient_id), 'true', NULL);
-- location
update temp_mentalhealth_visit tmhv
left join location l on tmhv.location_id = l.location_id
set tmhv.enc_location = l.name;

-- Role of referring person
update temp_mentalhealth_visit tmhv
left join
(
select encounter_id,  group_concat(name separator ' | ') names  from obs o join concept_name cn on cn.concept_id = o.value_coded and cn.voided = 0
and o.voided = 0 and o.concept_id = @role_of_referring_person and cn.locale = "fr" and concept_name_type = "FULLY_SPECIFIED"
group by encounter_id
) o on o.encounter_id = tmhv.encounter_id
set tmhv.referred_from_community_by = o.names;

update temp_mentalhealth_visit tmhv
set tmhv.other_referring_person = (select comments from obs where voided = 0 and encounter_id = tmhv.encounter_id and value_coded = @other_referring_person
and concept_id = @role_of_referring_person);

update temp_mentalhealth_visit tmhv
left join
(
select encounter_id, group_concat(name separator ' | ') names from obs o join concept_name cn on cn.concept_id = o.value_coded and cn.voided = 0
and o.voided = 0 and o.concept_id = @type_of_referral_role and cn.locale = "fr" and concept_name_type = "FULLY_SPECIFIED"
group by encounter_id
) o on o.encounter_id = tmhv.encounter_id
set tmhv.type_of_referral_role = o.names;

update temp_mentalhealth_visit tmhv
set tmhv.other_referring_role_type = (select comments from obs where voided = 0 and encounter_id = tmhv.encounter_id and value_coded = @other_referring_role_type
and concept_id = @type_of_referral_role);

-- hospitalization
update temp_mentalhealth_visit tmhv
set tmhv.hospitalized_since_last_visit = (select concept_name(value_coded, 'fr') from obs where voided = 0 and concept_id = @hospitalization and tmhv.encounter_id = encounter_id);

update temp_mentalhealth_visit tmhv
set tmhv.hospitalization_reason = (select value_text from obs where voided = 0 and concept_id = @hospitalization_reason and tmhv.encounter_id = encounter_id);

update temp_mentalhealth_visit tmhv
set tmhv.hospitalization_reason = (select value_text from obs where voided = 0 and concept_id = @hospitalization_reason and tmhv.encounter_id = encounter_id);

update temp_mentalhealth_visit tmhv
set tmhv.hospitalized_at_time_of_visit = IF(@inpatient_hospitalization=(select value_coded from obs where voided = 0 and concept_id = @type_of_patient
and tmhv.encounter_id = encounter_id), 'Oui', Null);

-- traumatic event
update temp_mentalhealth_visit tmhv
set tmhv.traumatic_event = IF(@yes=(select value_coded from obs where voided = 0 and concept_id = @traumatic_event
and tmhv.encounter_id = encounter_id), 'Oui', Null);

-- Adherence to appointment day
update temp_mentalhealth_visit tmhv
set tmhv.adherence_to_appt = (select concept_name(value_coded, 'fr') from obs where voided = 0 and concept_id = @adherence_to_appt
and tmhv.encounter_id = encounter_id);

update temp_mentalhealth_visit tmhv
left join
(select group_concat(cn.name separator ' | ') names, encounter_id from concept_name cn join obs o on o.voided = 0 and cn.voided = 0 and
value_coded = cn.concept_id and locale='fr' and concept_name_type = "FULLY_SPECIFIED" and o.concept_id = @depression_screening group by encounter_id) o on tmhv.encounter_id = o.encounter_id
set tmhv.depression_screening = o.names;

-- scores
update temp_mentalhealth_visit tmhv
set tmhv.zldsi_score = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @zldsi_score);

update temp_mentalhealth_visit tmhv
set tmhv.ces_dc = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @ces_dc);

update temp_mentalhealth_visit tmhv
set tmhv.psc_35 = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @psc_35);

update temp_mentalhealth_visit tmhv
set tmhv.pcl = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @pcl);

update temp_mentalhealth_visit tmhv
set tmhv.cgi_s = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @cgi_s);

update temp_mentalhealth_visit tmhv
set tmhv.cgi_i = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @cgi_i);

update temp_mentalhealth_visit tmhv
set tmhv.cgi_e = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @cgi_e);

update temp_mentalhealth_visit tmhv
set tmhv.whodas = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @whodas);

update temp_mentalhealth_visit tmhv
set tmhv.days_with_difficulties = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @days_with_difficulties);

update temp_mentalhealth_visit tmhv
set tmhv.days_without_usual_activity = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @days_without_usual_activity);

update temp_mentalhealth_visit tmhv
set tmhv.days_with_less_activity = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @days_with_less_activity);

update temp_mentalhealth_visit tmhv
set tmhv.aims = (select concept_name(value_coded, 'fr') from obs where voided = 0 and concept_id = @aims and tmhv.encounter_id = encounter_id);

update temp_mentalhealth_visit tmhv
set tmhv.seizure_frequency = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @seizure_frequency);

update temp_mentalhealth_visit tmhv
left join
(
select group_concat(cn.name separator ' | ') names, encounter_id from concept_name cn join obs o on o.voided = 0 and cn.voided = 0 and
value_coded = cn.concept_id and locale='fr' and concept_name_type = "FULLY_SPECIFIED" and o.concept_id = @past_suicidal_evaluation group by encounter_id) o
on tmhv.encounter_id = o.encounter_id
set tmhv.past_suicidal_evaluation  = o.names;

update temp_mentalhealth_visit tmhv
left join
(
select group_concat(cn.name separator ' | ') names, encounter_id from concept_name cn join obs o on o.voided = 0 and cn.voided = 0 and
value_coded = cn.concept_id and locale='fr' and concept_name_type = "FULLY_SPECIFIED" and o.concept_id = @current_suicidal_evaluation group by encounter_id) o
on tmhv.encounter_id = o.encounter_id
set tmhv.current_suicidal_evaluation  = o.names;

update temp_mentalhealth_visit tmhv
set tmhv.last_suicide_attempt_date = (select date(value_datetime) from obs where concept_id = @last_suicide_attempt_date and voided = 0 and tmhv.encounter_id = obs.encounter_id);

update temp_mentalhealth_visit tmhv
set tmhv.suicidal_screen_completed = IF(1=(select value_coded from obs where concept_id = @suicidal_screen_completed and voided = 0 and tmhv.encounter_id = obs.encounter_id),'Oui', Null);

update temp_mentalhealth_visit tmhv
set tmhv.suicidal_screening_result = (select concept_name(value_coded, 'fr') from obs where voided = 0 and concept_id = @suicidal_screening_result and tmhv.encounter_id = obs.encounter_id);

update temp_mentalhealth_visit tmhv
left join
(
select group_concat(cn.name separator ' | ') names, encounter_id from concept_name cn join obs o on o.voided = 0 and cn.voided = 0 and
value_coded = cn.concept_id and locale='fr' and concept_name_type = "FULLY_SPECIFIED" and o.concept_id = @current_suicidal_evaluation group by encounter_id) o
on tmhv.encounter_id = o.encounter_id
set tmhv.current_suicidal_evaluation  = o.names;

update temp_mentalhealth_visit tmhv
left join
(
select group_concat(cn.name separator ' | ') names, encounter_id from concept_name cn join obs o on o.voided = 0 and cn.voided = 0 and
value_coded = cn.concept_id and locale='fr' and concept_name_type = "FULLY_SPECIFIED" and o.value_coded in (@security_plan, @discuss_patient_with_supervisor, @hospitalize_due_to_suicide_risk) group by encounter_id
) o on tmhv.encounter_id = o.encounter_id
set tmhv.high_result_for_suicidal_screening = o.names;

update temp_mentalhealth_visit tmhv
left join
(
select group_concat(cn.name separator ' | ') names, encounter_id from concept_name cn join obs o on o.voided = 0 and cn.voided = 0 and
value_coded = cn.concept_id and locale='fr' and concept_name_type = "FULLY_SPECIFIED" and o.concept_id = @mh_diagnosis
-- and value_coded in (select concept_id from concept_set where concept_set = @hum_diagnoses)
group by encounter_id
) o on tmhv.encounter_id = o.encounter_id
set tmhv.diagnosis = o.names;

update temp_mentalhealth_visit tmhv
left join
(
select group_concat(cn.name separator ' | ') names, encounter_id from concept_name cn join obs o on o.voided = 0 and cn.voided = 0 and
value_coded = cn.concept_id and locale='fr' and concept_name_type = "FULLY_SPECIFIED" and o.concept_id = @mental_health_intervention
group by encounter_id
) o on tmhv.encounter_id = o.encounter_id
set tmhv.psychological_intervention = o.names,
	tmhv.other_psychological_intervention = (select comments from obs where voided = 0 and concept_id = @mental_health_intervention and value_coded = @other and tmhv.encounter_id = obs.encounter_id);

update temp_mentalhealth_visit tmhv
left join
(
select group_concat(d.name separator ' | ') names, encounter_id from obs o join drug d on d.concept_id = o.value_coded and o.voided = 0 and o.concept_id = @medication
and d.retired = 0
group by encounter_id
) o on tmhv.encounter_id = o.encounter_id
set tmhv.medication = o.names,
	tmhv.medication_comments = (select value_text from obs where voided = 0 and tmhv.encounter_id = obs.encounter_id and concept_id = @medication_comments);

update temp_mentalhealth_visit tmhv
set tmhv.pregnant = IF(1=(select value_coded from obs where voided = 0 and concept_id = @pregnant
and tmhv.encounter_id = encounter_id), 'Oui', Null),
	tmhv.last_menstruation_date = (select date(value_datetime) from obs where voided = 0 and concept_id = @last_menstruation_date and tmhv.encounter_id = obs.encounter_id),
    tmhv.estimated_delivery_date = (select date(value_datetime) from obs where voided = 0 and concept_id = @estimated_delivery_date and tmhv.encounter_id = obs.encounter_id);

update temp_mentalhealth_visit tmhv
left join
(
select group_concat(cn.name separator ' | ') names, encounter_id from concept_name cn join obs o on o.voided = 0 and cn.voided = 0 and
value_coded = cn.concept_id and locale='fr' and concept_name_type = "FULLY_SPECIFIED" and o.concept_id = @type_of_provider group by encounter_id
) o on tmhv.encounter_id = o.encounter_id
set tmhv.type_of_provider = o.names;

update temp_mentalhealth_visit tmhv
left join
(
select group_concat(cn.name separator ' | ') names, encounter_id from concept_name cn join obs o on o.voided = 0 and cn.voided = 0 and
value_coded = cn.concept_id and locale='fr' and concept_name_type = "FULLY_SPECIFIED" and o.concept_id = @type_of_referral_role group by encounter_id
) o on tmhv.encounter_id = o.encounter_id
set tmhv.type_of_referral_roles = o.names;

update temp_mentalhealth_visit tmhv
set tmhv.disposition = (select concept_name(value_coded, 'fr') from obs where concept_id = @disposition and voided = 0 and tmhv.encounter_id = obs.encounter_id),
	tmhv.disposition_comment = (select value_text from obs where concept_id = @disposition_comment and voided = 0 and tmhv.encounter_id = obs.encounter_id),
    tmhv.return_date = (select date(value_datetime) from obs where concept_id = @return_date and voided = 0 and tmhv.encounter_id = obs.encounter_id);


select
encounter_id,
patient_id,
zl_emr_id,
gender,
unknown_patient,
person_address_state_province(patient_id) 'province',
person_address_city_village(patient_id) 'city_village',
person_address_three(patient_id) 'address3',
person_address_one(patient_id) 'address1',
person_address_two(patient_id) 'address2',
provider,
enc_location,
encounter_date,
age_at_enc,
referred_from_community_by,
other_referring_person,
type_of_referral_role,
other_referring_role_type,
hospitalized_since_last_visit,
hospitalization_reason,
hospitalized_at_time_of_visit,
traumatic_event,
adherence_to_appt,
depression_screening,
zldsi_score,
ces_dc,
psc_35,
pcl,
cgi_s,
cgi_i,
cgi_e,
whodas,
days_with_difficulties,
days_without_usual_activity,
days_with_less_activity,
aims,
seizure_frequency,
past_suicidal_evaluation,
last_suicide_attempt_date,
suicidal_screen_completed,
suicidal_screening_result,
high_result_for_suicidal_screening,
diagnosis,
psychological_intervention,
other_psychological_intervention,
medication,
medication_comments,
type_of_provider,
type_of_referral_roles,
disposition,
disposition_comment,
return_date
from temp_mentalhealth_visit;
