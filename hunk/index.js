import { execFile as execFileCallback } from "node:child_process";
import { existsSync, readdirSync } from "node:fs";
import { readFile, stat } from "node:fs/promises";
import { basename, join, posix, resolve, sep } from "node:path";
import { promisify } from "node:util";

const execFile = promisify(execFileCallback);
const MAX_DIFF_BYTES = 32 * 1024 * 1024;
const MAX_SOURCE_BYTES = 1_000_000;

export function discoverRepos(root) {
  return readdirSync(root, { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && existsSync(join(root, entry.name, ".git")))
    .map((entry) => ({ name: entry.name, root: join(root, entry.name) }))
    .sort((a, b) => a.name.localeCompare(b.name));
}

async function git(repo, args, maxBuffer = MAX_DIFF_BYTES) {
  return (await execFile("git", ["-C", repo.root, ...args], { maxBuffer })).stdout;
}

function locateRepo(repos, workspacePath) {
  const normalized = posix.normalize(workspacePath);
  if (normalized.startsWith("../") || posix.isAbsolute(normalized)) return null;

  const repo = repos.find(({ name }) => normalized.startsWith(`${name}/`));
  if (!repo) return null;

  const relativePath = normalized.slice(repo.name.length + 1);
  const absolutePath = resolve(repo.root, ...relativePath.split("/"));
  if (!absolutePath.startsWith(`${resolve(repo.root)}${sep}`)) return null;
  return { repo, relativePath, absolutePath };
}

async function readWorkingFile(file) {
  try {
    if ((await stat(file)).size > MAX_SOURCE_BYTES) return null;
    return await readFile(file, "utf8");
  } catch {
    return null;
  }
}

async function diffRepo(repo) {
  const prefixes = [`--src-prefix=a/${repo.name}/`, `--dst-prefix=b/${repo.name}/`];
  try {
    return await git(repo, ["diff", "--no-ext-diff", "--no-color", ...prefixes, "HEAD", "--"]);
  } catch {
    // ponytail: unborn repositories show staged state only; handle mixed staged/unstaged files if it matters.
    return git(repo, ["diff", "--cached", "--no-ext-diff", "--no-color", ...prefixes, "--"]);
  }
}

export async function loadWorkspace(root, excludeUntracked = false) {
  const repos = discoverRepos(root);
  if (repos.length === 0) throw new Error(`No Git repositories found directly under ${root}`);

  const patchText = (await Promise.all(repos.map(diffRepo))).filter(Boolean).join("\n");
  const untrackedPaths = excludeUntracked
    ? []
    : (
        await Promise.all(
          repos.map(async (repo) =>
            (await git(repo, ["ls-files", "--others", "--exclude-standard", "-z"]))
              .split("\0")
              .filter(Boolean)
              .map((path) => `${repo.name}/${path}`),
          ),
        )
      ).flat();

  return {
    repoRoot: root,
    sourceLabel: root,
    title: `Workspace (${repos.length} repositories)`,
    patchText,
    untrackedPaths,
    readFileSource: async ({ path, previousPath, changeType, side }) => {
      const located = locateRepo(repos, side === "old" ? (previousPath ?? path) : path);
      if (!located || (side === "old" && changeType === "new") || (side === "new" && changeType === "deleted")) {
        return null;
      }
      if (side === "new") return readWorkingFile(located.absolutePath);

      try {
        return await git(located.repo, ["show", `HEAD:${located.relativePath}`], MAX_SOURCE_BYTES);
      } catch {
        return null;
      }
    },
  };
}

export default function workspaceExtension(hunk) {
  hunk.registerVcsAdapter({
    id: "workspace",
    name: "Git workspace",
    detect: (cwd) => (discoverRepos(cwd).length ? { id: "workspace", repoRoot: cwd } : null),
    operations: {
      "working-tree-diff": {
        load: (input, ctx) => loadWorkspace(ctx.cwd, input.options.excludeUntracked),
      },
    },
  });
}
