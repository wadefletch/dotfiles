/**
 * Office TV relay: a fixed set of Fire TV operations for beam's `office_tv` tool.
 *
 * Runs on arrakis next to the `office-tv` Cloudflare Tunnel. Beam's Worker
 * reaches it through a Workers VPC Service pinned to 127.0.0.1:8765 and POSTs
 * {"action": ..., "url": ...} with a bearer secret. Every action maps to one
 * fixed adb command; there is no way to run an arbitrary shell command.
 *
 * This process owns the only connection to the office LAN: it forwards
 * 127.0.0.1:5556 to the TV's adb port, and adb only ever talks to loopback. So
 * only Bun needs macOS's Local Network permission (allow it once, when the
 * LaunchAgent first starts).
 *
 * The bearer secret lives in the login Keychain (service office-tv-relay-secret);
 * beam holds the same value as OFFICE_TV_RELAY_SECRET.
 */
import { connect, createServer } from "node:net";
import { timingSafeEqual } from "node:crypto";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

class TvError extends Error {}
class BadRequest extends Error {}

// The TV on the office LAN; give it a DHCP reservation so this stays right.
// OFFICE_TV_ADDR (host:port) points the forward elsewhere, for testing.
const [TV_HOST, TV_PORT] = (process.env.OFFICE_TV_ADDR ?? "172.16.0.151:5555").split(":");
const ADB = "/opt/homebrew/bin/adb";
const SERIAL = "127.0.0.1:5556";
const SIGN = "ai.tractorbeam.sign/.SignActivity";
const KEYS: Record<string, string> = {
  home: "KEYCODE_HOME",
  back: "KEYCODE_BACK",
  wake: "KEYCODE_WAKEUP",
  sleep: "KEYCODE_SLEEP",
  volume_up: "KEYCODE_VOLUME_UP",
  volume_down: "KEYCODE_VOLUME_DOWN",
  mute: "KEYCODE_VOLUME_MUTE",
};

const SECRET = Buffer.from(
  (await run(["/usr/bin/security", "find-generic-password", "-a", process.env.USER!, "-s", "office-tv-relay-secret", "-w"]))
    .toString()
    .trim(),
);

// Forward loopback 5556 to the TV's adb port (see the module comment).
createServer((client) => {
  const upstream = connect(Number(TV_PORT), TV_HOST);
  client.pipe(upstream).pipe(client);
  const close = () => (client.destroy(), upstream.destroy());
  client.on("error", close).on("close", close);
  upstream.on("error", close).on("close", close);
}).listen(5556, "127.0.0.1");

async function run(argv: string[], timeoutMs = 20_000): Promise<Buffer> {
  const proc = Bun.spawn(argv, { stdout: "pipe", stderr: "pipe", timeout: timeoutMs });
  const [stdout, stderr, code] = await Promise.all([
    new Response(proc.stdout).arrayBuffer(),
    new Response(proc.stderr).text(),
    proc.exited,
  ]);
  if (code !== 0) throw new TvError(stderr.trim() || `${argv[0]} exited ${code}`);
  return Buffer.from(stdout);
}

/**
 * Run one adb command against the TV. adb's server keeps its connection across
 * relay restarts and network blips, where it can go stale ("device offline"),
 * so a failure reconnects from scratch and retries once.
 */
async function adb(...args: string[]): Promise<Buffer> {
  await run([ADB, "connect", SERIAL]).catch(() => {});
  try {
    return await run([ADB, "-s", SERIAL, ...args]);
  } catch {
    await run([ADB, "disconnect", SERIAL]).catch(() => {});
    await run([ADB, "connect", SERIAL]).catch(() => {});
    return run([ADB, "-s", SERIAL, ...args]);
  }
}

/** Quote one argument for the TV's shell, which `adb shell` hands its string to. */
const quote = (value: string) => `'${value.replaceAll("'", `'\\''`)}'`;

async function status() {
  const activities = (await adb("shell", "dumpsys activity activities")).toString();
  const power = (await adb("shell", "dumpsys power")).toString();
  const resumed = activities.split("\n").find((line) => line.includes("mResumedActivity")) ?? "";
  const foreground = resumed.split(/\s+/).find((token) => token.includes("/")) ?? null;
  return {
    foreground,
    sign_showing: foreground?.startsWith("ai.tractorbeam.sign/") ?? false,
    awake: power.includes("mWakefulness=Awake"),
  };
}

/** The current screen as a ~960px JPEG, small enough to keep in chat history. */
async function screenshot(): Promise<ArrayBuffer> {
  const dir = await mkdtemp(join(tmpdir(), "office-tv-"));
  try {
    const png = join(dir, "tv.png");
    const jpeg = join(dir, "tv.jpg");
    await Bun.write(png, await adb("exec-out", "screencap -p"));
    await run(["/usr/bin/sips", "-Z", "960", "-s", "format", "jpeg", png, "--out", jpeg]);
    return await Bun.file(jpeg).arrayBuffer();
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

async function perform(action: unknown, url: unknown) {
  if (action === "status") return status();
  if (action === "open_sign") return adb("shell", `am start -n ${SIGN}`).then(() => ({ ok: true }));
  if (action === "open_url") {
    if (typeof url !== "string" || !URL.canParse(url) || new URL(url).protocol !== "https:" || /\s/.test(url)) {
      throw new BadRequest("open_url needs an https URL");
    }
    return adb("shell", `am start -n ${SIGN} -e url ${quote(url)}`).then(() => ({ ok: true }));
  }
  if (typeof action === "string" && Object.hasOwn(KEYS, action)) {
    return adb("shell", `input keyevent ${KEYS[action]}`).then(() => ({ ok: true }));
  }
  throw new BadRequest(`unknown action: ${String(action)}`);
}

function authorized(request: Request): boolean {
  const token = Buffer.from((request.headers.get("authorization") ?? "").replace(/^Bearer /, ""));
  return token.length === SECRET.length && timingSafeEqual(token, SECRET);
}

// adb commands run one at a time.
let queue: Promise<unknown> = Promise.resolve();
const serialized = <T>(task: () => Promise<T>): Promise<T> => {
  const next = queue.then(task, task);
  queue = next.catch(() => {});
  return next;
};

Bun.serve({
  hostname: "127.0.0.1",
  port: 8765,
  async fetch(request) {
    if (request.method !== "POST") return Response.json({ ok: false, error: "POST only" }, { status: 405 });
    if (!authorized(request)) return Response.json({ ok: false, error: "unauthorized" }, { status: 401 });
    try {
      const { action, url } = (await request.json()) as { action?: unknown; url?: unknown };
      if (action === "screenshot") {
        return new Response(await serialized(screenshot), { headers: { "content-type": "image/jpeg" } });
      }
      return Response.json(await serialized(() => perform(action, url)));
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      if (error instanceof BadRequest || error instanceof SyntaxError) {
        return Response.json({ ok: false, error: message }, { status: 400 });
      }
      return Response.json({ ok: false, error: `TV unreachable: ${message}` }, { status: 502 });
    }
  },
});
