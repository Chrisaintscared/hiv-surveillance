// ====================== HIV/AIDS Surveillance - FULL LOGIN SYSTEM ======================

let supabaseClient = null;
let currentUser = null;
let chartsInitialized = false;

// Config
const SUPABASE_URL = 'https://vqwlrrhrgpiiualbetsf.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_dHKEoT8RgBRTwTYuQCJsbA_VzFJ0Jae';

// Initialize
function initSupabase() {
  supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  checkAuthStatus();
}

async function checkAuthStatus() {
  const { data: { session } } = await supabaseClient.auth.getSession();
  if (session) {
    currentUser = session.user;
    showMainApp();
  } else {
    showLoginPage();
  }
}

async function loginUser() {
  const email = document.getElementById('login-email').value.trim();
  const password = document.getElementById('login-password').value.trim();

  if (!email || !password) return alert("Please fill email and password");

  try {
    const { data, error } = await supabaseClient.auth.signInWithPassword({ email, password });
    if (error) throw error;

    currentUser = data.user;
    showMainApp();
    loadDashboardData();
    loadRecentCases();
  } catch (err) {
    alert("Login Failed: " + err.message);
  }
}

async function logoutUser() {
  await supabaseClient.auth.signOut();
  currentUser = null;
  showLoginPage();
}

function showLoginPage() {
  document.getElementById('login-page').style.display = 'flex';
  document.getElementById('main-app').style.display = 'none';
}

function showMainApp() {
  document.getElementById('login-page').style.display = 'none';
  document.getElementById('main-app').style.display = 'flex';
  console.log("✅ Logged in as:", currentUser?.email);
}

// ==================== DASHBOARD & REPOSITORY FUNCTIONS ====================

async function loadDashboardData() {
  try {
    const { count: totalCases } = await supabaseClient.from('hiv_cases').select('*', { count: 'exact', head: true }).eq('is_active', true);
    const { count: onArt } = await supabaseClient.from('hiv_cases').select('*', { count: 'exact', head: true }).eq('is_active', true).eq('art_status', 'on_art');
    const { count: cases2025 } = await supabaseClient.from('hiv_cases').select('*', { count: 'exact', head: true }).eq('is_active', true).eq('year_reported', 2025);

    document.getElementById('total-cases').textContent = (totalCases || 0).toLocaleString();
    document.getElementById('art-cases').textContent = (onArt || 0).toLocaleString();

    const newEl = document.querySelector('#p-dash .g4 .card:nth-child(3) .sv');
    if (newEl) newEl.textContent = (cases2025 || 0).toLocaleString();
  } catch (e) { console.error(e); }
}

async function loadRecentCases() {
  try {
    const { data } = await supabaseClient.from('v_active_cases')
      .select('case_code,year_reported,age_group,gender,region_name,facility_name,art_status')
      .order('created_at', { ascending: false }).limit(15);
    renderRepo(data || []);
  } catch (e) {
    renderRepo([]);
  }
}

function renderRepo(data) {
  const tbody = document.getElementById('repo-body');
  tbody.innerHTML = '';
  if (!data.length) {
    tbody.innerHTML = `<tr><td colspan="8" style="text-align:center;padding:60px;color:#64748b">No cases found</td></tr>`;
    return;
  }
  data.forEach(r => {
    const badge = (r.art_status === 'on_art') ? 
      `<span style="background:#def7ec;color:#0e9f6e;padding:4px 10px;border-radius:999px;font-size:12px;">On ART</span>` : 
      `<span style="background:#fee2e2;color:#c0392b;padding:4px 10px;border-radius:999px;font-size:12px;">Not yet</span>`;
    
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td><strong>${r.case_code}</strong></td>
      <td>${r.year_reported}</td>
      <td>${r.age_group || '—'}</td>
      <td>${r.gender}</td>
      <td>${r.region_name || '—'}</td>
      <td>${r.facility_name || '—'}</td>
      <td>${badge}</td>
      <td><button onclick="viewCase('${r.case_code}')" style="padding:6px 12px;background:#c0392b;color:white;border:none;border-radius:4px;cursor:pointer">View</button></td>
    `;
    tbody.appendChild(tr);
  });
}

function viewCase(code) { alert(`Case: ${code}\n\nFull view coming soon.`); }

// Navigation + Charts (same as before)
function nav(page, el) { /* ... your existing nav function ... */ }
function initCharts() { /* ... your existing charts ... */ }
function toggleSB() { document.getElementById('sidebar').classList.toggle('off'); }
function toggleDark() {
  const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
  document.documentElement.setAttribute('data-theme', isDark ? 'light' : 'dark');
}
function sendAI() { alert("AI Insights coming soon!"); }

// Initialize
window.onload = initSupabase;