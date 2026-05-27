/**
 * NexaCloud - Autenticación Cognito sin librerías de build.
 * Usa el endpoint público de Cognito Identity Provider desde el navegador.
 */

function cognitoEndpoint() {
    return `https://cognito-idp.${COGNITO_CONFIG.REGION}.amazonaws.com/`;
}

async function cognitoRequest(target, payload) {
    const response = await fetch(cognitoEndpoint(), {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-amz-json-1.1',
            'X-Amz-Target': `AWSCognitoIdentityProviderService.${target}`
        },
        body: JSON.stringify(payload)
    });

    const data = await response.json().catch(() => ({}));
    if (!response.ok) {
        const message = data.message || data.__type || `Error Cognito ${response.status}`;
        throw new Error(message.replace(/^.*#/, ''));
    }
    return data;
}

function cognito_saveSession(authResult, username) {
    if (!authResult) return;
    sessionStorage.setItem('cognito_token', authResult.IdToken);
    sessionStorage.setItem('cognito_access_token', authResult.AccessToken);
    sessionStorage.setItem('cognito_refresh_token', authResult.RefreshToken || '');
    sessionStorage.setItem('cognito_user', username);
    sessionStorage.setItem('cognito_expires_at', String(Date.now() + (authResult.ExpiresIn || 3600) * 1000));
}

async function cognito_login(email, password) {
    try {
        const username = String(email || '').trim().toLowerCase();
        const result = await cognitoRequest('InitiateAuth', {
            AuthFlow: 'USER_PASSWORD_AUTH',
            ClientId: COGNITO_CONFIG.CLIENT_ID,
            AuthParameters: {
                USERNAME: username,
                PASSWORD: password
            }
        });

        if (result.ChallengeName === 'NEW_PASSWORD_REQUIRED') {
            const newPassword = window.prompt('Cognito requiere cambiar la contraseña temporal. Escribe una nueva contraseña segura:');
            if (!newPassword) {
                return { success: false, message: 'Debes definir una nueva contraseña para completar el primer ingreso.' };
            }

            const challenge = await cognitoRequest('RespondToAuthChallenge', {
                ClientId: COGNITO_CONFIG.CLIENT_ID,
                ChallengeName: 'NEW_PASSWORD_REQUIRED',
                Session: result.Session,
                ChallengeResponses: {
                    USERNAME: username,
                    NEW_PASSWORD: newPassword
                }
            });

            cognito_saveSession(challenge.AuthenticationResult, username);
            return { success: true, message: 'Contraseña actualizada e inicio de sesión correcto.' };
        }

        cognito_saveSession(result.AuthenticationResult, username);
        return { success: true, message: 'Inicio de sesión correcto.' };
    } catch (error) {
        return { success: false, message: error.message || 'No se pudo iniciar sesión.' };
    }
}

function cognito_isAuthenticated() {
    const token = sessionStorage.getItem('cognito_token');
    const expiresAt = Number(sessionStorage.getItem('cognito_expires_at') || 0);
    if (!token || Date.now() >= expiresAt) {
        cognito_logout(false);
        return false;
    }
    return true;
}

function cognito_getCurrentUser() {
    return sessionStorage.getItem('cognito_user');
}

function cognito_logout(redirect = true) {
    sessionStorage.removeItem('cognito_token');
    sessionStorage.removeItem('cognito_access_token');
    sessionStorage.removeItem('cognito_refresh_token');
    sessionStorage.removeItem('cognito_user');
    sessionStorage.removeItem('cognito_expires_at');
    if (redirect) {
        window.location.href = '../login/login.html';
    }
}

async function cognito_forgotPassword(email) {
    try {
        await cognitoRequest('ForgotPassword', {
            ClientId: COGNITO_CONFIG.CLIENT_ID,
            Username: String(email || '').trim().toLowerCase()
        });
        return { success: true, message: 'Código enviado. Revisa el correo registrado en Cognito.' };
    } catch (error) {
        return { success: false, message: error.message || 'No se pudo enviar el código.' };
    }
}

async function cognito_confirmForgotPassword(email, code, newPassword) {
    try {
        await cognitoRequest('ConfirmForgotPassword', {
            ClientId: COGNITO_CONFIG.CLIENT_ID,
            Username: String(email || '').trim().toLowerCase(),
            ConfirmationCode: String(code || '').trim(),
            Password: newPassword
        });
        return { success: true, message: 'Contraseña actualizada correctamente.' };
    } catch (error) {
        return { success: false, message: error.message || 'No se pudo actualizar la contraseña.' };
    }
}
