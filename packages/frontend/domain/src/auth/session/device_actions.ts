import {
  createEmptyContextIndex,
  readContextIndex,
  removeContextEntry,
  writeContextIndex,
} from './context_index';
import { fetchDevices, revokeDevice, revokeOtherDevices } from './session_api';
import { removeActiveSession } from './state';

import type { AuthSessionState } from '../types';
import type { DeviceSession } from './session_api';

type ProtectedApiResult<T> =
  | { ok: true; data: T }
  | {
      ok: false;
      error: string;
      status?: number;
      failure?: 'session-expired' | 'unauthenticated' | 'account-suspended';
    };

type WithRefreshRetry = <T>(
  authState: AuthSessionState,
  apiCall: (headers: Record<string, string>) => Promise<ProtectedApiResult<T>>
) => Promise<T | null>;

/**
 * ログイン中の全セッション（デバイス）一覧を取得する。
 *
 * @param authState - 認証セッションの現在状態
 * @param withRefreshRetry - session-expired 時に refresh-once retry を行う保護API実行関数
 * @returns 取得できたデバイスセッション一覧。認証失敗時は null
 */
async function executeListDevices(
  authState: AuthSessionState,
  withRefreshRetry: WithRefreshRetry
): Promise<DeviceSession[] | null> {
  return withRefreshRetry(authState, (headers) => fetchDevices(headers));
}

/**
 * 指定されたセッションをリモートで無効化し、ローカル state と context index を更新する。
 *
 * @param authState - 認証セッションの現在状態
 * @param sessionId - 無効化する sessionId
 * @param withRefreshRetry - session-expired 時に refresh-once retry を行う保護API実行関数
 * @returns 無効化とローカル更新が成功した場合は true、失敗時は false
 */
async function executeRevokeDevice(
  authState: AuthSessionState,
  sessionId: string,
  withRefreshRetry: WithRefreshRetry
): Promise<boolean> {
  const result = await withRefreshRetry(authState, async (headers) => {
    const res = await revokeDevice(sessionId, headers);
    if (res.ok) {
      return { ok: true as const, data: true };
    }
    return { ok: false as const, error: res.error, status: 400, failure: res.failure };
  });
  if (result == null) {
    return false;
  }

  const targetSession = authState.sessions?.find((session) => session.sessionId === sessionId);
  if (targetSession != null) {
    const index = readContextIndex() ?? createEmptyContextIndex();
    removeContextEntry(index, targetSession.authContextId);
    writeContextIndex(index);
  }

  if (sessionId === authState.activeSessionId) {
    removeActiveSession(authState);
  } else {
    authState.sessions =
      authState.sessions?.filter((session) => session.sessionId !== sessionId) ?? [];
  }
  return true;
}

/**
 * 現在のセッション以外をすべてリモートで無効化し、ローカル state と context index を更新する。
 *
 * @param authState - 認証セッションの現在状態
 * @param withRefreshRetry - session-expired 時に refresh-once retry を行う保護API実行関数
 * @returns 無効化とローカル更新が成功した場合は true、失敗時は false
 */
async function executeRevokeOtherDevices(
  authState: AuthSessionState,
  withRefreshRetry: WithRefreshRetry
): Promise<boolean> {
  const result = await withRefreshRetry(authState, async (headers) => {
    const res = await revokeOtherDevices(headers);
    if (res.ok) {
      return { ok: true as const, data: true };
    }
    return { ok: false as const, error: res.error, status: 400, failure: res.failure };
  });
  if (result == null) {
    return false;
  }

  const active = authState.session;
  if (active != null) {
    const index = readContextIndex() ?? createEmptyContextIndex();
    index.entries = index.entries.filter((entry) => entry.authContextId === active.authContextId);
    index.activeAuthContextId = active.authContextId;
    writeContextIndex(index);
  }

  authState.sessions = active != null ? [active] : [];
  return true;
}

export { executeListDevices, executeRevokeDevice, executeRevokeOtherDevices };
