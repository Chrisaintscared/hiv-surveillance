// assets/js/supabaseClient.js
const SUPABASE_URL = 'https://vqwlrrhrgpiiualbetsf.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_dHKEoT8RgBRTwTYuQCJsbA_VzFJ0Jae';

const supabase = Supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

console.log("✅ Supabase Client Connected Successfully");