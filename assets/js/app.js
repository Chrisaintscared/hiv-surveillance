/**
 * DOH HIV Surveillance System - Core Logic (FIXED)
 * Fixes Vercel redirect loop + Supabase auth race conditions
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

// 2. AUTH HANDLER
async function handleAuth() {
    const isLogin = document.getElementById('auth-title').innerText === 'SIGN IN';
    const email = document.getElementById('login-email').value.trim();
    const password = document.getElementById('login-password').value.trim();
    const btn = document.getElementById('auth-btn');

    if (!email || !password) return alert("Please fill in all fields.");

    btn.disabled = true;
    const originalText = btn.innerText;
    btn.innerText = isLogin ? "Authenticating..." : "Creating Account...";

    try {
        if (isLogin) {
            const { data, error } = await supabaseClient.auth.signInWithPassword({
                email,
                password
            });

            if (error) throw error;

            const { data: profile } = await supabaseClient
                .from('users')
                .select('role')
                .eq('id', data.user.id)
                .single();

            if (!profile) {
                window.location.href = "/user_dashboard.html";
                return;
            }

            window.location.href =
                profile.role === 'admin'
                    ? "/admin_dashboard.html"
                    : "/user_dashboard.html";

        } else {
            const { error } = await supabaseClient.auth.signUp({
                email,
                password,
                options: {
                    data: { full_name: "Health Officer" }
                }
            });

            if (error) throw error;

            alert("Registration successful! You can now sign in.");
            toggleAuth();
        }

    } catch (err) {
        alert(err.message);
    }

    btn.disabled = false;
    btn.innerText = originalText;
}

// 3. LOGOUT
async function logoutUser() {
    await supabaseClient.auth.signOut();
    window.location.href = "login.html";
}

// 4. DASHBOARD LOADER
async function loadDashboard() {
    try {
        const { data: summary } = await supabaseClient
            .from('v_dashboard_summary')
            .select('*')
            .single();

        if (summary) {
            const set = (id, val) => {
                const el = document.getElementById(id);
                if (el) el.innerText = Number(val || 0).toLocaleString();
            };

            set('total-cases', summary.total_active_cases);
            set('art-cases', summary.total_on_art);
            set('new-cases', summary.cases_this_year);
            set('deceased', summary.total_deceased);
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
        console.warn("Dashboard error:", e);
    }
}

// 5. LOADER
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
            setTimeout(() => screen.classList.add('hidden'), 600);
            return;
        }

        if (bar) bar.style.width = steps[step].pct + '%';
        if (statusText) statusText.innerText = steps[step].msg;

        step++;
    }, 350);
}

// 6. AUTH GUARD (FIXED VERCEL LOOP)
document.addEventListener('DOMContentLoaded', async () => {

    await new Promise(r => setTimeout(r, 150));

    const {
        data: { session }
    } = await supabaseClient.auth.getSession();

    const path = window.location.pathname;
    const page = path.split('/').pop();

    const isLoginPage =
        page === 'login.html' ||
        page === '' ||
        path === '/' ||
        path.endsWith('/login.html');

    // =========================
    // IF USER IS LOGGED IN
    // =========================
    if (session) {

        const { data: profile } = await supabaseClient
            .from('users')
            .select('role')
            .eq('id', session.user.id)
            .single();

        // Prevent redirect loop on login page
        if (isLoginPage) {
            window.location.replace(
                profile?.role === 'admin'
                    ? "/admin_dashboard.html"
                    : "/user_dashboard.html"
            );
            return;
        }

        // Already inside dashboard
        loadDashboard();
        runCinematicLoader();
        return;
    }

    // =========================
    // NO SESSION (NOT LOGGED IN)
    // =========================
    if (!isLoginPage) {
        window.location.replace("/login.html");
    }
});
