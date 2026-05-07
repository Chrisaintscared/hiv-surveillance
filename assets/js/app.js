// ====================== HIV/AIDS Surveillance - FIXED APP.JS ======================

let supabaseClient = null;
let currentUser = null;

// Config
const SUPABASE_URL = 'https://vqwlrrhrgpiiualbetsf.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_dHKEoT8RgBRTwTYuQCJsbA_VzFJ0Jae';

function initSupabase() {
  supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  checkAuthStatus();
}

async function checkAuthStatus() {
  const { data: { session } } = await supabaseClient.auth.getSession();
  if (session) {
    currentUser = session.user;
    showMainApp();
    loadDashboardData();
    loadRecentCases();
    loadFacilities();
    initCharts();
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
    loadFacilities();
    initCharts();
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
  document.getElementById('main-app').classList.add('hidden');
}

function showMainApp() {
  document.getElementById('login-page').style.display = 'none';
  document.getElementById('main-app').classList.remove('hidden');
}

// ====================== NAVIGATION ======================
function navigateTo(page, el) {
  document.querySelectorAll('.sb-item').forEach(item => item.classList.remove('on'));
  if (el) el.classList.add('on');

  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  const target = document.getElementById(`page-${page}`);
  if (target) target.classList.add('active');

  document.getElementById('page-title').textContent = 
    page === 'dashboard' ? 'Dashboard Overview' :
    page === 'repository' ? 'Case Repository' :
    page === 'analytics' ? 'Analytics & Reports' : 'Facilities';
}

// ====================== DATA LOADING ======================
async function loadDashboardData() {
  try {
    const { count: totalCases } = await supabaseClient
      .from('hiv_cases').select('*', { count: 'exact', head: true }).eq('is_active', true);

    const { count: onArt } = await supabaseClient
      .from('hiv_cases').select('*', { count: 'exact', head: true }).eq('is_active', true).eq('art_status', 'on_art');

    const { count: cases2025 } = await supabaseClient
      .from('hiv_cases').select('*', { count: 'exact', head: true }).eq('is_active', true).eq('year_reported', 2025);

    document.getElementById('total-cases').textContent = (totalCases || 0).toLocaleString();
    document.getElementById('art-cases').textContent = (onArt || 0).toLocaleString();
    document.getElementById('cases-this-year').textContent = (cases2025 || 0).toLocaleString();
  } catch (e) {
    console.error(e);
  }
}

async function loadRecentCases() {
  try {
    const { data } = await supabaseClient
      .from('v_active_cases')
      .select('case_code, year_reported, age_group, gender, region_name, facility_name, art_status')
      .order('created_at', { ascending: false }).limit(8);

    renderRepo(data || []);
  } catch (e) {
    console.error(e);
    renderRepo([]);
  }
}

function renderRepo(data) {
  const tbody = document.getElementById('repo-body');
  tbody.innerHTML = '';
  if (!data.length) {
    tbody.innerHTML = `<tr><td colspan="8" class="text-center py-12 text-gray-500">No cases found</td></tr>`;
    return;
  }

  data.forEach(r => {
    const badge = r.art_status === 'on_art' 
      ? `<span class="bg-green-900 text-green-400 px-3 py-1 rounded-full text-xs">On ART</span>`
      : `<span class="bg-red-900 text-red-400 px-3 py-1 rounded-full text-xs">Not on ART</span>`;

    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td><strong>${r.case_code}</strong></td>
      <td>${r.year_reported}</td>
      <td>${r.age_group || '—'}</td>
      <td>${r.gender}</td>
      <td>${r.region_name || '—'}</td>
      <td>${r.facility_name || '—'}</td>
      <td>${badge}</td>
      <td><button onclick="viewCase('${r.case_code}')" class="px-4 py-1 bg-red-600 hover:bg-red-700 text-white rounded-lg text-sm">View</button></td>
    `;
    tbody.appendChild(tr);
  });
}

async function loadFacilities() {
  try {
    const { data } = await supabaseClient
      .from('v_facility_performance')
      .select('*')
      .order('total_cases', { ascending: false });

    const tbody = document.getElementById('facilities-body');
    tbody.innerHTML = '';

    data.forEach(f => {
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td class="font-medium">${f.facility_name}</td>
        <td>${f.region_name || '—'}</td>
        <td>${f.facility_type?.replace('_', ' ')}</td>
        <td><strong>${f.total_cases}</strong></td>
        <td>${f.is_art_hub ? '✅' : '—'}</td>
        <td>${f.last_submission ? new Date(f.last_submission).toLocaleDateString() : '—'}</td>
      `;
      tbody.appendChild(tr);
    });
  } catch (e) {
    console.error(e);
  }
}

// ====================== CHARTS ======================
let regionChart, artTrendChart, transmissionChart;

function initCharts() {
  // Regional Distribution
  const ctx1 = document.getElementById('regionChart');
  if (ctx1) {
    if (regionChart) regionChart.destroy();
    regionChart = new Chart(ctx1, {
      type: 'bar',
      data: {
        labels: ['NCR', 'Region XI', 'Region VII', 'Region X', 'CAR'],
        datasets: [{
          label: 'Cases',
          data: [452, 187, 134, 98, 67],
          backgroundColor: '#c0392b'
        }]
      },
      options: { responsive: true, maintainAspectRatio: false }
    });
  }

  // You can add more charts here later
}

// View Case Modal
function viewCase(code) {
  alert(`Viewing case: ${code}\n\nFull case details coming soon.`);
}

function closeModal() {
  document.getElementById('case-modal').style.display = 'none';
}

// Other functions
function toggleSB() {
  document.getElementById('sidebar').classList.toggle('off');
}

function toggleDark() {
  const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
  document.documentElement.setAttribute('data-theme', isDark ? 'light' : 'dark');
}

function sendAI() {
  alert("🧠 AI Insights Assistant\n\nThis feature is coming soon!");
}

function filterCases() {
  const term = document.getElementById('search-input').value.toLowerCase().trim();
  if (!term) {
    loadRecentCases();
    return;
  }
  // Simple client-side filter (can be improved later)
  alert("Search functionality will be enhanced soon!");
}

// Initialize everything
window.onload = initSupabase;