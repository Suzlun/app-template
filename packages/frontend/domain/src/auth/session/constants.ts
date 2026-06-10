/** session-expired を表す Product API エラーコード。 */
const SESSION_EXPIRED_ERROR = 'session-expired';

/** account-suspended を表す Product API エラーコード。 */
const ACCOUNT_SUSPENDED_ERROR = 'account-suspended';

/**
 * same-origin Product API への Cookie-only request 設定。
 *
 * refresh / logout の HttpOnly Cookie を同一 origin にだけ送信し、
 * cross-origin へ Cookie を漏らさないために利用する。
 */
const COOKIE_AUTH_REQUEST_INIT = { credentials: 'same-origin' } as const satisfies RequestInit;

export { ACCOUNT_SUSPENDED_ERROR, COOKIE_AUTH_REQUEST_INIT, SESSION_EXPIRED_ERROR };
