## REMOVED Requirements

### Requirement: 低強調のパスキーログイン導線を提供する

**Reason**

Product Svelte app の `/login` surface を削除し、Flutter app 本体もまだ作成しないため、frontend が passkey-only login route を提供する仕様を維持しない。

**Migration**

Product API と backend auth contract は backend/API spec 側で維持する。将来 Flutter app を追加する場合は、Flutter app 用のFE/モバイル仕様として新たに定義する。

### Requirement: 復旧導線は既存アカウントの passkey 再登録だけを扱う

**Reason**

Product Svelte app の recovery/device-link route family を削除するため、frontend route と UI による復旧・端末追加体験を要求しない。

**Migration**

Backend recovery/device-link API の必要性は backend/API spec で扱う。Flutter app で復旧導線を持つ場合は、対象 app の仕様として再定義する。

### Requirement: auth routes は no-store な認証面として配信する

**Reason**

Product frontend auth routes を配信しないため、`/login*` と `/logout` の SvelteKit route response に対する no-store requirement は適用対象を失う。

**Migration**

Backend auth endpoint の no-store/security header は backend spec で維持する。Admin frontend の no-store は `admin-auth-fe` で維持する。

### Requirement: session expiry と logout は未認証導線を明確に分離する

**Reason**

Product Svelte app の authenticated navigation、`/session-expired` route、`/logout` route を削除するため、frontend route selection と presentation requirement は維持しない。

**Migration**

Session expiry/logout の API semantics は backend/API spec に残す。将来の Flutter app は独自の session UX として仕様化する。

### Requirement: 認証済みユーザーはアプリ内でパスキーを一覧・追加・削除できる

**Reason**

認証済み Product app 画面を削除し、Flutter app 本体も作成しないため、Product frontend の passkey management UI を要求しない。

**Migration**

Passkey management API の保持要否は backend/API spec で扱う。Admin operator passkey management は `admin-auth-fe` と backend admin auth specs で維持する。

### Requirement: 認証 UI は secret leakage を抑える security presentation を提供する

**Reason**

Product frontend auth UI を削除するため、recovery token URL除去や認証画面presentationに関する frontend requirement は対象外になる。

**Migration**

Secret leakage 抑止は backend endpoint、Admin auth UI、将来のFlutter app仕様でそれぞれ扱う。

### Requirement: 新端末からトークン型のデバイスリンクでパスキーを追加できる

**Reason**

Product Svelte app の device-link consume/register UI を削除するため、frontend で token 型 device-link を消費する画面仕様を維持しない。

**Migration**

Device-link API と token security の必要性は backend/API spec で扱う。将来の app surface が必要とする場合は新しいFE仕様で定義する。

### Requirement: クライアントは JWT アクセストークンの有効期限を監視し自動更新する

**Reason**

Product frontend domain state と Product Svelte app を削除し、browser-readable Product client session 管理を行う surface がなくなるため。

**Migration**

Token/refresh endpoint の contract は backend/API spec に残す。Admin operator token handling は `admin-auth-fe` で維持する。

### Requirement: クライアントは複数アカウントのセッションを同時に保持・切り替えできる

**Reason**

Product Svelte app の client session state と account switching UI を削除するため、frontend requirement として維持しない。

**Migration**

Flutter app が multi-account UX を必要とする場合は、Flutter app 追加時に独立した仕様として定義する。

### Requirement: suspended account は認証 UI で安全に案内される

**Reason**

Product frontend login/protected route UI を削除するため、suspended account の frontend presentation requirement は対象外になる。

**Migration**

Suspended account の API response semantics は backend/API spec で維持する。将来の app surface で案内画面を定義する。

### Requirement: 認証済みユーザーはログイン中のデバイスを確認・管理できる

**Reason**

Product authenticated app と device management page を削除するため、frontend device management UI requirement を維持しない。

**Migration**

Session management API の保持要否は backend/API spec で扱う。将来の Flutter app が device management を持つ場合は、その app surface の仕様として追加する。
