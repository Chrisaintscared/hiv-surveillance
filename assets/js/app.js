// ====================== HIV/AIDS Surveillance System - Production (Vercel) ======================

let supabaseClient = null;
let chartsInitialized = false;

// Supabase Configuration
const SUPABASE_URL = 'https://vqwlrrhrgpiiualbetsf.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_dHKEoT8RgBRTwTYuQCJsbA_VzFJ0Jae';

// Initialize Supabase
function initSupabase() {
  if (typeof supabase === "undefined") {
    console.error("❌ Supabase library not loaded");
    return;
  }

  supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  
  console.log("✅ Supabase Client Connected Successfully");
  loadDashboardData();
  loadRecentCases();
}

// Load Dashboard Statistics
async function loadDashboardData() {
  if (!supabaseClient) return;

  try {
    const { count: totalCases } = await supabaseClient
      .from('hiv_cases')
      .select('*', { count: 'exact', head: true })
      .eq('is_active', true);

    const { count: onArt } = await supabaseClient
      .from('hiv_cases')
      .select('*', { count: 'exact', head: true })
      .eq('is_active', true)
      .eq('art_status', 'on_art');

    const { count: cases2025 } = await supabaseClient
      .from('hiv_cases')
      .select('*', { count: 'exact', head: true })
      .eq('is_active', true)
      .eq('year_reported', 2025);

    // Update Dashboard Cards
    document.getElementById('total-cases').textContent = (totalCases || 0).toLocaleString();
    document.getElementById('art-cases').textContent = (onArt || 0).toLocaleString();

    const newCasesEl = document.querySelector('#p-dash .g4 .card:nth-child(3) .sv');
    if (newCasesEl) newCasesEl.textContent = (cases2025 || 0).toLocaleString();

  } catch (err) {
    console.error("Error loading dashboard data:", err);
  }
}

// Load Recent Cases
async function loadRecentCases() {
  if (!supabaseClient) return;

  try {
    const { data, error } = await supabaseClient
      .from('v_active_cases')
      .select(`
        case_code,
        year_reported,
        age_group,
        gender,
        region_name,
        facility_name,
        art_status
      `)
      .order('created_at', { ascending: false })
      .limit(20);

    if (error) throw error;
    renderRepo(data || []);
  } catch (err) {
    console.warn("View not available, using fallback...");
    try {
      const { data: fallback } = await supabaseClient
        .from('hiv_cases')
        .select('case_code, year_reported, age_group, gender, art_status')
        .limit(20);
      renderRepo(fallback || []);
    } catch (e) {
      console.error(e);
      renderRepo([]);
    }
  }
}

function renderRepo(data) {
  const tbody = document.getElementById('repo-body');
  tbody.innerHTML = '';

  if (!data || data.length === 0) {
    tbody.innerHTML = `<tr><td colspan="8" style="text-align:center;padding:60px;color:#64748b;">No cases found</td></tr>`;
    return;
  }

  data.forEach(r => {
    const badge = (r.art_status === 'on_art') 
      ? `<span style="background:#def7ec;color:#0e9f6e;padding:4px 10px;border-radius:999px;font-size:12px;">On ART</span>`
      : `<span style="background:#fee2e2;color:#c0392b;padding:4px 10px;border-radius:999px;font-size:12px;">Not yet</span>`;

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

function viewCase(caseCode) {
  alert(`📋 Viewing Case: ${caseCode}\n\nFull details coming soon.`);
}

// Navigation
function nav(page, el) {
  document.querySelectorAll('.page').forEach(p => p.classList.remove('on'));
  document.querySelectorAll('.sb-item').forEach(item => item.classList.remove('on'));
  if (el) el.classList.add('on');

  document.getElementById(`p-${page}`).classList.add('on');

  document.getElementById('pg-title').textContent = 
    page === 'dash' ? 'Dashboard Overview' : 
    page === 'repo' ? 'Data Repository' : 
    page.charAt(0).toUpperCase() + page.slice(1);

  if (page === 'repo') loadRecentCases();
  if (page === 'dash' && !chartsInitialized) initCharts();
}

// Charts
function initCharts() {
  if (chartsInitialized) return;
  chartsInitialized = true;

  new Chart(document.getElementById('trendChart'), {
    type: 'line',
    data: {
      labels: ['2020','2021','2022','2023','2024','2025'],
      datasets: [{
        label: 'New Cases',
        data: [6800, 7600, 9100, 10200, 11200, 1843],
        borderColor: '#c0392b',
        backgroundColor: 'rgba(192, 57, 43, 0.15)',
        tension: 0.3,
        fill: true
      }]
    },
    options: { responsive: true, maintainAspectRatio: false }
  });

  new Chart(document.getElementById('transChart'), {
    type: 'doughnut',
    data: {
      labels: ['Sexual', 'Blood-borne', 'MTCT', 'Unknown'],
      datasets: [{ 
        data: [85, 8, 4, 3], 
        backgroundColor: ['#c0392b', '#1a56db', '#0e9f6e', '#b45309'] 
      }]
    },
    options: { 
      responsive: true, 
      maintainAspectRatio: false, 
      cutout: '65%',
      plugins: { legend: { position: 'bottom' } }
    }
  });
}

// Utilities
function toggleSB() { document.getElementById('sidebar').classList.toggle('off'); }

function toggleDark() {
  const current = document.documentElement.getAttribute('data-theme');
  document.documentElement.setAttribute('data-theme', current === 'dark' ? 'light' : 'dark');
}

function sendAI() {
  const input = document.getElementById('ai-inp');
  if (input.value.trim()) {
    alert("🤖 AI Assistant:\n\nReal AI insights coming soon!");
    input.value = '';
  }
}

// Start the App
window.onload = () => {
  initSupabase();
  initCharts();
};