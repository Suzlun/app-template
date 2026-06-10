import { mkdir, readFile, readdir, rename, rm, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

// TypeSpec package の root を script の場所から解決し、呼び出し元の cwd に依存しない生成後処理にする。
const packageRoot = fileURLToPath(new URL('..', import.meta.url));

// OpenAPI emitter が surface 名付きで出力した中間 artifact を、この repository で追跡する安定ファイル名へ正規化する。
const openApiDirectory = join(packageRoot, 'openapi');

// Product と Admin の service 名を TypeSpec namespace に合わせ、既存の Product 生成物パスと新しい Admin 生成物パスを固定する。
const artifactMappings = [
  {
    sourceFileName: 'AppTemplate.openapi.json',
    destinationFileName: 'openapi.json',
  },
  {
    sourceFileName: 'Admin.openapi.json',
    destinationFileName: 'admin.openapi.json',
  },
];

// TypeSpec の共有 namespace が OpenAPI schema key に残ると、Orval が複数 schema を同じ TypeScript 名へ潰してしまうため除去する。
const schemaNamespacePrefixes = ['AppTemplate.'];

// JSON stringify の改行を repository の prettier 対象 JSON と同じ末尾改行付きに固定する。
const jsonIndent = 2;

/**
 * OpenAPI schema key と $ref から共有 namespace prefix を取り除き、SDK 生成時の型名衝突を防ぐ。
 *
 * @param artifactPath - 正規化済み OpenAPI artifact の絶対 path
 */
async function normalizeSchemaNames(artifactPath) {
  // Step 1: OpenAPI artifact を JSON として読み込み、文字列置換ではなく構造を保ったまま編集する。
  const document = JSON.parse(await readFile(artifactPath, 'utf8'));

  // Step 2: components.schemas の key を単純名へ正規化し、衝突があれば生成 artifact の異常として停止する。
  const schemas = document.components?.schemas;
  if (schemas != null) {
    const normalizedSchemas = {};
    for (const [schemaName, schemaDefinition] of Object.entries(schemas)) {
      const normalizedSchemaName = stripSchemaNamespace(schemaName);
      if (Object.hasOwn(normalizedSchemas, normalizedSchemaName)) {
        throw new Error(
          `OpenAPI schema normalization conflict in ${artifactPath}: ${schemaName} -> ${normalizedSchemaName}`
        );
      }
      normalizedSchemas[normalizedSchemaName] = schemaDefinition;
    }
    document.components.schemas = normalizedSchemas;
  }

  // Step 3: artifact 全体の $ref を同じ単純名へ張り替え、path parameter や nested schema の参照を揃える。
  normalizeSchemaRefs(document);

  // Step 4: 後続の prettier 前でも読みやすい JSON として書き戻し、生成結果を deterministic にする。
  await writeFile(artifactPath, `${JSON.stringify(document, null, jsonIndent)}\n`);
}

/**
 * schema key に含まれる共有 namespace prefix を一段だけ取り除く。
 *
 * @param schemaName - OpenAPI components.schemas の key
 * @returns SDK type 名として使う単純 schema 名
 */
function stripSchemaNamespace(schemaName) {
  for (const namespacePrefix of schemaNamespacePrefixes) {
    if (schemaName.startsWith(namespacePrefix)) {
      return schemaName.slice(namespacePrefix.length);
    }
  }
  return schemaName;
}

/**
 * OpenAPI document 内の $ref を再帰的に走査し、正規化後の schema key を参照する形へ更新する。
 *
 * @param value - 走査対象の JSON value
 */
function normalizeSchemaRefs(value) {
  if (Array.isArray(value)) {
    // 配列要素は schema や parameter object を含むため、各要素を同じ規則で再帰処理する。
    for (const item of value) {
      normalizeSchemaRefs(item);
    }
    return;
  }

  if (value == null || typeof value !== 'object') {
    return;
  }

  if (typeof value.$ref === 'string') {
    value.$ref = normalizeSchemaRef(value.$ref);
  }

  // object の全 property を走査し、responses/components/paths のどこにある $ref でも同じ正規化を適用する。
  for (const child of Object.values(value)) {
    normalizeSchemaRefs(child);
  }
}

/**
 * components.schemas への $ref だけを対象に、schema namespace prefix を除去する。
 *
 * @param ref - OpenAPI $ref 文字列
 * @returns schema namespace を正規化した $ref
 */
function normalizeSchemaRef(ref) {
  const schemaRefPrefix = '#/components/schemas/';
  if (!ref.startsWith(schemaRefPrefix)) {
    return ref;
  }

  return `${schemaRefPrefix}${stripSchemaNamespace(ref.slice(schemaRefPrefix.length))}`;
}

// 生成先 directory が存在しない初回実行でも、後続の rename が directory 不在で失敗しないようにする。
await mkdir(openApiDirectory, { recursive: true });

for (const artifactMapping of artifactMappings) {
  // TypeSpec emitter の出力名と repository が公開する安定名を、それぞれ絶対 path として組み立てる。
  const sourcePath = join(openApiDirectory, artifactMapping.sourceFileName);
  const destinationPath = join(openApiDirectory, artifactMapping.destinationFileName);
  const temporaryPath = join(openApiDirectory, `.${artifactMapping.destinationFileName}.tmp`);

  // 前回の失敗で一時 artifact が残っていても、今回の正規化結果へ混ざらないよう先に削除する。
  await rm(temporaryPath, { force: true });

  try {
    // 大小文字を同一視する filesystem では Admin.openapi.json と admin.openapi.json が衝突するため、まず一意な一時名へ退避する。
    await rename(sourcePath, temporaryPath);

    // 既存の安定名 artifact は古い生成結果なので、一時退避後に削除して source の誤削除を防ぐ。
    await rm(destinationPath, { force: true });

    // 一時 artifact を安定名へ移動し、Product/Admin の出力が混ざらない形で追跡対象にする。
    await rename(temporaryPath, destinationPath);

    // 共有 namespace 由来の dotted schema key を SDK 生成器に渡す前に単純名へ正規化する。
    await normalizeSchemaNames(destinationPath);
  } catch (error) {
    // service 名の変更や emitter 設定の失敗を検出しやすくするため、実際に出力された file 一覧を添えて失敗させる。
    const generatedFiles = await readdir(openApiDirectory);
    throw new Error(
      `OpenAPI artifact normalization failed for ${artifactMapping.sourceFileName}. ` +
        `Generated files: ${generatedFiles.join(', ')}`,
      { cause: error }
    );
  }
}
