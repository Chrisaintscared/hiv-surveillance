/**
 * DOH HIV Surveillance System - Core Logic
 * Handles UUID-based Auth, Role Redirects, and Dashboard Sync
 */

// 1. UI & NAVIGATION
function toggleSB() {
    const sidebar = document.getElementById('sidebar');
    if (sidebar) sidebar.classList.toggle('off');
}

function toggleAuth() {
    const title = document.getElementById('auth-title');
    const desc = document.getElementById('auth-desc');
    const btn = document.getElementById('auth-btn');
    const toggleLink = document.getElementById('auth-toggle-text');
    const isLogin = title.innerText === 'SIGN IN';

    if (isLogin) {
        title.innerText = 'CREATE ACCOUNT';
        desc.innerText = 'Register for the HARP Repository';
        btn.innerText = 'Register Now';
        toggleLink.innerHTML = 'Already have an account? <span class="text-red-500 font-bold">Sign In.</span>';
    } else {
        title.innerText = 'SIGN IN';
        desc.innerText = 'Surveillance Unit';
        btn.innerText = 'Sign In';
        toggleLink.innerHTML = 'Need an account? <span class="text-red-500 font-bold">Click here.</span>';
    }
}

// 2. MASTER AUTH FUNCTION
async function handleAuth() {
    const isLogin = document.getElementById('auth-title').innerText === 'SIGN IN';
    const email = document.getElementById('login-email').value.trim();
    const password = document.getElementById('login-password').value.trim();
    const btn = document.getElementById('auth-btn');

    if (!email || !password) return alert("Please fill in all fields.");
    
    btn.disabled = true;
    const originalText = btn.innerText;
    btn.innerText = isLogin ? "Authenticating..." : "Creating Account...";

    if (isLogin) {
        const { data, error } = await supabaseClient.auth.signInWithPassword({ email, password });
        
        if (error) {
            alert("Login Failed: " + error.message);
            btn.disabled = false;
            btn.innerText = originalText;
        } else {
            const { data: profile, error: profileError } = await supabaseClient
                .from('users')
                .select('role')
                .eq('id', data.user.id)
                .single();

            if (profileError || !profile) {
                window.location.href = "user_dashboard.html";
            } else {
                window.location.href = profile.role === 'admin'
                    ? "admin_dashboard.html"
                    : "user_dashboard.html";
            }
        }
    } else {
        const { data, error } = await supabaseClient.auth.signUp({ 
            email, 
            password,
            options: { data: { full_name: "Health Officer" } }
        });
        
        if (error) {
            alert(error.message);
            btn.disabled = false;
            btn.innerText = originalText;
        } else {
            alert("Registration successful! You can now sign in.");
            toggleAuth(); 
            btn.disabled = false;
            btn.innerText = "Sign In";
        }
    }
}

async function logoutUser() {
    await supabaseClient.auth.signOut();
    window.location.href = "login.html";
}

// 3. DASHBOARD DATA LOADING
async function loadDashboard() {
    try {
        const { data: summary } = await supabaseClient.from('v_dashboard_summary').select('*').single();
        if (summary) {
            if (document.getElementById('total-cases')) document.getElementById('total-cases').innerText = summary.total_active_cases.toLocaleString();
            if (document.getElementById('art-cases')) document.getElementById('art-cases').innerText = summary.total_on_art.toLocaleString();
            if (document.getElementById('new-cases')) document.getElementById('new-cases').innerText = summary.cases_this_year.toLocaleString();
            if (document.getElementById('deceased')) document.getElementById('deceased').innerText = summary.total_deceased.toLocaleString();
        }

        const { data: cases } = await supabaseClient
            .from('hiv_cases')
            .select('*')
            .order('created_at', { ascending: false })
            .limit(10);

        const tableBody = document.getElementById('repo-table');
        if (tableBody && cases) {
            tableBody.innerHTML = cases.map(c => `
                <tr class="hover:bg-white/5 transition border-b border-white/5 text-sm">
                    <td class="p-5 font-mono text-red-500 font-bold">${c.case_code}</td>
                    <td class="p-5 text-slate-300">${c.gender}</td>
                    <td class="p-5 text-slate-400">${c.transmission_mode}</td>
                    <td class="p-5">
                        <span class="status-pill ${c.art_status}">
                            ${c.art_status.replace('_', ' ')}
                        </span>
                    </td>
                </tr>
            `).join('');
        }
    } catch (e) {
        console.warn("Dashboard sync error:", e);
    }
}

// 4. CINEMATIC LOADER
function runCinematicLoader() {
    const screen = document.getElementById('loading-screen');
    const bar = document.getElementById('ls-bar');
    const statusText = document.getElementById('ls-status');
    
    if (!screen) return;

    const steps = [
        { pct: 20, msg: 'Syncing with HARP central node...' },
        { pct: 55, msg: 'Fetching regional case data...' },
        { pct: 90, msg: 'Verifying session integrity...' },
        { pct: 100, msg: 'Access Granted.' }
    ];

    let step = 0;
    const interval = setInterval(() => {
        if (step >= steps.length) {
            clearInterval(interval);
            setTimeout(() => { screen.classList.add('hidden'); }, 600);
            return;
        }
        if (bar) bar.style.width = steps[step].pct + '%';
        if (statusText) statusText.innerText = steps[step].msg;
        step++;
    }, 350);
}

// 5. SESSION INITIALIZER — SAFE, NO REDIRECT LOOPS
document.addEventListener('DOMContentLoaded', async () => {
    const { data: { session } } = await supabaseClient.auth.getSession();
    const path = window.location.pathname;

    // Identify which "zone" this page belongs to
    const isLoginPage = path.includes('login') || path === '/' || path === '';
    const isAdminPage = path.includes('admin_dashboard');
    const isUserPage = path.includes('user_dashboard');
    const isDashboardPage = isAdminPage || isUserPage;

    if (session) {
        const { data: profile } = await supabaseClient
            .from('users')
            .select('role')
            .eq('id', session.user.id)
            .single();

        const role = profile?.role ?? 'user';

        if (isLoginPage) {
            // Logged-in user hit the login page — send them home
            window.location.href = role === 'admin' ? "admin_dashboard.html" : "user_dashboard.html";

        } else if (isDashboardPage) {
            // ✅ Already on a dashboard — just load data, DO NOT redirect
            loadDashboard();
            runCinematicLoader();
        }
        // Any other page: do nothing, let it render normally

    } else {
        // No session — only redirect if on a protected page
        if (isDashboardPage) {
            window.location.href = 'login.html';
        }
    }
});