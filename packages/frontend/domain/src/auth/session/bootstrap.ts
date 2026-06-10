import { refreshToken } from '@app-template/api';

import { COOKIE_AUTH_REQUEST_INIT } from './constants';
import {
  clearContextIndex,
  createEmptyContextIndex,
  readContextIndex,
  toContextIndexEntry,
  upsertContextEntry,
  writeContextIndex,
} from './context_index';
import { decodeAccessToken, isAccessTokenForSession } from './token_state';

import type { AuthSessionState, AuthSessionSummary } from '../types';

/** context index bootstrap の進行状態。 */
type BootstrapPhase = 'pending' | 'done';

/**
 * context index から復元できた session 一覧を accountId 単位で重複除去する。
 *
 * @param sessions - refresh に成功した session 一覧
 * @returns 同一 accountId の重複を後方 entry 優先で除去した session 一覧
 */
function dedupeSessionsByAccountId(sessions: AuthSessionSummary[]): AuthSessionSummary[] {
  const dedupedSessions: AuthSessionSummary[] = [];
  const seenAccountIds = new Set<string>();

  for (const session of [...sessions].reverse()) {
    if (!seenAccountIds.has(session.accountId)) {
      seenAccountIds.add(session.accountId);
      dedupedSessions.unshift(session);
    }
  }

  return dedupedSessions;
}

/**
 * refresh response から復元可能な session summary を組み立てる。
 *
 * @param authContextId - context index entry が保持する auth context ID
 * @param response - refreshToken の API 応答
 * @returns 検証済み session summary。claims 不一致や不正応答では null
 */
function restoreSessionFromRefreshResponse(
  authContextId: string,
  response: Awaited<ReturnType<typeof refreshToken>>
): AuthSessionSummary | null {
  if (response.status !== 200 || !('accessToken' in response.data)) {
    return null;
  }

  const { accessToken, account, sessionId, expiresAt } = response.data;
  const restoredSession: AuthSessionSummary = {
    requestId: response.data.requestId,
    authContextId,
    accountId: account.accountId,
    passkeyCredentialId: account.passkeyCredentialId,
    sessionId,
    accessToken,
    expiresAt,
  };

  const claims = decodeAccessToken(accessToken);
  if (claims == null || !isAccessTokenForSession(claims, restoredSession)) {
    return null;
  }

  return restoredSession;
}

/**
 * 復元済み session を in-memory state と context index に反映する。
 *
 * @param state - 復元結果を反映する認証セッション state
 * @param sessions - accountId 単位で重複除去済みの session 一覧
 * @param restoredActiveSession - context index 上で active だった session
 */
function applyRestoredSessions(
  state: AuthSessionState,
  sessions: AuthSessionSummary[],
  restoredActiveSession: AuthSessionSummary | null
): void {
  const fallbackActiveSession = sessions[0];
  if (fallbackActiveSession == null) {
    return;
  }

  const active =
    restoredActiveSession != null &&
    sessions.some((session) => session.sessionId === restoredActiveSession.sessionId)
      ? restoredActiveSession
      : fallbackActiveSession;

  state.sessions = sessions;
  state.session = active;
  state.activeSessionId = active.sessionId;
  state.phase = 'authenticated';
  state.routeIntent = '/login';
  state.lastFailure = null;
  state.lastError = null;

  const newIndex = createEmptyContextIndex();
  for (const session of sessions) {
    upsertContextEntry(
      newIndex,
      toContextIndexEntry(session, session.expiresAt),
      session.sessionId === active.sessionId
    );
  }
  writeContextIndex(newIndex);
}

/**
 * context index から session bootstrap を試行し、成功 entry を復元する。
 *
 * @param state - 復元した session を反映する in-memory 認証 state
 * @param bootstrapPhase - guard が redirect 判断に使う bootstrap 進行状態
 */
async function bootstrapSessionsFromContextIndex(
  state: AuthSessionState,
  bootstrapPhase: { value: BootstrapPhase }
): Promise<void> {
  try {
    const index = readContextIndex();
    if (index == null || index.entries.length === 0) {
      return;
    }

    const restoredSessions: AuthSessionSummary[] = [];
    let restoredActiveSession: AuthSessionSummary | null = null;

    for (const entry of index.entries) {
      try {
        const response = await refreshToken(
          entry.authContextId,
          undefined,
          COOKIE_AUTH_REQUEST_INIT
        );
        const restoredSession = restoreSessionFromRefreshResponse(entry.authContextId, response);
        if (restoredSession == null) {
          continue;
        }
        restoredSessions.push(restoredSession);
        if (index.activeAuthContextId === entry.authContextId) {
          restoredActiveSession = restoredSession;
        }
      } catch {
        // refresh failure: 該当 entry は authenticated state として採用しない。
      }
    }

    if (restoredSessions.length === 0) {
      clearContextIndex();
      return;
    }

    applyRestoredSessions(
      state,
      dedupeSessionsByAccountId(restoredSessions),
      restoredActiveSession
    );
  } finally {
    // bootstrap 完了を記録し、guard が redirect 判断を再評価できるようにする。
    bootstrapPhase.value = 'done';
  }
}

export type { BootstrapPhase };
export { bootstrapSessionsFromContextIndex };
