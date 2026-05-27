/**
 * NexaCloud - API Configuration local.
 * Terraform reemplaza este archivo en S3 con valores reales de API Gateway y Cognito.
 */
const COGNITO_CONFIG = {
    USER_POOL_ID: 'REEMPLAZADO_POR_TERRAFORM',
    CLIENT_ID: 'REEMPLAZADO_POR_TERRAFORM',
    REGION: 'us-east-1',
    SCOPES: ['email', 'profile', 'openid']
};

const API_CONFIG = {
    BASE_URL: '',
    TICKETS: {
        CREATE: '/tickets/create',
        GET: '/tickets/list',
        GET_BY_ID: '/tickets/:id',
        TRACK: '/tickets/track/:id',
        UPDATE: '/tickets/:id/update'
    },
    TIMEOUT: 30000,
    HEADERS: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }
};

function getApiUrl(endpoint) {
    const base = API_CONFIG.BASE_URL.replace(/\/+$/, '');
    const normalizedEndpoint = endpoint.startsWith('/') ? endpoint : '/' + endpoint;
    return base + normalizedEndpoint;
}

function getAuthHeaders() {
    const token = sessionStorage.getItem('cognito_token');
    const headers = { ...API_CONFIG.HEADERS };
    if (token) headers['Authorization'] = token;
    return headers;
}

async function apiCall(endpoint, method = 'GET', data = null) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), API_CONFIG.TIMEOUT);

    try {
        if (!API_CONFIG.BASE_URL) {
            throw new Error('API_CONFIG.BASE_URL no está configurado. Ejecuta Terraform para generar api-config.js.');
        }

        const options = {
            method,
            headers: getAuthHeaders(),
            signal: controller.signal
        };

        if (data && ['POST', 'PUT'].includes(method)) {
            options.body = JSON.stringify(data);
        }

        const response = await fetch(getApiUrl(endpoint), options);
        const payload = await response.json().catch(() => ({}));

        if (!response.ok) {
            if ([401, 403].includes(response.status)) {
                if (typeof cognito_logout === 'function') cognito_logout(false);
                window.location.href = '../login/login.html';
            }
            throw new Error(payload.message || 'Error ' + response.status + ': ' + response.statusText);
        }

        return payload;
    } catch (error) {
        if (error.name === 'AbortError') {
            throw new Error('Timeout: la solicitud excedió ' + API_CONFIG.TIMEOUT + 'ms');
        }
        throw error;
    } finally {
        clearTimeout(timeoutId);
    }
}

async function createTicket(ticketData) {
    return apiCall(API_CONFIG.TICKETS.CREATE, 'POST', ticketData);
}

async function getAllTickets(filters = {}) {
    let endpoint = API_CONFIG.TICKETS.GET;
    const cleanFilters = Object.fromEntries(
        Object.entries(filters).filter(([, value]) => value !== undefined && value !== null && value !== '')
    );
    if (Object.keys(cleanFilters).length > 0) {
        endpoint += '?' + new URLSearchParams(cleanFilters).toString();
    }
    return apiCall(endpoint, 'GET');
}

async function getTicketById(ticketId) {
    return apiCall(API_CONFIG.TICKETS.GET_BY_ID.replace(':id', encodeURIComponent(ticketId)), 'GET');
}

async function trackTicket(ticketId) {
    return apiCall(API_CONFIG.TICKETS.TRACK.replace(':id', encodeURIComponent(ticketId)), 'GET');
}

async function updateTicket(ticketId, updateData) {
    return apiCall(API_CONFIG.TICKETS.UPDATE.replace(':id', encodeURIComponent(ticketId)), 'PUT', updateData);
}
