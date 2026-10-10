-- Verificación tras aplicar aplicar_cron_parcial_capsoul.sql

select jobid, jobname, schedule
from cron.job
where jobname like 'capsoul-%'
order by jobname;

select jobid, status, start_time, end_time, return_message
from cron.job_run_details
order by start_time desc
limit 15;
